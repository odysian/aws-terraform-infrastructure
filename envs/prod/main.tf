module "networking" {
  source = "../../modules/networking"

  project_name         = var.project_name
  aws_region           = var.aws_region
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "compute" {
  source = "../../modules/compute"

  project_name          = var.project_name
  instance_type         = var.instance_type
  asg_min_size          = var.asg_min_size
  asg_max_size          = var.asg_max_size
  asg_desired_capacity  = var.asg_desired_capacity
  public_subnet_ids     = module.networking.public_subnet_ids
  web_security_group_id = module.networking.web_security_group_id
  vpc_id                = module.networking.vpc_id
  db_host               = module.database.db_host
  db_name               = var.db_name
  db_username           = var.db_username
  db_password           = var.db_password
  db_endpoint           = module.database.db_endpoint
}

module "database" {
  source = "../../modules/database"

  db_name                    = var.db_name
  db_password                = var.db_password
  db_username                = var.db_username
  project_name               = var.project_name
  database_security_group_id = module.networking.database_security_group_id
  private_subnet_ids         = module.networking.private_subnet_ids

}

module "monitoring" {
  source = "../../modules/monitoring"

  project_name               = var.project_name
  aws_region                 = var.aws_region
  alarm_email                = var.alarm_email
  cpu_alarm_threshold        = var.cpu_alarm_threshold
  unhealthy_target_threshold = var.unhealthy_target_threshold
  rds_storage_threshold      = var.rds_storage_threshold
  db_identifier              = module.database.db_identifier
  autoscaling_group_name     = module.compute.autoscaling_group_name
  lb_arn_suffix              = module.compute.lb_arn_suffix
  lb_tg_arn_suffix           = module.compute.lb_tg_arn_suffix
}
