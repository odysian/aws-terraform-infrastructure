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
output "alb_security_group_id" {
  description = "ID of ALB security group"
  value       = aws_security_group.alb.id
}
output "web_instance_security_group_id" {
  description = "ID of web instance security group"
  value       = aws_security_group.web_instance.id
}
output "database_security_group_id" {
  description = "ID of DB security group"
  value       = aws_security_group.database.id
}
