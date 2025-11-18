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

## RDS Slow Query Logging Test

**Purpose:** Verify that the custom MySQL parameter group and CloudWatch log exports are working.

**Steps:**

1. Connect to the DB instance from a web EC2 instance using the MySQL client.
2. Create and populate a `slow_test` table with:
```sql
CREATE TABLE IF NOT EXISTS slow_test (
    id INT AUTO_INCREMENT PRIMARY KEY,
    padding CHAR(200) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO slow_test (padding)
SELECT REPEAT('x', 200)
FROM information_schema.tables
LIMIT 5000;
```
3. Run deliberately slow queries (e.g., `SELECT SLEEP(3);` and a large SELECT).
```sql
SELECT SLEEP(3);
SELECT * FROM slow_test ORDER BY padding DESC LIMIT 1000;
```
4. In the AWS Console:
   - Confirm the DB is using `terraform-webapp-dev-mysql8-parameter-group`.
   - Open the CloudWatch Logs group `/aws/rds/instance/terraform-webapp-dev-database/slowquery`.
5. Verify the slow query appears in the log stream with execution time > 2 seconds.
```
2025-11-18T04:04:50.953Z
# Time: 2025-11-18T04:04:50.953323Z
# User@Host: admin[admin] @  [10.0.2.86]  Id:    14
# Query_time: 3.000274  Lock_time: 0.000000 Rows_sent: 1  Rows_examined: 1
SET timestamp=1763438687;
SELECT SLEEP(3);

# Time: 2025-11-18T04:04:50.953323Z # User@Host: admin[admin] @ [10.0.2.86] Id: 14 # Query_time: 3.000274 Lock_time: 0.000000 Rows_sent: 1 Rows_examined: 1 SET timestamp=1763438687; SELECT SLEEP(3);
```
