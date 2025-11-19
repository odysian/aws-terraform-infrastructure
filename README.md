# AWS Terraform Infrastructure

## Overview

Terraform-based rebuild of my Week 1 CloudWatch monitoring project, with a focus on more production-style patterns and CloudOps workflows.

This repo represents Week 3 of my CloudOps learning and builds directly on:

- Week 1 – Manual build: [AWS CloudWatch Monitoring](https://github.com/odysian/aws-cloudwatch-monitoring)  
- Week 2 – Break/fix: [AWS Incident Response Lab](https://github.com/odysian/aws-incident-response-lab) 

## Goals:

- Build practical fluency with Terraform
- Implement more production-style patterns: modules, remote state, multi-env, hardening
- Treat this like my other labs: deploy -> observe -> harden -> document

## Features:

- 3-tier web app (ALB → EC2 → RDS MySQL)
- Auto Scaling Group with CPU-based scale up/down
- CloudWatch dashboard and alarms for ALB / EC2 / RDS
- HTTPS entrypoint on `lab.odysian.dev` (TLS terminated at ALB with ACM, HTTP → HTTPS redirect)
- S3 remote state with DynamoDB locking
- AWS Secrets Manager for application DB credentials
- IMDSv2 enforced on EC2 instances
- Basic RDS hardening (encryption, backups, custom parameter group, logs to CloudWatch)
- Separate `dev` and `prod` environments with isolated backends

For detailed architecture, see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
For security details (IAM, TLS policy, Secrets Manager), see [docs/SECURITY.md](docs/SECURITY.md).

## Secrets Management

DB credentials are not stored in Terraform variables.
- A Secrets Manager secret is created outside Terraform (console or CLI) with JSON like:

```json
  { "username": "...", "password": "...", "dbname": "..." }
```
- The secret ARN is passed into Terraform as a root variable and forwarded into the compute module.
- EC2 IAM role has a scoped policy allowing secretsmanager:GetSecretValue on that ARN.
- User data calls `aws secretsmanager get-secret-value`, parses the JSON, writes `config.php`, and `index.php` uses those constants to connect to MySQL.

## Modules

The root module is intentionally thin and just wires the pieces together.

- **`modules/networking`**
  - VPC, subnets, route tables, IGW
  - ALB, Web, and DB security groups  
  - Outputs:
    - `vpc_id`
    - `public_subnet_ids`
    - `private_subnet_ids`
    - `alb_security_group_id`
    - `web_security_group_id`
    - `database_security_group_id`

- **`modules/compute`**
  - AMI Data source, IAM role/instance profile
  - Launch Template, ASG, ALB, target group, listener
  - CPU based scaling policies
  - Outputs: `autoscaling_group_name`, `asg_scale_up_policy_ARN`, `asg_scale_down_policy_ARN`, `lb_dns_name`, etc.

- **`modules/database`**
  - DB subnet group
  - RDS instance + custom parameter group
  - Outputs: `db_endpoint`, `db_host`, `db_name`, `db_identifier`

- **`modules/monitoring`**
  - SNS topic + email subscription
  - CloudWatch dashboard
  - Alarms for ALB / ASG / RDS

More detail on design decisions and hardening lives in:
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- [docs/SECURITY.md](docs/SECURITY.md)
- [docs/TESTING.md](docs/TESTING.md)

## Environments

This repo uses separate environment directories plus separate backends:

```
envs/
├── dev/
│   ├── backend.tf         # S3 backend: dev.tfstate
│   ├── main.tf            # Calls the root modules
│   └── terraform.tfvars   # Dev-specific variables
└── prod/
    ├── backend.tf         # S3 backend: prod.tfstate
    ├── main.tf
    └── terraform.tfvars
```

Each environment has:
- Its own remote state and DynamoDB lock
- Its own variables
- Its own RDS instance and ALB/ASG

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
- **Security hardening (networking):**
  - Split ALB and EC2 security groups and restricted web instance traffic to only come from the ALB SG
  - DB SG only allows MySQL from the web instance SG

## Related Projects

- [AWS CloudWatch Monitoring](https://github.com/odysian/aws-cloudwatch-monitoring) - Manual infrastructure build (Week 1)
- [AWS Incident Response Lab](https://github.com/odysian/aws-incident-response-lab) - Troubleshooting scenarios (Week 2)
- **AWS Terraform Infrastructure** - Terraform based rebuild (Week 3)

