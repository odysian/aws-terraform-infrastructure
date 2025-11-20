# Architecture

This document describes the 3-tier web application architecture deployed via Terraform.

Goal: A production-style, internet-facing application that is auto-scaled, observable, and uses least-privilege access patterns.

## Request Flow

1. Client connects to `lab.odysian.dev` (public DNS)
2. ALB redirects HTTP → HTTPS and terminates TLS
3. ALB forwards requests to healthy EC2 instances in the target group
4. EC2 instances connect to RDS MySQL over the private network
5. Response flows back through ALB to the client

## Network Topology

**VPC Layout**
- Single VPC with Internet Gateway
- **Public subnets (2):** ALB and web EC2 instances
- **Private subnets (2):** RDS MySQL (no direct internet route)

**Security Groups**
- **ALB SG:** HTTP/HTTPS from internet → ALB only
- **Web SG:** HTTP from ALB SG only (no direct internet access)
- **DB SG:** MySQL 3306 from Web SG only

**TLS & Entry Point**
- Public endpoint: `https://lab.odysian.dev`
- HTTP :80 listener redirects all traffic to HTTPS
- HTTPS :443 listener terminates TLS using ACM certificate
- ALB forwards plain HTTP to target group inside VPC
- WAF Web ACL protects the ALB with AWS managed rule groups

## Compute Layer

**Launch Template**
- Amazon Linux 2023 (via `data "aws_ami"`)
- Instance type: `t3.micro`
- IMDSv2 enforced (`http_tokens = "required"`)

**User Data** (`scripts/user_data_v2.sh`)
1. Installs Apache, PHP, CloudWatch agent
2. Discovers region via IMDSv2
3. Fetches DB credentials from Secrets Manager
4. Writes `config.php` with database connection constants
5. Creates `index.php` showing instance metadata and DB status
6. Creates `/health.html` for ALB health checks
7. Installs and enables SSM agent

**Auto Scaling Group**
- Spans both public subnets
- Desired/min/max capacity set per environment
- Attached to ALB target group
- CPU-based scaling policies (high/low thresholds)

**Load Balancer**
- Application Load Balancer in public subnets
- HTTP :80 → HTTPS :443 redirect
- HTTPS :443 → target group on port 80
- Health check: `/health.html`
- SSL policy: `ELBSecurityPolicy-TLS13-1-2-2021-06`

## Database Layer

**RDS MySQL**
- Engine: MySQL 8.0
- Instance class: `db.t3.micro`
- Deployed in private subnets (multi-AZ subnet group)
- Storage encrypted (KMS)
- Automated backups (1-day retention)
- Deletion protection enabled

**Custom Parameter Group**
- `slow_query_log = 1`
- `long_query_time = 2`
- Log exports: `error`, `general`, `slowquery` → CloudWatch Logs

**Connectivity**
- Only Web SG allowed on port 3306
- Application uses least-privilege user from Secrets Manager
- RDS master user reserved for administrative tasks

## Monitoring

**CloudWatch Dashboard**
- ASG: CPU utilization
- ALB: Request count, response time, healthy/unhealthy hosts
- RDS: CPU, storage, memory, connections, latency

**Alarms**
- ASG CPU high/low (triggers scaling policies)
- ALB high response time and unhealthy targets
- RDS high CPU, low storage, low memory
- SNS topic sends email notifications

**Logs**
- RDS logs stream to CloudWatch Logs
- ALB access logs written to S3
- CloudWatch agent collects system metrics

## Terraform Layout

**Modules**
- `networking`: VPC, subnets, route tables, security groups
- `compute`: IAM role, launch template, ASG, ALB, scaling policies
- `database`: RDS instance, parameter group, Secrets Manager secret
- `monitoring`: SNS topic, CloudWatch dashboard and alarms
- `waf`: Web ACL with managed rule groups
- `security`: CloudTrail trail and log bucket

**Environments**
- Separate directories: `envs/dev` and `envs/prod`
- Each has its own S3 backend state key
- Environment-specific variables via `.tfvars` files
- Isolated resources (RDS, ALB, Secrets Manager ARN)
