variable "alarm_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
}

variable "cpu_alarm_threshold" {
  description = "CPU utilization threshold for alarms (percentage)"
  type        = number
}

variable "unhealthy_target_threshold" {
  description = "Number of unhealthy targets before alarming"
  type        = number
}

variable "rds_storage_threshold" {
  description = "RDS free storage threshold in bytes"
  type        = number
}
variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}
variable "aws_region" {
  description = "Region of AWS resources"
  type        = string
}
variable "db_identifier" {
  description = "Identifier of DB instance"
}
variable "autoscaling_group_name" {
  description = "Autoscaling Group Name"
}
variable "lb_arn_suffix" {
  description = "Suffix of Load Balancer ARN"
}
variable "lb_tg_arn_suffix" {
  description = "Suffix of Load Balancer Target Group ARN"
}
