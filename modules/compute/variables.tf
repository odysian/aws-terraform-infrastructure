variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}
variable "vpc_id" {
  description = "ID of VPC"
  type        = string
}
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}
variable "asg_min_size" {
  description = "Minimum number of instances in ASG"
  type        = number
}
variable "asg_max_size" {
  description = "Maximum number of instances in ASG"
  type        = number
}
variable "asg_desired_capacity" {
  description = "Desired number of instances in ASG"
  type        = number
}
variable "web_security_group_id" {
  type = string
}
variable "public_subnet_ids" {
  type = list(string)
}
variable "db_host" {
  description = "RDS database address"
  type        = string
}
variable "db_name" {
  description = "Database name"
  type        = string
}
variable "db_username" {
  description = "Database username"
  type        = string
}
variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}
variable "db_endpoint" {
  description = "RDS database endpoint"
  type        = string
}
variable "db_credentials_secret_arn" {
  description = "ARN of Secrets Manager secret containing DB credentials"
  type        = string
}
