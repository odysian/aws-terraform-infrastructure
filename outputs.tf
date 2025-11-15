output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "web_security_group_id" {
  description = "ID of web security group"
  value       = aws_security_group.web.id
}

output "database_security_group_id" {
  description = "ID of database security group"
  value       = aws_security_group.database.id
}

output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the load balancer"
  value       = aws_lb.main.zone_id
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.web.arn
}

output "db_endpoint" {
  description = "DNS endpoint for RDS instance"
  value       = aws_db_instance.mysql.endpoint
}

output "cloudwatch_dashboard_url" {
  description = "URL to CloudWatch Dashboard"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "sns_topic_arn" {
  description = "ARN of SNS topic for alarms"
  value       = aws_sns_topic.alarms.arn
}

output "alarm_names" {
  description = "Names of CloudWatch alarms"
  value = [
    aws_cloudwatch_metric_alarm.unhealthy_targets.alarm_name,
    aws_cloudwatch_metric_alarm.asg_high_cpu.alarm_name,
    aws_cloudwatch_metric_alarm.rds_high_cpu.alarm_name,
    aws_cloudwatch_metric_alarm.rds_low_storage.alarm_name,
    aws_cloudwatch_metric_alarm.alb_high_response_time.alarm_name,
    aws_cloudwatch_metric_alarm.rds_low_freeable_memory.alarm_name
  ]
}

output "scale_up_policy_arn" {
  description = "ARN of scale up policy"
  value       = aws_autoscaling_policy.scale_up.arn
}

output "scale_down_policy_arn" {
  description = "ARN of scale down policy"
  value       = aws_autoscaling_policy.scale_down.arn
}

output "scaling_alarm_names" {
  description = "Names of scaling alarms"
  value = [
    aws_cloudwatch_metric_alarm.cpu_high_scale_up.alarm_name,
    aws_cloudwatch_metric_alarm.cpu_low_scale_down.alarm_name
  ]
}
