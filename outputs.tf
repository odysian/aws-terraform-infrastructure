output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.networking.private_subnet_ids
}

output "web_security_group_id" {
  description = "ID of web security group"
  value       = module.networking.web_security_group_id
}

output "database_security_group_id" {
  description = "ID of database security group"
  value       = module.networking.database_security_group_id
}

output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = module.compute.alb_dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the load balancer"
  value       = module.compute.alb_zone_id
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = module.compute.lb_tg_arn_suffix
}

output "db_endpoint" {
  description = "DNS endpoint for RDS instance"
  value       = module.database.db_endpoint
}

output "cloudwatch_dashboard_url" {
  description = "URL to CloudWatch Dashboard"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${module.monitoring.cloudwatch_dashboard_name}"
}

output "sns_topic_arn" {
  description = "ARN of SNS topic for alarms"
  value       = module.monitoring.sns_topic_arn
}

output "alarm_names" {
  description = "Names of CloudWatch alarms"
  value = [
    module.monitoring.unhealthy_targets_alarm_name,
    module.monitoring.asg_high_cpu_alarm_name,
    module.monitoring.rds_high_cpu_alarm_name,
    module.monitoring.rds_low_storage_alarm_name,
    module.monitoring.alb_high_response_time_alarm_name,
    module.monitoring.rds_low_freeable_memory_alarm_name
  ]
}

output "scale_up_policy_arn" {
  description = "ARN of scale up policy"
  value       = module.compute.scale_up_policy_arn
}

output "scale_down_policy_arn" {
  description = "ARN of scale down policy"
  value       = module.compute.scale_down_policy_arn
}

output "scaling_alarm_names" {
  description = "Names of scaling alarms"
  value = [
    module.compute.scale_up_policy_name,
    module.compute.scale_down_policy_name
  ]
}
