# Testing & Validation

## Auto Scaling

**Goal:** Verify ASG scale-out and scale-in on CPU thresholds

- Desired capacity: 2 instances
- Scale-out: CPU > 70% for 4 minutes
- Scale-in: CPU < 30% for 4 minutes

**Steps:**
- From both instances, ran:
  ```bash
  stress-ng --cpu 2 --cpu-load 90 --timeout 600s
  ```
- Observed:
  - High-CPU alarm triggered and a 3rd instance was launched
  - After stopping `stress-ng`, CPU dropped and low-CPU alarm triggered
  - ASG terminated the extra instance after cooldown

## Infrastructure Validation

### Database Connectivity
From a web instance:
```bash
mysql -h terraform-webapp-dev-database.c0fekuwkkx5w.us-east-1.rds.amazonaws.com -u admin -p
```

Confirmed successful login and application page reports healthy DB connection

### Load Balancer & Health Checks

Basic health check:
```bash
curl http://terraform-webapp-dev-alb-1107457006.us-east-1.elb.amazonaws.com/health.html
```

Round-robin distribution check:
```bash
for i in {1..10}; do   curl -s http://terraform-webapp-dev-alb-1107457006.us-east-1.elb.amazonaws.com/ | grep "Instance ID"; done
```

Confirmed health.html returns OK and load is spread between instances across loop iterations

### CloudWatch Alarms

Verified alarm states by inducing conditions:

- ASG CPU utilization high/low (via `stress-ng`)
- ALB unhealthy targets by temporarily stopping Apache on one instance
- RDS low free storage / high CPU by running heavier queries

Confirmed:
- Alarms transitioned between `OK`, `ALARM`, and `INSUFFICIENT_DATA` as expected
- Notifications delivered to SNS email subscription

## Terraform & Remote State

### Backend & Locking

- State stored in S3 bucket with versioning enabled
- DynamoDB table configured for state locking

Locking check:
- Ran `terraform plan` in two shells against the same environment
- Second plan failed with a lock error until the first completed

## RDS Slow Query Logging

**Goal:** Confirm custom parameter group and CloudWatch log exports

- Parameter group:
  - `slow_query_log = 1`
  - `long_query_time = 2`

**Test:**
From the RDS instance (via MySQL client):

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

SELECT SLEEP(3);
SELECT * FROM slow_test ORDER BY padding DESC LIMIT 1000;
```

In CloudWatch Logs (`/aws/rds/instance/terraform-webapp-dev-database/slowquery`), confirmed entries with:

- `Query_time` > 2 seconds.
- Matching `SELECT SLEEP(3);` and large `SELECT` statements.

```
# Time: 2025-11-18T04:04:50.953323Z # User@Host: admin[admin] @ [10.0.2.86] Id: 14 # Query_time: 3.000274 Lock_time: 0.000000 Rows_sent: 1 Rows_examined: 1 SET timestamp=1763438687; SELECT SLEEP(3);
```

## Troubleshooting Notes

- **Misconfigured RDS security group after initial modularization**
  - Symptom: 504s from ALB and timeouts from `curl` and `nc` to RDS endpoint
  - Root cause: RDS using the web SG instead of the DB SG
  - Fix: Corrected DB SG output in networking module and re-applied
  - Result: Application came up cleanly and DB connection succeeded
