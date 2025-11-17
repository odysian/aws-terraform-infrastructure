variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}
variable "db_username" {
  description = "RDS master username"
  type        = string
}

variable "db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}
variable "db_name" {
  description = "Application database name"
  type        = string
}
variable "private_subnet_ids" {
  description = "Private Subnet IDs"
  type        = list(string)
}
variable "database_security_group_id" {
  description = "DB Security group id"
  type        = string
}


