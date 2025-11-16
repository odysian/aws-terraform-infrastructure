# Testing & Validation

## Auto Scaling Test

**Setup:**
- 2 instances
- Threshold: CPU > 70% for 4 minutes

**Testing:**
1. Connected via Session Manager
2. Installed stress: `sudo dnf install -y stress-ng`
3. Ran: `stress-ng --cpu 2 --cpu-load 90 --timeout 600s` on both instances
4. After a few minutes, high-cpu alarm triggered and created another ec2 instance
5. Following the test, low-cpu alarm triggered and removed the added instance

## Infrastructure Validation

### Database Connectivity

Tested from web instance:
```bash
mysql -h terraform-webapp-database.c0fekuwkkx5w.us-east-1.rds.amazonaws.com -u admin -p
```

### Load Balancer

Tested traffic distribution:
```bash
for i in {1..10}; do curl http://terraform-webapp-alb-1738341724.us-east-1.elb.amazonaws.com/| grep "Instance ID"; done
```

### CloudWatch Alarms

Active alarms:
1. Unhealthy targets
2. ASG high CPU
3. RDS high CPU
4. RDS low storage
5. ALB high response time
6. RDS low freeable memory

## Terraform Validation

### Remote State

State file encrypted in S3 and versioning enabled. DynamoDB locking works Tested by running `terraform plan` in two terminals, second one failed with lock error.
