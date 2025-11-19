variable "project_name" {
  description = "Base name for WAF resources"
  type        = string
}

variable "alb_arn" {
  description = "ARN of the Application Load Balancer"
  type        = string
}
