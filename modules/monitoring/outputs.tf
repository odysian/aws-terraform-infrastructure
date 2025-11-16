output "cloudwatch_dashboard_name" {
  description = "CloudWatch Dashboard Name"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}
output "sns_topic_arn" {
  description = "SNS Topic ARN"
  value       = aws_sns_topic.alarms.arn
}
output "unhealthy_targets_alarm_name" {
  description = "Unhealthy Target Alarm Name"
  value       = aws_cloudwatch_metric_alarm.unhealthy_targets.alarm_name
}
output "asg_high_cpu_alarm_name" {
  description = "ASG High CPU Alarm Name"
  value       = aws_cloudwatch_metric_alarm.asg_high_cpu.alarm_name
}
output "rds_high_cpu_alarm_name" {
  description = "RDS High CPU Alarm Name"
  value       = aws_cloudwatch_metric_alarm.rds_high_cpu.alarm_name
}
output "rds_low_storage_alarm_name" {
  description = "RDS Low Storage Alarm Name"
  value       = aws_cloudwatch_metric_alarm.rds_low_storage.alarm_name
}
output "alb_high_response_time_alarm_name" {
  description = "ALB High Response Time Alarm Name"
  value       = aws_cloudwatch_metric_alarm.alb_high_response_time.alarm_name
}
output "rds_low_freeable_memory_alarm_name" {
  description = "RDS Low Freeable Memory Alarm Name"
  value       = aws_cloudwatch_metric_alarm.rds_low_freeable_memory.alarm_name
}
