# AWS Terraform Infrastructure - Auto-Scaling Web Application

> **Status:** In Progress - Core infrastructure complete, adding production enhancements

A production ready, auto-scaling web application infrastructure built entirely with Terraform. Demonstrates Infrastructure-as-Code best practices, high availability architecture, and comprehensive monitoring.

## Project Overview

This project provisions a complete multi-tier web application on AWS, including:

- **Multi-AZ VPC** with public and private subnets
- **Auto Scaling Group** with dynamic scaling policies
- **Application Load Balancer** for traffic distribution
- **RDS MySQL Database** in private subnets
- **CloudWatch Monitoring** with dashboards and alarms
- **Email Notifications** via SNS for infrastructure events

## Architecture

### Architecture Diagram

![PLACEHOLDER](docs/images/architecture-diagram.png)

*Multi-AZ auto-scaling architecture with load balancing and monitoring*

### Infrastructure Components

**Networking Layer:**
- VPC: `10.0.0.0/16`
- 2 Public Subnets: `10.0.1.0/24`, `10.0.2.0/24` (us-east-1a, us-east-1b)
- 2 Private Subnets: `10.0.11.0/24`, `10.0.12.0/24` (us-east-1a, us-east-1b)
- Internet Gateway with public routing
- Security groups for web tier and database tier

**Compute Layer:**
- Launch Template with Amazon Linux 2023
- Auto Scaling Group (min: 2, max: 4, desired: 2)
- Application Load Balancer (internet-facing)
- Target Group with health checks
- IAM roles for SSM and CloudWatch access

**Database Layer:**
- RDS MySQL 8.0 (db.t3.micro)
- Multi-AZ subnet group in private subnets
- Security group allowing access only from web tier

**Monitoring Layer:**
- CloudWatch Dashboard with 6 metric widgets
- 6 CloudWatch Alarms for critical metrics
- SNS Topic for email notifications
- Auto scaling alarms with automated responses

### Auto Scaling Behavior

**Scale Up Trigger:**
- When average CPU > 70% for 4 minutes
- Action: Add 1 instance
- Cooldown: 5 minutes

**Scale Down Trigger:**
- When average CPU < 30% for 4 minutes
- Action: Remove 1 instance
- Cooldown: 5 minutes

## Monitoring

### CloudWatch Dashboard

Access your dashboard via the output URL:
```bash
terraform output cloudwatch_dashboard_url
```

**Metrics displayed:**
- ALB response time and request count
- Target health (healthy/unhealthy hosts)
- ASG CPU utilization
- RDS CPU utilization and connections
- RDS free storage space
- RDS read/write latency

### Active Alarms

Six alarms monitor infrastructure health:
1. **Unhealthy Targets** - Alerts when instances fail health checks
2. **ASG High CPU** - Triggers scale-up when CPU > 80%
3. **RDS High CPU** - Alerts when database CPU > 80%
4. **RDS Low Storage** - Warns when free storage < 2GB
5. **ALB High Response Time** - Alerts when response time > 1s
6. **RDS Low Freeable Memory** - Warns of memory pressure

All alarms send notifications to the configured email address.

## 🧪 Testing Auto Scaling

### Test Scale Up

1. Connect to instances via AWS Session Manager
2. Install and run stress tool:
```bash
sudo dnf install -y stress-ng
stress-ng --cpu 2 --cpu-load 80 --timeout 600s &
```

3. Monitor in CloudWatch:
   - CPU utilization rises above 70%
   - After 4 minutes, scale-up alarm triggers
   - ASG adds a third instance
   - Receive email notification

### Test Scale Down

1. Stop the stress test or wait for timeout
2. CPU drops below 30%
3. After 4 minutes, scale-down alarm triggers
4. ASG removes the extra instance
5. Returns to baseline capacity (2 instances)

## Project Structure
```
aws-terraform-infrastructure/
├── networking.tf              # VPC, subnets, IGW, security groups
├── compute.tf                 # Launch template, ASG, ALB, IAM roles
├── database.tf                # RDS instance and subnet group
├── monitoring.tf              # CloudWatch dashboard and alarms
├── variables.tf               # Input variable definitions
├── outputs.tf                 # Output value definitions
├── providers.tf               # AWS provider configuration
├── terraform.tfvars.example   # Example configuration (no secrets)
├── scripts/
│   └── user_data.sh          # EC2 bootstrap script
├── docs/
│   ├── images/               # Architecture diagrams and screenshots
│   └── TESTING.md            # Detailed testing procedures
└── examples/                  # Optional production features (commented)
```
## Configuration Variables

### Required Variables

| Variable | Description |
|----------|-------------|
| `alarm_email` | Email for CloudWatch notifications |
| `db_password` | RDS master password |

### Optional Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `aws_region` | `us-east-1` | AWS region for deployment |
| `project_name` | `terraform-webapp` | Prefix for resource names |
| `instance_type` | `t3.micro` | EC2 instance type |
| `asg_min_size` | `2` | Minimum ASG instances |
| `asg_max_size` | `4` | Maximum ASG instances |
| `cpu_alarm_threshold` | `80` | CPU % for monitoring alarms |
| `db_name` | `appdb` | MySQL database name |

See `terraform.tfvars.example` for complete list.

## Outputs

| Output | Description |
|--------|-------------|
| `alb_dns_name` | Load balancer URL to access application |
| `cloudwatch_dashboard_url` | Direct link to CloudWatch dashboard |
| `vpc_id` | VPC identifier |
| `db_endpoint` | RDS database endpoint |
| `sns_topic_arn` | SNS topic for alarm notifications |

## Development Timeline

### Phase 1: Foundation ✅
- VPC and networking infrastructure
- Security groups for web and database tiers
- Verified with `terraform apply`

### Phase 2: Compute Layer ✅
- Launch template with Amazon Linux 2023
- Auto Scaling Group with target group integration
- Application Load Balancer with health checks
- IAM roles for SSM and CloudWatch

### Phase 3: Database Integration ✅
- RDS MySQL instance in private subnets
- Database connectivity from web tier
- Template injection for database credentials
- Verified with direct MySQL connection and web interface

### Phase 4: Monitoring ✅
- CloudWatch dashboard with 6 metric widgets
- 6 CloudWatch alarms for infrastructure health
- SNS notifications for alarm states
- Email subscription for alerting

### Phase 5: Auto Scaling ✅
- CPU-based scaling policies (up and down)
- CloudWatch alarms to trigger scaling
- Tested scale-up with stress tool
- Verified scale-down after load removal

### Phase 6: Production Features 
- [ ] S3 backend for remote state
- [ ] Terraform modules for code reusability
- [ ] Multi-environment support (dev/prod)
- [ ] Enhanced security configurations
- [ ] Performance optimizations

## Learning Outcomes

This project helped me learn:

- **Infrastructure as Code:** Complete infrastructure defined in version controlled code
- **Terraform Proficiency:** Variables, outputs, data sources, and resource dependencies
- **Monitoring & Observability:** Comprehensive CloudWatch integration
- **Auto Scaling Policies:** Dynamic capacity based on real-time metrics

## Development Notes

This project was built with help from Claude for:
- Terraform syntax and AWS resource configuration
- CloudWatch dashboard JSON structure
- Best practices and production patterns

All code was written manually with understanding of each component. AI was used as a learning tool and documentation reference.

## Related Projects

- [AWS CloudWatch Monitoring](https://github.com/odysian/aws-cloudwatch-monitoring) - Manual infrastructure build with monitoring
- [AWS Incident Response Lab](https://github.com/odysian/aws-incident-response-lab) - Troubleshooting and incident response scenarios