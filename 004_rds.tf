# https://registry.terraform.io/modules/terraform-aws-modules/rds-aurora/aws/latest
module "db" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "~> 2.0"

  name = format("%s-%s-%s", var.db_name, local.tags.project-name, local.tags.env)

  engine         = var.db_engine
  engine_mode    = var.db_engine_mode
  engine_version = var.db_engine_version

  instance_type = var.db_instance

  vpc_id                     = module.vpc.vpc_id
  # TODO - Aclarar con el equipo si desplegar la BBDD en subred pública o privada
  subnets                    = module.vpc.private_subnets
  #subnets                    = module.vpc.public_subnets
  allowed_security_groups    = [aws_security_group.rds_aurora_vpc_access.id]
  publicly_accessible        = var.publicly_accessible
  vpc_security_group_ids     = [aws_security_group.my_dbs_access.id]

  snapshot_identifier        = var.snapshot_identifier
  enable_http_endpoint       = var.enable_http_endpoint
  scaling_configuration      = var.scaling_configuration
  
  replica_count = var.db_replica_count

  username = var.db_master_username
  password = data.aws_kms_secrets.rds_aurora.plaintext[format("%s-rds-aurora-password-%s", local.tags["project-name"], local.tags["env"])]

  port = "5432"

  apply_immediately     = var.db_apply_immediately
  copy_tags_to_snapshot = var.db_copy_tags_to_snapshot

  preferred_maintenance_window = var.db_maintenance_window
  preferred_backup_window      = var.db_backup_window
  skip_final_snapshot          = var.db_skip_final_snapshot

  # disable backups to create DB faster
  backup_retention_period = var.db_backup_retention_period

  final_snapshot_identifier_prefix = format("snapshot-%s-%s-%s", local.tags.project-name, local.tags.env, substr(replace(timestamp(), "/[:]/", "-"), 0, 16))

  tags = local.tags
}