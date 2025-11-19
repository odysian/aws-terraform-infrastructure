#!/bin/bash
set -euo pipefail

# Log all output from this script
exec > /var/log/user-data.log 2>&1

echo "=== Starting user-data bootstrap ==="

# ------------------------------------------------------------------------------
# Values injected by Terraform via templatefile(...)
# - db_host       = RDS address/endpoint
# - db_secret_arn = ARN of Secrets Manager secret with DB creds
# ------------------------------------------------------------------------------
DB_HOST="${db_host}"
DB_SECRET_ARN="${db_secret_arn}"

echo "DB_HOST from Terraform: $DB_HOST"
echo "DB_SECRET_ARN from Terraform: $DB_SECRET_ARN"

# ------------------------------------------------------------------------------
# System Updates & Packages
# ------------------------------------------------------------------------------
dnf update -y
dnf install -y httpd php php-mysqlnd php-cli php-common php-fpm wget mariadb105 jq awscli

# ----------------------------------------------------------------------
# Ensure SSM Agent is installed and running
# ----------------------------------------------------------------------
echo "Ensuring SSM Agent is installed and running..."
dnf install -y amazon-ssm-agent || true
systemctl enable amazon-ssm-agent
systemctl restart amazon-ssm-agent || systemctl start amazon-ssm-agent

systemctl enable httpd
systemctl start httpd

systemctl enable php-fpm
systemctl start php-fpm

# Ensure proper permissions on web root
mkdir -p /var/www/html
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

# ------------------------------------------------------------------------------
# Determine AWS region via IMDSv2
# ------------------------------------------------------------------------------
echo "Fetching IMDSv2 token..."
TOKEN=$(curl -sS -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

if [ -z "$TOKEN" ]; then
  echo "ERROR: Failed to retrieve IMDSv2 token."
  exit 1
fi

echo "Fetching instance identity document..."
INSTANCE_IDENTITY=$(curl -sS -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/dynamic/instance-identity/document)

AWS_REGION=$(echo "$INSTANCE_IDENTITY" | jq -r '.region')

if [ -z "$AWS_REGION" ] || [ "$AWS_REGION" = "null" ]; then
  echo "ERROR: Failed to parse AWS region from instance identity document."
  exit 1
fi

echo "Detected AWS region: $AWS_REGION"

# ------------------------------------------------------------------------------
# Fetch DB credentials from AWS Secrets Manager
# Secret JSON expected shape: {"username":"...","password":"...","dbname":"..."}
# ------------------------------------------------------------------------------
echo "Fetching DB credentials from Secrets Manager..."
SECRET_JSON=$(aws secretsmanager get-secret-value \
  --secret-id "$DB_SECRET_ARN" \
  --query 'SecretString' \
  --output text \
  --region "$AWS_REGION")

if [ -z "$SECRET_JSON" ]; then
  echo "ERROR: Secrets Manager returned empty SecretString."
  exit 1
fi

DB_USER=$(echo "$SECRET_JSON" | jq -r '.username')
DB_PASS=$(echo "$SECRET_JSON" | jq -r '.password')
DB_NAME=$(echo "$SECRET_JSON" | jq -r '.dbname')

if [ -z "$DB_USER" ] || [ -z "$DB_PASS" ] || [ -z "$DB_NAME" ]; then
  echo "ERROR: One or more DB fields (username/password/dbname) are empty."
  exit 1
fi

echo "Successfully retrieved DB credentials from Secrets Manager."

# ------------------------------------------------------------------------------
# Write config.php with DB constants (no secrets in Terraform/user data anymore)
# ------------------------------------------------------------------------------
echo "Writing /var/www/html/config.php..."
cat > /var/www/html/config.php <<EOF
<?php
define('DB_HOST', '$DB_HOST');
define('DB_NAME', '$DB_NAME');
define('DB_USER', '$DB_USER');
define('DB_PASS', '$DB_PASS');
EOF

chown apache:apache /var/www/html/config.php
chmod 640 /var/www/html/config.php

# ------------------------------------------------------------------------------
# Write index.php (uses config.php + IMDSv2 for instance metadata)
# ------------------------------------------------------------------------------
echo "Writing /var/www/html/index.php..."
cat > /var/www/html/index.php <<'PHP'
<?php
require_once __DIR__ . '/config.php';

/**
 * Get an IMDSv2 token from the Instance Metadata Service.
 */
function get_imds_token(): ?string {
    $opts = [
        'http' => [
            'method'  => 'PUT',
            'header'  => "X-aws-ec2-metadata-token-ttl-seconds: 21600\r\n",
            'timeout' => 2,
        ],
    ];
    $context = stream_context_create($opts);

    $token = @file_get_contents('http://169.254.169.254/latest/api/token', false, $context);
    if ($token === false || $token === '') {
        return null;
    }
    return trim($token);
}

/**
 * Read a metadata path using IMDSv2 (token header).
 */
function get_imds_value(string $path, ?string $token): string {
    $headers = '';
    if ($token !== null) {
        $headers .= "X-aws-ec2-metadata-token: {$token}\r\n";
    }

    $opts = [
        'http' => [
            'method'  => 'GET',
            'header'  => $headers,
            'timeout' => 2,
        ],
    ];
    $context = stream_context_create($opts);

    $result = @file_get_contents("http://169.254.169.254/latest/meta-data/{$path}", false, $context);
    if ($result === false) {
        return '';
    }
    return trim($result);
}

$token = get_imds_token();

$instance_id       = get_imds_value('instance-id', $token);
$availability_zone = get_imds_value('placement/availability-zone', $token);
$private_ip        = get_imds_value('local-ipv4', $token);

echo "<h1>Hello from Terraform Web Server!</h1>";
echo "<p><strong>Instance ID:</strong> " . htmlspecialchars($instance_id) . "</p>";
echo "<p><strong>Availability Zone:</strong> " . htmlspecialchars($availability_zone) . "</p>";
echo "<p><strong>Private IP:</strong> " . htmlspecialchars($private_ip) . "</p>";
echo "<p><strong>Server Time:</strong> " . date('Y-m-d H:i:s') . "</p>";

echo "<hr>";
echo "<h2>Database Connection</h2>";

echo "<p><strong>DB Host (from config.php):</strong> " . htmlspecialchars(DB_HOST) . "</p>";
echo "<p><strong>DB Name (from config.php):</strong> " . htmlspecialchars(DB_NAME) . "</p>";

$mysqli = @new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);

if ($mysqli->connect_errno) {
    echo "<p style='color: red;'><strong>Status:</strong> Connection failed</p>";
    echo "<p><strong>Error:</strong> " . htmlspecialchars($mysqli->connect_error) . "</p>";
} else {
    echo "<p style='color: green;'><strong>Status:</strong> Connected successfully!</p>";

    $result = $mysqli->query("SELECT NOW() AS current_time, VERSION() AS mysql_version");
    if ($result) {
        $row = $result->fetch_assoc();
        echo "<p><strong>MySQL Version:</strong> " . htmlspecialchars($row['mysql_version']) . "</p>";
        echo "<p><strong>DB Time:</strong> " . htmlspecialchars($row['current_time']) . "</p>";
    }

    $mysqli->close();
}
?>
PHP

chown apache:apache /var/www/html/index.php
chmod 644 /var/www/html/index.php

# ------------------------------------------------------------------------------
# ALB Health Check Endpoint
# ------------------------------------------------------------------------------
echo "OK" > /var/www/html/health.html
chown apache:apache /var/www/html/health.html
chmod 644 /var/www/html/health.html

# ------------------------------------------------------------------------------
# CloudWatch Agent Installation
# ------------------------------------------------------------------------------
wget -q https://amazoncloudwatch-agent.s3.amazonaws.com/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -Uvh amazon-cloudwatch-agent.rpm || true

# ------------------------------------------------------------------------------
# Restart services to ensure everything is picked up
# ------------------------------------------------------------------------------
systemctl restart php-fpm
systemctl restart httpd

echo "User data script completed successfully at $(date)"
