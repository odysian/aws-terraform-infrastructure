output "db_endpoint" {
  description = "DNS endpoint for RDS instance"
  value       = aws_db_instance.mysql.endpoint
}

output "db_host" {
  description = "Address for DB"
  value       = aws_db_instance.mysql.address
}
output "db_name" {
  description = "Name of DB"
  value       = aws_db_instance.mysql.db_name
}
output "db_identifier" {
  description = "Identifier of DB instance"
  value       = aws_db_instance.mysql.identifier
}
