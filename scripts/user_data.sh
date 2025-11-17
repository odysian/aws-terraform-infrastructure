#!/bin/bash
set -xe

# Redirect all output to a log file for debugging
exec > /var/log/user-data.log 2>&1

# System Updates & Base Packages
dnf update -y
dnf install -y httpd php php-mysqlnd php-cli php-common php-fpm wget mariadb105

# Apache + PHP-FPM Setup
systemctl enable httpd
systemctl start httpd

systemctl enable php-fpm
systemctl start php-fpm

# Ensure proper permissions
mkdir -p /var/www/html
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

# Create Main PHP Page with hardcoded DB credentials
# (Terraform will inject these values before launch)
cat > /var/www/html/index.php << 'PHPEOF'
<?php
// Get instance metadata
$instance_id       = @file_get_contents('http://169.254.169.254/latest/meta-data/instance-id');
$availability_zone = @file_get_contents('http://169.254.169.254/latest/meta-data/placement/availability-zone');
$private_ip        = @file_get_contents('http://169.254.169.254/latest/meta-data/local-ipv4');

echo "<h1>Hello from Terraform Web Server!</h1>";
echo "<p><strong>Instance ID:</strong> $instance_id</p>";
echo "<p><strong>Availability Zone:</strong> $availability_zone</p>";
echo "<p><strong>Private IP:</strong> $private_ip</p>";
echo "<p><strong>Server Time:</strong> " . date('Y-m-d H:i:s') . "</p>";

echo "<hr>";
echo "<h2>Database Connection</h2>";

// Database credentials injected by Terraform
$db_host = '${db_host}';
$db_name = '${db_name}';
$db_user = '${db_user}';
$db_pass = '${db_pass}';

echo "<p><strong>DB Host (template):</strong> $db_host</p>";
echo "<p><strong>DB Name (template):</strong> $db_name</p>";

if ($db_host && $db_name && $db_user) {
    $conn = @mysqli_connect($db_host, $db_user, $db_pass, $db_name);

    if ($conn) {
        echo "<p style='color: green;'><strong>Status:</strong> Connected successfully!</p>";

        // Test query
        $result = @mysqli_query($conn, "SELECT NOW() as current_time, VERSION() as mysql_version");
        if ($result) {
            $row = mysqli_fetch_assoc($result);
            echo "<p><strong>MySQL Version:</strong> " . $row['mysql_version'] . "</p>";
            echo "<p><strong>DB Time:</strong> " . $row['current_time'] . "</p>";
        }

        mysqli_close($conn);
    } else {
        echo "<p style='color: red;'><strong>Status:</strong> Connection failed</p>";
        echo "<p><strong>Error:</strong> " . mysqli_connect_error() . "</p>";
    }
} else {
    echo "<p style='color: red;'>Database credentials not configured properly.</p>";
}
?>
PHPEOF

# ALB Health Check Endpoint
echo "OK" > /var/www/html/health.html

# Set permissions
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

# CloudWatch Agent Installation
wget https://amazoncloudwatch-agent.s3.amazonaws.com/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -Uvh amazon-cloudwatch-agent.rpm || true

# Restart services to ensure everything is picked up
systemctl restart php-fpm
systemctl restart httpd

echo "User data script completed successfully at $(date)"
