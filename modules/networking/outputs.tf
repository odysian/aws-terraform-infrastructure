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
  description = "ID of DB security group"
  value       = aws_security_group.database.id
}
