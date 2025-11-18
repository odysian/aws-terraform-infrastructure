# Security Overview

This document summarizes the main security controls in this Terraform-based environment and highlights areas for future hardening.

## Scope & Assumptions

- Single AWS account used for learning and lab work (not multi-account production).
- Terraform runs from a trusted workstation within a VMware Ubuntu system with IAM credentials managed outside this repo.
- Focus areas:
  - Network and access boundaries
  - Secrets and data protection
  - Logging, monitoring, and observability

## Network Security

**VPC & Subnets**
- 2 public subnets (ALB + EC2)
- 2 private subnets (RDS only)
- Internet Gateway attached to VPC with a single public route table
- RDS is not publicly accessible and has no direct internet route

**Security Groups**
- **ALB SG**
  - Inbound: HTTP 80 from the internet
  - Outbound: HTTP/HTTPS to web instances
- **Web Instance SG**
  - Inbound: HTTP 80 from ALB SG only
  - No direct inbound from the internet
  - Remote access is via SSM Session Manager, not SSH
- **DB SG**
  - Inbound: MySQL 3306 from Web Instance SG only
  - No inbound from ALB, internet, or arbitrary CIDR

## Instance Hardening

**Metadata Service**
- IMDSv2 enforced on all EC2 instances:
  - `http_tokens = "required"`
  - `http_endpoint = "enabled"`
  - `http_put_response_hop_limit = 1`
- Application sample code uses IMDSv2 to read instance metadata (instance ID, AZ, etc.)

**Access to Instances**
- No SSH key pairs or port 22 rules are configured
- Management access is intended via:
  - AWS Systems Manager (SSM) using the `AmazonSSMManagedInstanceCore` managed policy

## Identity & Access Management (IAM)

**EC2 IAM Role**
- `Principal: { Service: "ec2.amazonaws.com" }`
- Attached policies:
  - `AmazonSSMManagedInstanceCore` (managed) – SSM access
  - `CloudWatchAgentServerPolicy` (managed) – metrics/logs publishing
  - Inline policy for Secrets Manager (least privilege):
    - `Action: secretsmanager:GetSecretValue`
    - `Resource: <db-credentials-secret-arn>`
- Least privilege for the EC2 role (scoped to a single secret)

## Secrets Management (AWS Secrets Manager)

The project uses AWS Secrets Manager to store and expose database credentials to the web tier.

1. A Secrets Manager secret is created outside Terraform (CLI or console) with JSON like:

    ```json
    { "username": "...", "password": "...", "dbname": "..." }
    ```

2. The secret ARN is passed into Terraform as a root variable and then forwarded into the compute module.
3. An inline policy is added to the EC2 IAM role allowing it access to the secret via `secretsmanager:GetSecretValue` on that specific ARN.
4. User data calls `aws secretsmanager get-secret-value`, parses the JSON, and writes `config.php` with `DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASS`.
5. `index.php` includes `config.php` and uses those constants to connect to the database.

- Credentials are only retrieved at runtime from Secrets Manager by instances with the correct IAM role
- DB credentials never appear in:
  - Terraform variable files under version control
  - Terraform state
  - User data template itself


**Future Hardening**
- Rotate the secret on a schedule (manual or via Lambda/Secrets Manager rotation)
- Use a dedicated KMS key for the secret, with restricted key policy.

## Data Protection (RDS)

**Storage & Backups**
- Storage encrypted at rest using AWS-managed KMS key.
- Automated backups enabled (1-day retention for free-tier compliance)
- Explicit backup and maintenance windows configured
- Deletion protection enabled to reduce accidental data loss

**Custom Parameter Group**
- Custom parameter group attached to the instance:
  - `slow_query_log = 1`
  - `long_query_time = 2`
- Provides better observability into inefficient queries without changing application code

**Network & Access**
- RDS deployed into private subnets
- Only accessible from the DB SG (which only allows MySQL from the web SG)

**Future Hardening**
- Add read replicas and/or Multi-AZ for resilience (beyond free-tier)

## Logging, Monitoring & Observability

**CloudWatch Metrics & Alarms**
- EC2 / ASG: CPU-based scale-out and scale-in alarms
- ALB: Latency and unhealthy host alarms
- RDS: CPU, storage, and freeable memory alarms

**CloudWatch Logs**
- RDS exports: `error`, `general`, `slowquery` log types to CloudWatch Logs
- CloudWatch Agent delivers instance-level metrics to CloudWatch for dashboards/alarms

**Notifications**
- SNS topic with email subscription for alarm notifications

**Future Hardening Ideas**
- Enable and document AWS CloudTrail for API auditing
- Add AWS Config rules or Security Hub / GuardDuty for continuous checks
- Add dashboards focused on security signals (e.g., failed connections, spikes in 5xx/4xx)

## Terraform State Security

**Backend**
- Remote state stored in an S3 bucket (encryption and versioning enabled)
- DynamoDB table used for state locking to prevent concurrent modification

**Security Considerations**
- State may still contain some non-secret identifiers and ARNs; treat state bucket as sensitive
- Access to S3 bucket and DynamoDB table should be limited to:
  - Terraform IAM identity
  - CI user/role

## Known Gaps & Future Work

The following are intentionally out-of-scope for this iteration but are natural next steps:

- **HTTPS Everywhere**
  - Attach ACM certificate to ALB and redirect HTTP → HTTPS
- **Edge Protection**
  - Add AWS WAF in front of the ALB for basic OWASP protections and rate limiting
- **Stronger Egress Controls**
  - Restrict outbound traffic from web instances and database to only required endpoints
- **Patch & Compliance**
  - Formal patching strategy using SSM Patch Manager
  - Baseline configuration with SSM State Manager
- **Multi-Account / Landing Zone**
  - Separate dev/prod accounts and shared services for logging/security in a real production environment
