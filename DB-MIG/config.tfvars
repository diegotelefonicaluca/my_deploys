################
##### VPC ######
################
cidr            = "10.123.0.0/16"
private_subnets = ["10.123.1.0/24", "10.123.2.0/24"]
public_subnets  = ["10.123.11.0/24", "10.123.12.0/24"]

#########################
### Aurora PostgreSQL ###
#########################
db_kms_pass             = "testLuc4P4ss"
snapshot_identifier     = "brand-power-postgresql-serverless"

# Aurora Serverless
db_engine_version       = "10.12"
db_name                 = "brand-power-serverless"
enable_http_endpoint    = true
publicly_accessible     = true
db_engine_mode          = "serverless"
db_backup_window        = ""
db_maintenance_window   = ""
db_replica_count        = "0"
scaling_configuration   = {
    auto_pause               = true
    max_capacity             = 2
    min_capacity             = 2
    seconds_until_auto_pause = 3600
    timeout_action           = "ForceApplyCapacityChange"
  }

############
### Glue ###
############
connection_name = "brand-power-serverless"
database        = "brand_power"