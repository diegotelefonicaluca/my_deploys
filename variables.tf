variable "tags" {
  description = "Tags que se utilizan en la creación de los recursos"
  type        = map(any)
  default = {
    "Project"      = "ej211602"
    "project-name" = "ej211602"
    "description"  = "Telefonica ProFuturo - Unidad de Datos 2021"
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

#############################
### PROFUTURO-REPO-FE TED ###
#############################
variable "ec2_repo_fe_region" {
  description = "Región de la EC2 de TED desde la que se ejecuta el aws s3 sync"
  type        = string
  default     = "eu-west-1"
}

variable "ec2_repo_fe_accountid" {
  description = "Account-Id de la EC2 de TED desde la que se ejecuta el aws s3 sync"
  type        = string
  default     = "339916744372"
}

variable "ec2_repo_fe_instanceid" {
  description = "Instance-Id de la EC2 de TED desde la que se ejecuta el aws s3 sync"
  type        = string
  default     = "i-0c8284594f654b4c3"
}

##########
### S3 ###
##########
variable "s3_de_bucket_name" {
  description = "Prefix name for the Data Engineering bucket ('project-name' and 'env', will be added to the bucket name to make it unique)"
  type        = string
  default     = "data-engineering"
}

variable "de_s3_bucket_dirs" {
  description = "Dirs structure to be created into the Data Engineering Bucket"
  type    = list(string)
  default = ["glue-etl-jobs", "libs"]
}

variable "s3_datalake_bucket_name" {
  description = "Prefix name for the Datalake bucket ('project-name' and 'env', will be added to the bucket name to make it unique)"
  type        = string
  default     = "profuturo-datalake"
}

variable "datalake_s3_bucket_dirs" {
  description = "Dirs structure to be created into the Datalake Bucket"
  type    = list(string)
  default = ["pre-in", "in", "raw", "pre-proc", "proc", "staging"]
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
  default     = "profuturodb"
}

variable "db_master_username" {
  description = "Nombre del usuario master de la BBDD"
  type        = string
  default     = "profuturoadmin"
}

variable "db_pass" {
  description = "Password de la BBDD"
  type        = string
  default     = "Pr0fu7ur0P4ss"
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

###########################
### SSM Parameter Store ###
###########################
variable "ssm_parameters_glue" {
  description = "Map de Maps donde key=Parameter_ID y value=map conteniendo un conjunto de configuraciones para cada Parameter utilizados en Jobs de Glue"
  type        = map(map(string))
  default     = {}
}

############
### Glue ###
############
variable "catalog_databases" {
  description = "Map of Maps where key=catalog_db identifier and value=map containing a set of configs for each database"
  type        = map(map(string))
  default     = {
    db1 = {
      prefix_name = "profuturo_catalog_db"
      location    = ""
    }
  }
}

variable "connection_name" {
  description = "Nombre de la conexión"
  type        = string
  default     = "profuturodb_conn"
}

variable "database" {
  description = "Nombre de la BBDD (Aurora) a la que conectarse desde la conexión de Glue"
  type        = string
  default     = "profuturodb"
}
variable "catalog_crawlers" {
  description = "Map of Maps where key=Crawler identifier and value=map containing a set of configs for each crawler"
  type        = map(map(string))
  default  = {}
}

variable "python_glue_jobs" {
  description = "Map of Maps where key=Glue Job Identifier and value=map containing a set of configs for each Glue Job"
  type        = map(map(string))
  default  = {}
}

variable "spark_glue_jobs" {
  description = "Map of Maps where key=Glue Job Identifier and value=map containing a set of configs for each Glue Job"
  type        = map(map(string))
  default  = {
  }
}

variable "glue_workflows" {
  description = "Map of Maps where key=Workflow identifier and value=map containing a set of configs foe each Glue Workflow"
  type        = map(map(string))
  default = {}
}

variable "glue_triggers_scheduled_jobs_action" {
  description = "Map of Maps where key=Glue Trigger Identifier and value=map containing a set of configs for each Glue trigger (with action on Glue Jobs and Scheduled executions)"
  type        = map(map(any))
  default     = {}
}

variable "glue_triggers_jobs_action_crawlers_condition" {
  description = "Map of Maps where key=Glue Trigger Identifier and value=map containing a set of configs for each Glue trigger (with action on Glue Jobs and Crawlers based conditions)"
  type        = map(map(any))
  default     = {
    
  }
}

variable "glue_triggers_crawlers_action_jobs_condition" {
  description = "Map of Maps where key=Glue Trigger Identifier and value=map containing a set of configs for each Glue trigger (with action on Glue Crawlers and Jobs based conditions)"
  type        = map(map(any))
  default     = {
  }
}

variable "glue_triggers_crawlers_action_crawlers_condition" {
  description = "Map of Maps where key=Glue Trigger Identifier and value=map containing a set of configs for each Glue trigger (with action on Glue Crawlers and Crawler based conditions)"
  type        = map(map(any))
  default     = {
    
  }
}

variable "glue_triggers_jobs_action_jobs_condition" {
  description = "Map of Maps where key=Glue Trigger Identifier and value=map containing a set of configs for each Glue trigger (with action on Glue Jobs and Jobs based conditions)"
  type        = map(map(any))
  default     = {

  }
}

variable "glue_triggers_on_demand_crawlers_action" {
  description = "Map of Maps where key=Glue Trigger Identifier and value=map containing a set of configs for each Glue trigger (with action on Glue Crawlers and On-demand executions)"
  type        = map(map(any))
  default     = {
    
  }
}