output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
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
output "scale_up_policy_arn" {
  description = "ARN of scale up policy"
  value       = aws_autoscaling_policy.scale_up.arn
}
output "scale_down_policy_arn" {
  description = "ARN of scale down policy"
  value       = aws_autoscaling_policy.scale_down.arn
}
output "scale_up_policy_name" {
  description = "Name of Scale Up Policy Alarm"
  value       = aws_cloudwatch_metric_alarm.cpu_high_scale_up.alarm_name
}
output "scale_down_policy_name" {
  description = "Name of Scale Down Policy Alarm"
  value       = aws_cloudwatch_metric_alarm.cpu_low_scale_down.alarm_name
}
output "autoscaling_group_name" {
  description = "Autoscaling Group Name"
  value       = aws_autoscaling_group.web.name
}
output "lb_arn_suffix" {
  description = "Suffix of Load Balancer ARN"
  value       = aws_lb.main.arn_suffix
}
output "lb_tg_arn_suffix" {
  description = "Suffix of Load Balancer target group ARN"
  value       = aws_lb_target_group.web.arn_suffix
}

