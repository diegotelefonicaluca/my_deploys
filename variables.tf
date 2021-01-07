variable "tags" {
  description = "Tags que se utilizan en la creación de los recursos"
  type        = map(any)
  default = {
    "Project"      = "dms201590"
    "project-name" = "dms201590"
    "description"  = "Mahou Brand Power Digital - Migracion ETLs"
    "owner"        = "LUCA-dms"
    "terraform"    = true
  }
}

variable "aws_region" {
  description = "Región"
  type        = string
  default     = "eu-west-1"
}

variable "azs" {
  description = "Zonas de disponibilidad"
  type        = list(any)
  default     = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

##########
### S3 ###
##########
variable "s3_de_bucket_name" {
  description = "Prefix name for the Data Engineering bucket (random digit will be added to the bucket name to make it unique)"
  type        = string
  default     = "data-engineering"
}

variable "s3_raw_bucket_name" {
  description = "Nombre del bucket para los datos en RAW"
  type        = string
  default     = "brandpower-pre-raw"
}

################
##### VPC ######
################
variable "cidr" {
  description = "Direccionamiento de red del VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "private_subnets" {
  description = "Redes privadas "
  type        = list(any)
  default     = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
}

variable "public_subnets" {
  description = "Redes publicas"
  type        = list(any)
  default     = ["10.10.11.0/24", "10.10.12.0/24", "10.10.13.0/24"]
}

#############################
### RDS Aurora PostgreSQL ###
#############################
# RDS engine types per region
# aws --region eu-west-1 rds describe-db-engine-versions --engine postgres

variable "db_name" {
  description = "Nombre de la BBDD"
  type        = string
  default     = "brand-power"
}

variable "db_master_username" {
  description = "Nombre del usuario master de la BBDD"
  type        = string
  default     = "dbmahouadmin"
}

variable "db_kms_pass" {
  description = "Password de la BBDD"
  type        = string
}

variable "db_engine" {
  description = "Tipo de la BBDD RDS"
  type        = string
  default     = "aurora-postgresql"
}

variable "db_engine_version" {
  description = "Version de la BBDD"
  type        = string
  default     = "11.6"
}

variable "db_engine_mode" {
  description = "Modo de la BBDD [global, paralellquery, provisioned, serverless, multimaster]"
  type        = string
  default     = "provisioned"
}

variable "db_maintenance_window" {
  description = "Cuando llevar a cabo una ventana de mantenimiento"
  type        = string
  default     = "Mon:00:00-Mon:03:00"
}

variable "db_backup_window" {
  description = "Cuando llevar a cabo backups"
  type        = string
  default     = "03:00-06:00"
}

variable "db_backup_retention_period" {
  description = "Cuanto tiempo mantener los backups (en dias)"
  type        = string
  default     = "7" #[1-35]
}

variable "db_replica_count" {
  description = "Version de la BBDD"
  type        = string
  default     = "1" # Default=1
}

variable "db_skip_final_snapshot" {
  description = "No realizar el snapshot final"
  type        = bool
  default     = true
}

variable "db_apply_immediately" {
  description = "Aplicar los cambios de forma inmediata"
  type        = bool
  default     = true
}

variable "db_copy_tags_to_snapshot" {
  description = "Copiar todos los tags del cluster a los snapshots"
  type        = bool
  default     = true
}

variable "db_instance" {
  description = "Tipo de instancia de la BBDD"
  type        = string
  default     = "db.t3.medium"
}

variable "snapshot_identifier" {
  description = "ID del snapshot desde el que se quiere crear la BBDD"
  type        = string
  default     = ""
}

variable "publicly_accessible" {
  description = "Si la DB debería tener una IP pública"
  type        = string
  default     = "false"
}

variable "enable_http_endpoint" {
  description = "Habilitar el Data API para Aurora Serverless"
  type        = string
  default     = "false"
}

variable "scaling_configuration" {
  description = "Map de atributos con propiedades de escalado. Solo válido cuando el engine_mode es 'serverless'"
  type        = map(string)
  default     = {}
}

############
### Glue ###
############

# Prefijo para los buckets legacy de RAW (ya creados en fases anteriores)
variable "raw_data_bucket" {
  description = "Bucket Data Name"
  type        = string
  default     = "bpd-raw"
}

variable "db_catalog" {
  description = "DB Catalog name"
  type        = string
  default     = "landing"
}

variable "crawler" {
  description = "Crawler"
  type        = string
  default     = "landing"
}

variable "connection_name" {
  description = "Nombre de la conexión"
  type        = string
  default     = "brand-power"
}

variable "database" {
  description = "Nombre de la BBDD a la que conectarse"
  type        = string
  default     = "brand-power"
}