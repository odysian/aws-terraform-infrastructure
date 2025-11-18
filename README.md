# AWS Terraform Infrastructure

## Overview

This project recreates (and improves) the infrastructure from [aws-cloudwatch-monitoring](https://github.com/odysian/aws-cloudwatch-monitoring) using Terraform.

My goals:

- Gain strong, practical proficiency with Terraform
- Implement more production-style patterns

High-level features:

- 3-tier web app (ALB → EC2 → RDS MySQL)
- Auto Scaling Group and scaling policies
- CloudWatch monitoring and alarms
- S3 remote state with DynamoDB locking
- AWS Secrets Manager for application DB credentials
- IMDSv2 required on EC2 instances


This repo represents Week 3 of my CloudOps learning and builds directly on:

- Week 1 – Manual build: [AWS CloudWatch Monitoring](https://github.com/odysian/aws-cloudwatch-monitoring)  
- Week 2 – Break/fix: [AWS Incident Response Lab](https://github.com/odysian/aws-incident-response-lab) 

## Current Status

**Completed:**

- VPC and networking (2 AZs with public/private subnets)
- Compute layer (Launch template, ASG, ALB)
- Database (RDS MySQL in private subnet)
- Monitoring (CloudWatch dashboard, alarms, SNS notifications)
- Auto scaling policies (CPU-based scale up/down)
- S3 backend + DynamoDB for remote state and locking
- Modules: Split resources into `networking`, `compute`, `database`, and `monitoring` Terraform modules
- Multi-environment: Dev/prod directories with separate backends
- Secrets Management: 
  - DB credentials stored in AWS Secrets Manager
  - Secret created outside Terraform and injected via ARN
  - EC2 instances retrieve credentials at boot with IAM role and `GetSecretValue`
- IMDSv2 Instance Metadata: 
  - Launch Template requires IMDSv2 
  - Application uses IMDSv2 to read instance metadata

**In Progress:**

- Production Examples: Add WAF, read replica configs
- Polish documentation and add diagrams

## Architecture

### High Level

- **Networking**
  - 2 public subnets (ALB + EC2)
  - 2 private subnets (RDS)
  - Internet Gateway + public route table
  - Security groups:
    - Web SG: 80/443 from Internet
    - DB SG: 3306 from Web SG only

- **Compute**
  - Launch Template with Amazon Linux 2023 AMI
  - User data bootstraps Apache + PHP and deploys a simple PHP app
  - Auto Scaling Group across public subnets
  - Application Load Balancer with health checks on `/health.html`

- **Database**
  - RDS MySQL 8.0 (`db.t3.micro`)
  - Private subnet group across 2 AZs
  - Not publicly accessible
  - Web tier connects over port 3306 via DB SG
  - Storage encrypted at rest with KMS key
  - Automated backups retained for 1 day (free-tier)
  - Defined backup and maintenance windows
  - Deletion protection enabled
  - Custom parameter group
  - RDS error/general/slowquery logs exported to CloudWatch Logs
 


- **Monitoring**
  - CloudWatch Dashboard:
    - ASG CPU utilization
    - ALB TargetResponseTime / RequestCount, ALB HealthyHostCount / UnHealthyHostCount
    - RDS CPU, FreeStorageSpace, FreeableMemory, DatabaseConnections, latency
  - CloudWatch Alarms:
    - ASG high CPU
    - ALB high response time, unhealthy targets
    - RDS high CPU, low storage, low freeable memory
    - Separate CPU-driven alarms wired to ASG scale-up / scale-down policies

### Module Layout

The single root module was refactored into four modules:

- **`modules/networking`**
  - VPC, subnets, route tables, IGW
  - Web + DB security groups  
  - Outputs:
    - `vpc_id`
    - `public_subnet_ids`
    - `private_subnet_ids`
    - `web_security_group_id`
    - `database_security_group_id`

- **`modules/compute`**
  - Data source for Amazon Linux 2023 AMI
  - IAM role + instance profile for EC2 (SSM + CloudWatchAgent)
  - Launch Template (connects to RDS via user data)
  - ALB, target group, listener
  - ASG and scaling policies
  - Outputs:
    - `autoscaling_group_name`, `asg_scale_up/down_policy_ARN`, 
    - `lb_dns_name`, `lb_zone_id`, `lb_arn_suffix`, `lb_tg_arn_suffix`

- **`modules/database`**
  - DB subnet group (private subnets)
  - RDS MySQL instance
  - Outputs:
    - `db_endpoint`, `db_host`, `db_identifier`, `db_name`

- **`modules/monitoring`**
  - SNS topic + email subscription
  - ASG lifecycle notifications → SNS
  - CloudWatch dashboard
  - CloudWatch metric alarms for ALB, ASG, and RDS

The root `main.tf` just wires the modules together and passes outputs around.

## User Data & App Behavior

The web app is a single PHP page deployed by user data. Current flow:

1. Bootstrap stack (user data)
2. Discover region with IMDSv2
3. Fetch DB credentials from Secrets Manager
4. Write `config.php` with DB constants
5. Write `index.php`:
  - Implements IMDSv2 for instance metadata calls
  - Displays Instance ID, AZ, IP, server time
  - Connects to MySQL and displays connection status
6. Write `health.html` with a simple OK
7. Installs cloudwatch agent

### Secrets Management (AWS Secrets Manager)

The project uses AWS Secrets Manager to store and expose database credentials to the web tier.
1. A Secrets Manager secret is created outside Terraform (CLI or console) with JSON like:
```json
{ "username": "...", "password": "...", "dbname": "..." }
```
2. The secret ARN is passed into Terraform as a root variable and then forwarded into the compute module.
3. An inline policy is added to the EC2 IAM role allowing it access to the secret.
4. User data calls `aws secretsmanager get-secret-value`, parses the JSON and writes config.php with `DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASS`.
5. `index.php` includes `config.php` and uses those constants to connect to the database.

```hcl
user_data = base64encode(templatefile("${path.module}/../../scripts/user_data_v2.sh", {
  db_host       = var.db_host
  db_secret_arn = var.db_credentials_secret_arn
}))

```

- Only non-sensitive values are passed from terraform into user data
- The actual credentials are pulled at runtime from Secrets Manager

## Key Learnings

### Terraform Concepts
- **Remote state** 
    - Migrated from local state to S3 backend with DynamoDB state locking.
    - Safe for collaboration and avoids drift from local files.
- **Modules**
    - Split networking / compute / database / monitoring into dedicated modules.
    - Root module is used to wire them together.
    - Learned how to:
        - Pass variables/outputs between modules
        - Expose RDS identifiers/endpoints for other modules
        - Use user_data from within a module -> Changed \${path.module} to \${path.root}
- **Dependencies:**
    - Gained better understanding of how modules rely on each other
        - Compute depends on Database only through its variables
        - Monitoring depends on the other modules outputs

### Multi-Environment Setup (dev / prod)

After completing the initial modular refactor, I created  multiple environments so development and production deployments can run independently with their own Terraform state files.

- There are two common strategies in Terraform for handling multiple environments:
    - Terraform Workspaces
    - Separate Environment Directories + Separate Backends

I chose separate environment directories, as this mirrors real-world workflows more closely and provides explicit state isolation.

```
envs/
├── dev/
│   ├── backend.tf         # S3 backend: dev.tfstate
│   ├── main.tf            # Calls the same root modules
│   └── terraform.tfvars   # Dev-specific variables
└── prod/
    ├── backend.tf         # S3 backend: prod.tfstate
    ├── main.tf
    └── terraform.tfvars
```
Both environments reference the same set of modules, but each maintains:
- Its own remote state
- Its own state lock
- Its own variable file (terraform.tfvars)

Both environments were initialized and migrated successfully using:
```bash
terraform init -migrate-state
```

### RDS Hardening

- Created a custom parameter group:
  - Enabled slow query logging (`slow_query_log = 1`)
  - Reduced `long_query_time` to 2 seconds 
- Enabled export of `error`, `general`, and `slowquery` logs to CloudWatch Logs for troubleshooting
- Turned on:
  - Storage encryption at rest
  - Deletion protection
  - Automated backups
  - Explicit backup and maintenance windows

### Troubleshooting and Incident Debugging

While refactoring the project into modules, I ran into a small issue that turned into a good troubleshooting experience:

- **Wrong Security Group on RDS**
    - 504 timeout on `curl localhost/index.php` and ALB DNS name through browser
    - `nc` to the RDS endpoint timed out
    - Checked RDS security group and it was incorrect (was using the EC2 SG)
    - Networking module output had EC2 SG as the value for the DB SG, quick change and the app was operational 

## Testing & Validation

**Auto Scaling Test:**
- Stressed both instances to 90% CPU using `stress-ng` command
    - Scale-up alarm triggered after 4 minutes and added 3rd instance
- Stopped stress, CPU dropped below 30%
    - Scale-down alarm triggered after cooldown and removed 3rd instance

**Infrastructure Validation:**
- Database connectivity from web tier
- Load balancer distributing traffic evenly, /health.html returning 200
- CloudWatch alarms sending email notifications
- Complete destroy/recreate cycle tested after modularization

See [docs/TESTING.md](docs/TESTING.md) for additional testing

## Repository Structure
```
aws-terraform-infrastructure/
├── main.tf                 # Root module wiring: calls networking, compute, database, monitoring
├── providers.tf            # AWS provider config
├── backend.tf              # S3 + DynamoDB backend config
├── variables.tf            # Root input variables
├── .tfvars.example         # Example of quick variable file
├── outputs.tf              # Root outputs (ALB DNS, RDS endpoint, dashboard URL, etc.)
├── modules/
│   ├── networking/
│   │   ├── main.tf         # VPC, subnets, route tables, security groups
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── compute/
│   │   ├── main.tf         # AMI data, IAM, Launch Template, ALB, ASG, scaling policies
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── database/
│   │   ├── main.tf         # DB subnet group + RDS instance
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── monitoring/
│       ├── main.tf         # SNS, CloudWatch dashboard + alarms
│       ├── variables.tf
│       └── outputs.tf
├── scripts/
│   ├── user_data_v2.sh     # Updated with IMDSv2 and Secrets Manager
│   └── user_data.sh        # EC2 bootstrap / PHP app deployment
└── docs/
    ├── TESTING.md          # Auto scaling and connectivity test plans/results
    └── images/             # Diagrams and screenshots
```

## Development Tools

- **Terraform**
- **AWS CLI** 
- **VS Code + Remote SSM** 
- **Claude** for documentation and syntax help, all Terraform was typed and debugged manually.

---
**Built to learn Terraform and best practices, with a focus on real-world CloudOps workflows (deploy → observe → break → fix → refactor)**

## Related Projects

- [AWS CloudWatch Monitoring](https://github.com/odysian/aws-cloudwatch-monitoring) - Manual infrastructure build (Week 1)
- [AWS Incident Response Lab](https://github.com/odysian/aws-incident-response-lab) - Troubleshooting scenarios (Week 2)
- **AWS Terraform Infrastructure** - Terraform based rebuild (Week 3)s

