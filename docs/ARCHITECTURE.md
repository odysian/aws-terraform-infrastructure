# Architecture

This document describes the application and architecture for the Terraform-based rebuild

The goal is a simple, production-style 3-tier web application that is:

- Internet-facing via an Application Load Balancer (ALB)
- Auto-scaled across multiple AZs
- Backed by a private RDS MySQL database
- Observable via CloudWatch metrics, dashboards, and alarms

## Logical Architecture

The application follows a 3-tier pattern:

1. **Presentation tier** – Application Load Balancer (ALB)
2. **Web / application tier** – EC2 instances in an Auto Scaling Group
3. **Data tier** – RDS MySQL instance in private subnets

High-level request flow:

1. Client sends HTTP(S) request to the ALB at `lab.odysian.dev` (public endpoint)
2. ALB:
   - Redirects HTTP :80 traffic to HTTPS :443
   - Terminates TLS on HTTPS :443 and forwards the request to healthy EC2 instances in the target grou
3. EC2 instance:
   - Reads configuration written by user data (`config.php`)
   - Uses DB credentials from Secrets Manager
   - Connects to RDS over the private network and returns the response
4. RDS executes queries and returns results to the web tier

## Network Topology

**VPC & Subnets**

- Single VPC dedicated to this project
- **Public subnets (2)** – One per AZ, used for:
  - Application Load Balancer
  - Web EC2 instances
- **Private subnets (2)** – One per AZ, used for:
  - RDS MySQL instance
- **Routing**
  - Internet Gateway attached to the VPC
  - Public route table with default route (`0.0.0.0/0 → IGW`) associated to public subnets
  - Private subnets have no direct route to the internet

**Security Groups**

- **ALB SG**
  - Inbound: HTTP 80 from the internet
  - Outbound: HTTP/HTTPS to the web instance SG
- **Web Instance SG**
  - Inbound: HTTP 80 from ALB SG only
  - No direct inbound from the internet
- **DB SG**
  - Inbound: MySQL 3306 from the web instance SG only
  - No inbound from ALB or public CIDRs

### HTTPS / Entry Point

- Public entry point: https://lab.odysian.dev
- Application Load Balancer exposes:
  - HTTP :80 listener that redirects all traffic to HTTPS
  - HTTPS :443 listener that terminates TLS using an ACM certificate for lab.odysian.dev
- ALB then forwards plain HTTP traffic on port 80 to the web instances in the target group

For TLS policy details and certificate configuration, see [SECURITY.md](SECURITY.md).

#### TLS termination flow

1. Client connects to `http://lab.odysian.dev` on port 80  
   - The ALB HTTP listener returns an HTTP 301 redirect to `https://lab.odysian.dev/...`

2. Client follows the redirect and connects to `https://lab.odysian.dev` on port 443  
   - The ALB presents the ACM certificate for `lab.odysian.dev`  
   - The browser and ALB complete the TLS handshake using the configured AWS-managed security policy

3. After TLS is established, the ALB terminates TLS and forwards the request to the target group over HTTP on port 80  
   - Traffic between the client and ALB is HTTPS (encrypted)  
   - Traffic between the ALB and EC2 instances is HTTP inside the VPC

## Compute Layer

**Launch Template**

- AMI: Amazon Linux 2023 (via `data "aws_ami"`)
- Instance type: `t3.micro`
- Security group: Web instance SG
- **Instance metadata (IMDSv2)**
  - `http_tokens = "required"`
  - `http_endpoint = "enabled"`
  - `http_put_response_hop_limit = 1`

**User Data**

User data script (`scripts/user_data_v2.sh`) is responsible for:

1. Installing Apache + PHP
2. Discovering the region via IMDSv2
3. Fetching DB credentials from AWS Secrets Manager
4. Writing `config.php` with `DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASS`
5. Writing `index.php` that:
   - Shows EC2 instance metadata (ID, AZ, IP, server time)
   - Connects to MySQL and reports connection status
6. Creating `/health.html` for ALB health checks
7. Installing and configuring the CloudWatch agent

**Auto Scaling Group**

- ASG spans both public subnets
- Desired / min / max capacity defined per environment (`terraform.tfvars`)
- Attached to ALB target group

**Load Balancer**

- Application Load Balancer (ALB) in public subnets
- Listeners:
  - HTTP :80 - redirects all requests to HTTPS
  - HTTPS :443 - terminates TLS using the ACM certificate for `lab.odysian.dev` and forwards to the target group on port 80
- Target group:
  - Protocol HTTP, port 80
  - Health check path `/health.html`

## Database Layer

**RDS MySQL**

- Engine: MySQL 8.0
- Instance class: `db.t3.micro`
- Deployed in private subnets (multi-AZ subnet group, single-AZ instance for now)

**Hardening & Configuration**

- Storage encrypted at rest (KMS)
- Automated backups enabled (1-day retention for free-tier)
- Explicit backup and maintenance windows
- Deletion protection enabled
- Custom parameter group:
  - `slow_query_log = 1`
  - `long_query_time = 2`

**Connectivity**

- Only web instance SG is allowed to connect on port 3306
- Application uses credentials from Secrets Manager rather than static env vars or Terraform variables

## Monitoring

**Metrics & Dashboards**

- **CloudWatch Dashboard** includes:
  - ASG / EC2: `CPUUtilization`
  - ALB: `RequestCount`, `TargetResponseTime`, healthy/unhealthy host counts
  - RDS: CPU, `FreeStorageSpace`, `FreeableMemory`, `DatabaseConnections`, `latency`

**Alarms**

- **ASG / EC2**
  - High CPU → triggers scale-out policy
  - Low CPU → triggers scale-in policy
- **ALB**
  - High response time
  - Unhealthy target count
- **RDS**
  - High CPU
  - Low storage
  - Low freeable memory

**Logs**

- RDS log exports:
  - `error`, `general`, and `slowquery` logs streamed to CloudWatch Logs
- CloudWatch agent on EC2 instances sends system-level metrics to CloudWatch

**Notifications**

- SNS topic used as alarm action target
- Email subscription receives alarm notifications

## Terraform Architecture

The Terraform layout is intentionally modular and environment-aware

**Modules**

- **`modules/networking`**
  - VPC, subnets, route tables, Internet Gateway
  - ALB, web, and DB security groups
- **`modules/compute`**
  - AMI data source, IAM role + instance profile
  - Launch Template, ASG, ALB, target group, listener
  - Auto scaling policies
- **`modules/database`**
  - DB subnet group
  - RDS instance and custom parameter group
- **`modules/monitoring`**
  - SNS topic + subscription
  - CloudWatch dashboard and alarms

The root module (`main.tf`) wires these together via inputs/outputs and exposes key outputs (ALB DNS, RDS endpoint, dashboard URL, etc.)

**Environments**

- Separate directories for `dev` and `prod` under `envs/`
- Each environment:
  - Has its own S3 backend and DynamoDB lock table
  - Calls the same root module
  - Uses its own `terraform.tfvars` for instance counts, DB identifiers, etc.
