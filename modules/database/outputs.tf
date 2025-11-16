output "db_endpoint" {
  description = "DNS endpoint for RDS instance"
  value       = aws_db_instance.mysql.endpoint
}
output "db_username" {
  description = "Username for DB"
  value       = aws_db_instance.mysql.username
}
output "db_password" {
  description = "Password for DB"
  value       = aws_db_instance.mysql.password
}
output "db_host" {
  description = "Address for DB"
  value       = aws_db_instance.mysql.address
}
output "db_name" {
  description = "Name of DB"
  value       = aws_db_instance.mysql.db_name
}
output "db_instance" {
  description = "DB Instance Info"
  value       = aws_db_instance.mysql
}
output "db_identifier" {
  description = "Identifier of DB instance"
  value       = aws_db_instance.mysql.identifier
}
