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
variable "user_data" {
  description = "User Data for Bootstrap Script"
  type        = string
}
