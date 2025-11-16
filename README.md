# AWS Terraform Infrastructure

## Overview

This project recreates the infrastructure from [aws-cloudwatch-monitoring](https://github.com/odysian/aws-cloudwatch-monitoring) using Terraform. I'm continuing to build on the app, adding features and learning terraform at the same time.

**Key additions:** 
- Auto scaling policies that dynamically add/remove instances based on CPU load.
- S3 backend and DynamoDB state locking for .tfstate

## Current Status

**Completed:**

- VPC and networking
- Compute layer (ASG, ALB, launch template)
- Database (RDS)
- Monitoring (CloudWatch dashboard, alarms)
- Auto scaling policies
- S3 backend for remote state

**In Progress:**

- Terraform Modules: Refactor into reusable modules
- Multi-environment: Dev/prod workspace pattern
- Production Examples: Add WAF, read replica configs
- Polish documentation

## Architecture

**Networking:**
- VPC with two public/private subnets
- Internet gateway and public route table
- Security groups for EC2 and RDS

**Auto Scaling:**
- Scale UP: CPU > 70% for 4 minutes → add 1 instance
- Scale DOWN: CPU < 30% for 4 minutes → remove 1 instance

**Monitoring:**
- ALB metrics (response time, requests, target health)
- ASG CPU utilization
- RDS metrics (CPU, connections, storage, latency)
- SNS email alerts

## Key Learnings

### Terraform Concepts
- **Remote state:** S3 backend with DynamoDB locking for team collaboration
- **Count parameter:** Creating multiple subnets with a single resource block

### Challenges Solved
- **Alarm behavior:** Scale-down alarm stays in ALARM state at minimum capacity (normal behavior)
- **State management:** Migrating from local to remote state without losing resources

## Testing & Validation

**Auto Scaling Test:**
- Stressed both instances to 90% CPU using `stress` command
- Scale-up alarm triggered after 4 minutes
- ASG added third instance (~3 min to healthy)
- Stopped stress, CPU dropped below 30%
- Scale-down alarm triggered after cooldown
- ASG removed instance, returned to baseline

**Infrastructure Validation:**
- Database connectivity from web tier
- Load balancer distributing traffic evenly
- CloudWatch alarms sending email notifications
- Complete destroy/recreate cycle

See [docs/TESTING.md](docs/TESTING.md) for detailed test procedures.

## Repository Structure
```
aws-terraform-infrastructure/
├── networking.tf          # VPC, subnets, routing, security groups
├── compute.tf             # Launch template, ASG, ALB, IAM
├── database.tf            # RDS MySQL
├── monitoring.tf          # CloudWatch dashboard, alarms, SNS
├── backend.tf             # S3 remote state configuration
├── variables.tf           # Input variables
├── outputs.tf             # Important values (ALB DNS, etc.)
├── providers.tf           # AWS provider config
├── scripts/
│   └── user_data.sh      # EC2 bootstrap script
└── docs/
    ├── SETUP.md          # Deployment instructions
    ├── TESTING.md        # Auto scaling test results
    └── images/           # Screenshots
```

## Development Tools

- **Terraform**
- **AWS CLI** 
- **VS Code**

All code was typed manually, Claude served as documentation reference and syntax guide.

## Related Projects

- [AWS CloudWatch Monitoring](https://github.com/odysian/aws-cloudwatch-monitoring) - Manual infrastructure build (Week 1)
- [AWS Incident Response Lab](https://github.com/odysian/aws-incident-response-lab) - Troubleshooting scenarios (Week 2)
- **AWS Terraform Infrastructure** ← You are here (Week 3)

These demonstrate: building → operating → automating cloud infrastructure.

---

**Built to learn Terraform and Infrastructure-as-Code patterns.**