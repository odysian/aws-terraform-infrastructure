resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

resource "aws_db_parameter_group" "mysql" {
  name        = "${var.project_name}-mysql8-parameter-group"
  family      = "mysql8.0"
  description = "Custom MySQL 8.0 parameter group for ${var.project_name}"

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "2"
  }

  parameter {
    name         = "general_log"
    value        = "1"
    apply_method = "immediate"
  }

  parameter {
    name         = "log_output"
    value        = "FILE"
    apply_method = "immediate"
  }
}

resource "aws_db_instance" "mysql" {
  identifier = "${var.project_name}-database"

  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"

  allocated_storage = 20

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.database_security_group_id]

  publicly_accessible = false
  skip_final_snapshot = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  backup_retention_period    = 1
  backup_window              = "06:00-07:00"
  maintenance_window         = "sun:07:00-sun:08:00"
  auto_minor_version_upgrade = true
  copy_tags_to_snapshot      = true
  deletion_protection        = true
  storage_encrypted          = true

  parameter_group_name = aws_db_parameter_group.mysql.name

  enabled_cloudwatch_logs_exports = [
    "error",
    "general",
    "slowquery",
  ]

  lifecycle {
    create_before_destroy = false
  }
}

