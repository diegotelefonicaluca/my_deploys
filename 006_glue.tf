
# TODO: Revisar políticas para hacerlas más específicas, sobre todo las de
# RDS y S3, tanto para los crawlers como los jobs 

###############################################################
###################### Data Catalog ###########################
###############################################################

# Databases
resource "aws_glue_catalog_database" "catalog_dbs" {
  for_each      = var.catalog_databases
  name          = format("%s-%s", lookup(each.value, "prefix_name"), local.tags.env)
  location_uri  = lookup(each.value, "location")
  description   = format("Database %s, inferred from Crawlers", lookup(each.value, "prefix_name"))
}

# Crawlers
resource "aws_glue_crawler" "crawlers" {
  for_each              = var.catalog_crawlers
  database_name         = format("%s-%s", lookup(each.value, "database_prefix_name"), local.tags.env)
  name                  = format("%s_%s", lookup(each.value, "prefix_name"), local.tags.env)
  table_prefix          = lookup(each.value, "table_prefix")
  configuration         = templatefile(lookup(each.value, "configuration_file_path"), { 
                            partition_update_behaviour = lookup(each.value, "partition_update_behaviour"), 
                            table_update_behaviour = lookup(each.value, "table_update_behaviour"), 
                            table_grouping_policy = lookup(each.value, "table_grouping_policy") 
                          })
  role                  = aws_iam_role.glue_service_role.arn
  schema_change_policy  {
    update_behavior = lookup(each.value, "schema_update_behaviour") #'LOG'|'UPDATE_IN_DATABASE'
    delete_behavior = lookup(each.value, "schema_delete_behaviour") #'LOG'|'DELETE_FROM_DATABASE'|'DEPRECATE_IN_DATABASE'
  }
  s3_target {
    path = format("s3://%s%s",aws_s3_bucket.datalake_bucket.id, lookup(each.value, "s3_target_sufix"))
  }
  tags =  local.tags
}

###############################################################
######################## ETL ##################################
###############################################################

# Glue Connection

# https://www.terraform.io/docs/providers/aws/r/glue_connection.html
resource "aws_glue_connection" "rds_aurora_connection" {

  name = format("%s_%s_%s", local.tags.project-name, var.connection_name, local.tags.env)

  connection_properties = {
    JDBC_CONNECTION_URL = format("jdbc:postgresql://%s:5432/%s", module.db.this_rds_cluster_endpoint, var.database)
    PASSWORD            = data.aws_kms_secrets.rds_aurora.plaintext[format("%s-rds-aurora-password-%s", local.tags["project-name"], local.tags["env"])]
    USERNAME            = var.db_master_username
  }

  physical_connection_requirements {
    availability_zone      = var.azs[0]
    security_group_id_list = [aws_security_group.rds_aurora_vpc_access.id]
    subnet_id              = module.vpc.private_subnets[0]
  }
}

# Enabling CloudWatch Logs and Metrics
# Create a new log group per each Glue Job
resource "aws_cloudwatch_log_group" "cw_log_groups" {
  for_each          = var.python_glue_jobs
  name              = replace(replace(lookup(each.value, "cloudwatch_log_group_name"), "{job_prefix_name}", lookup(each.value, "job_prefix_name")), "{env}", local.tags.env)
  retention_in_days = lookup(each.value, "cloudwatch_log_group_retention_days")
  tags              = local.tags
}

# Upload libs used by Glue Jobs
locals {
  libs_source_path = replace(abspath(path.root), "infrastructure/terraform", "engineering/glue/libs")
  jobs_source_path = replace(abspath(path.root), "infrastructure/terraform", "engineering/glue/scripts")
}
resource "aws_s3_bucket_object" "glue_libs" {
  for_each = fileset(local.libs_source_path, "*")
  bucket  = aws_s3_bucket.data_engineering_bucket.id
  acl     = "private"  # or can be "public-read"
  key     = format("/libs/%s/%s", local.tags.env, each.value)
  source  = format("%s/%s", local.libs_source_path, each.value)
  etag    = filemd5(format("%s/%s", local.libs_source_path, each.value))
}

# Upload Jobs Code Glue
resource "aws_s3_bucket_object" "glue_jobs_scripts" {
  for_each = fileset(local.jobs_source_path, "*")
  bucket  = aws_s3_bucket.data_engineering_bucket.id
  acl     = "private"  # or can be "public-read"
  key     = format("/glue-etl-jobs/%s/%s", local.tags.env, each.value)
  source  = format("%s/%s", local.jobs_source_path, each.value)
  etag    = filemd5(format("%s/%s", local.jobs_source_path, each.value))
}

################################################################################################################################
# Workflows

resource "aws_glue_workflow" "glue_workflows" {
  for_each    = var.glue_workflows
  name        = format("%s_%s", lookup(each.value, "prefix_name"), local.tags.env)
  description = lookup(each.value, "description")
}

################################################################################################################################
# Jobs
#
##########################
# PYTHON
##########################
resource "aws_glue_job" "python_glue_jobs" {
  for_each = var.python_glue_jobs
  name     = format("%s_%s", lookup(each.value, "job_prefix_name"), local.tags.env)
  role_arn = aws_iam_role.glue_service_role.arn

  glue_version = lookup(each.value, "glue_version")
  
  max_capacity      = lookup(each.value, "max_capacity")
  timeout           = lookup(each.value, "timeout")
  max_retries       = lookup(each.value, "max_retries")

  execution_property {
    max_concurrent_runs = lookup(each.value, "max_concurrent_runs")
  }

  command {
    name = lookup(each.value, "command_name")
    script_location = replace(replace(lookup(each.value, "script_location"), "{s3_data_eng_bucket_name}", aws_s3_bucket.data_engineering_bucket.id), "{env}", local.tags.env)
    python_version = lookup(each.value, "python_version")
  }

  connections = [aws_glue_connection.rds_aurora_connection.name]
  
  default_arguments = {
    "--extra-py-files"                    = replace(replace(lookup(each.value, "--extra-py-files"), "{s3_data_eng_bucket_name}", aws_s3_bucket.data_engineering_bucket.id), "{env}", local.tags.env)
    "--job-bookmark-option"               = lookup(each.value, "--job-bookmark-option")
    "--job-language"                      = lookup(each.value, "--job-language")
    "--TempDir"                           = replace(replace(lookup(each.value, "--TempDir"), "{s3_data_eng_bucket_name}", aws_s3_bucket.data_engineering_bucket.id), "{env}", local.tags.env)
    "--continuous-log-logGroup"           = aws_cloudwatch_log_group.cw_log_groups[each.key].name
    "--enable-continuous-cloudwatch-log"  = lookup(each.value, "--enable-continuous-cloudwatch-log")
    "--enable-continuous-log-filter"      = lookup(each.value, "--enable-continuous-log-filter")
    "--enable-glue-datacatalog"           = lookup(each.value, "--enable-glue-datacatalog")
    # ... custom arguments ...
    "--web"                               = lookup(each.value, "--web")
    "--prefix_ps"                         = replace(lookup(each.value, "--prefix_ps"), "{env}", local.tags.env)
    "--source"                            = lookup(each.value, "--source")
    "--page_access_token_source"          = lookup(each.value, "--page_access_token_source")
    "--sub_source"                        = lookup(each.value, "--sub_source")
    "--date"                              = lookup(each.value, "--date")
    "--table"                             = lookup(each.value, "--table")
    "--s3_subpath_in"                     = lookup(each.value, "--s3_subpath_in")
    "--s3_subpath_out"                    = lookup(each.value, "--s3_subpath_out")
  }

  /*non_overridable_arguments = {
    "s3_bucket" = replace(lookup(each.value, "env_var_s3_bucket"), "{s3_data_eng_bucket_name}", aws_s3_bucket.data_engineering_bucket.id)
  }*/
  
  tags       = local.tags
}

##########################
# SPARK
##########################
resource "aws_glue_job" "spark_glue_jobs" {
  for_each = var.spark_glue_jobs
  name     = format("%s_%s", lookup(each.value, "job_prefix_name"), local.tags.env)
  role_arn = aws_iam_role.glue_service_role.arn

  glue_version = lookup(each.value, "glue_version") //glue_version = 2 (Spark 2.4, Python3)
  
  worker_type       = lookup(each.value, "worker_type")
  number_of_workers = lookup(each.value, "number_of_workers")
  timeout           = lookup(each.value, "timeout")
  max_retries       = lookup(each.value, "max_retries")

  execution_property {
    max_concurrent_runs = lookup(each.value, "max_concurrent_runs")
  }

  command {
    name = lookup(each.value, "command_name")
    script_location = replace(replace(lookup(each.value, "script_location"), "{s3_data_eng_bucket_name}", aws_s3_bucket.data_engineering_bucket.id), "{env}", local.tags.env)
    python_version = lookup(each.value, "python_version")
  }
  
  default_arguments = {
    "--job-bookmark-option"               = lookup(each.value, "--job-bookmark-option")
    "--job-language"                      = lookup(each.value, "--job-language")
    "--TempDir"                           = replace(replace(lookup(each.value, "--TempDir"), "{s3_data_eng_bucket_name}", aws_s3_bucket.data_engineering_bucket.id), "{env}", local.tags.env)
    "--continuous-log-logGroup"           = aws_cloudwatch_log_group.cw_log_groups[each.key].name
    "--enable-continuous-cloudwatch-log"  = lookup(each.value, "--enable-continuous-cloudwatch-log")
    "--enable-continuous-log-filter"      = lookup(each.value, "--enable-continuous-log-filter")
    "--enable-glue-datacatalog"           = lookup(each.value, "--enable-glue-datacatalog")
    "--enable-metrics"                    = lookup(each.value, "--enable-metrics")
    "--enable-spark-ui"                   = lookup(each.value, "--enable-spark-ui")
    "--spark-event-logs-path"             = replace(lookup(each.value, "--spark-event-logs-path"), "{s3_data_eng_bucket_name}", aws_s3_bucket.data_engineering_bucket.id)
    # ... custom arguments ...
    # TODO add custom arguments
  }

  tags       = local.tags
}

################################################################################################################################
# Triggers
# This Triggers section will generate multiple types of Triggers automatically (based on tfvars configuration), such as:
#
#     * SCHEDULED Triggers:
#         - Triggering Scheduled Actions
#
#     * CONDITIONAL Triggers:
#         - Triggering Jobs Actions based on Conditions over Crawlers
#         - Triggering Jobs Actions based on Conditions over Jobs
#         - Triggering Crawlers Actions based on Conditions over Jobs
#         - Triggering Crawlers Actions based on Conditions over Crawlers
#
#     * ON-DEMAND Triggers:
#         - Triggering Crawlers Actions
#
################################################################################################################################

# Triggers for Crawlers to be triggered as "Action" and Scheduled executions
resource "aws_glue_trigger" "glue_triggers_scheduled_jobs_action" {
  for_each  = var.glue_triggers_scheduled_jobs_action
  name      = format("%s_%s", lookup(each.value, "prefix_name"), local.tags.env)
  type      = lookup(each.value, "type")
  schedule  = lookup(each.value, "schedule")

  dynamic "actions" {
    for_each  = split(",", lookup(each.value, "jobs_prefix_to_trigger_list"))
    content {
      job_name = format("%s_%s", trimspace(actions.value), local.tags.env)
      arguments = {
        "--web"             = lookup(each.value, "--web")
        "--date"            = lookup(each.value, "--date")
        "--sub_source"      = lookup(each.value, "--sub_source")
        "--table"           = lookup(each.value, "--table")
        "--source"          = lookup(each.value, "--source")
        "--s3_subpath_in"   = lookup(each.value, "--s3_subpath_in")
        "--s3_subpath_out"  = lookup(each.value, "--s3_subpath_out")
      }
      timeout = lookup(each.value, "--job_timeout")
    }
  }

  workflow_name = aws_glue_workflow.glue_workflows[lookup(each.value, "associated_workflow_map_key")].name
  #ej: workflow_name = aws_glue_workflow.glue_workflows["workflow6"].name

  tags       = local.tags
}

# Triggers for Jobs to be triggered as "Action" and Crawler based "Conditions"
resource "aws_glue_trigger" "glue_triggers_jobs_action_crawlers_condition" {
  for_each  = var.glue_triggers_jobs_action_crawlers_condition
  name      = format("%s_%s", lookup(each.value, "prefix_name"), local.tags.env)
  type      = lookup(each.value, "type")

  dynamic "actions" {
    for_each  = split(",", lookup(each.value, "jobs_to_trigger_list"))
    content {
      job_name = replace(trimspace(actions.value), "{env}", local.tags.env)
    }
  }

  predicate {
    dynamic "conditions" {
      for_each = split(",", lookup(each.value, "condition_crawler_prefix_name_list"))
      content {
        crawler_name  = format("%s_%s", trimspace(conditions.value), local.tags.env)
        crawl_state   = lookup(each.value, "condition_crawler_state")
      }
    }
  }

  workflow_name = aws_glue_workflow.glue_workflows[lookup(each.value, "associated_workflow_map_key")].name
  #ej: workflow_name = aws_glue_workflow.glue_workflows["workflow2"].name

  tags          = local.tags
}

# Triggers for Crawlers to be triggered as "Action" and Jobs based "Conditions"
resource "aws_glue_trigger" "glue_triggers_crawlers_action_jobs_condition" {
  for_each  = var.glue_triggers_crawlers_action_jobs_condition
  name      = format("%s_%s", lookup(each.value, "prefix_name"), local.tags.env)
  type      = lookup(each.value, "type")

  dynamic "actions" {
    for_each  = split(",", lookup(each.value, "crawlers_prefix_to_trigger_list"))
    content {
      crawler_name = format("%s_%s", trimspace(actions.value), local.tags.env)
    }
  }

  predicate {
    dynamic "conditions" {
      for_each = split(",", lookup(each.value, "condition_job_prefix_name_list"))
      content {
        job_name  = format("%s_%s", trimspace(conditions.value), local.tags.env)
        state     = lookup(each.value, "condition_job_state")
      }
    }
  }

  workflow_name = aws_glue_workflow.glue_workflows[lookup(each.value, "associated_workflow_map_key")].name
  #ej: workflow_name = aws_glue_workflow.glue_workflows["workflow3"].name
  
  tags       = local.tags
}

# Triggers for Crawlers to be triggered as "Action" and Crawler based "Conditions"
resource "aws_glue_trigger" "glue_triggers_crawlers_action_crawlers_condition" {
  for_each  = var.glue_triggers_crawlers_action_crawlers_condition
  name      = format("%s_%s", lookup(each.value, "prefix_name"), local.tags.env)
  type      = lookup(each.value, "type")

  dynamic "actions" {
    for_each  = split(",", lookup(each.value, "crawlers_prefix_to_trigger_list"))
    content {
      crawler_name = format("%s_%s", trimspace(actions.value), local.tags.env)
    }
  }

  predicate {
    dynamic "conditions" {
      for_each = split(",", lookup(each.value, "condition_crawler_prefix_name_list"))
      content {
        crawler_name  = format("%s_%s", trimspace(conditions.value), local.tags.env)
        crawl_state     = lookup(each.value, "condition_crawler_state")
      }
    }
  }

  workflow_name = aws_glue_workflow.glue_workflows[lookup(each.value, "associated_workflow_map_key")].name
  #ej: workflow_name = aws_glue_workflow.glue_workflows["workflow4"].name

  tags       = local.tags
}

# Triggers for Jobs to be triggered as "Action" and Jobs based "Conditions"
resource "aws_glue_trigger" "glue_triggers_jobs_action_jobs_condition" {
  for_each  = var.glue_triggers_jobs_action_jobs_condition
  name      = format("%s_%s", lookup(each.value, "prefix_name"), local.tags.env)
  type      = lookup(each.value, "type")

  dynamic "actions" {
    for_each  = split(",", lookup(each.value, "jobs_to_trigger_list"))
    content {
      job_name = replace(trimspace(actions.value), "{env}", local.tags.env)
    }
  }

  predicate {
    dynamic "conditions" {
      for_each = split(",", lookup(each.value, "condition_job_prefix_name_list"))
      content {
        job_name  = format("%s_%s", trimspace(conditions.value), local.tags.env)
        state     = lookup(each.value, "condition_job_state")
      }
    }
  }

  workflow_name = aws_glue_workflow.glue_workflows[lookup(each.value, "associated_workflow_map_key")].name
  #ej: workflow_name = aws_glue_workflow.glue_workflows["workflow5"].name

  tags       = local.tags
}

# Triggers for Crawlers to be triggered as "Action" and On-demand executions
resource "aws_glue_trigger" "glue_triggers_on_demand_crawlers_action" {
  for_each  = var.glue_triggers_on_demand_crawlers_action
  name      = format("%s_%s", lookup(each.value, "prefix_name"), local.tags.env)
  type      = lookup(each.value, "type")

  dynamic "actions" {
    for_each  = split(",", lookup(each.value, "crawlers_prefix_to_trigger_list"))
    content {
      crawler_name = format("%s_%s", trimspace(actions.value), local.tags.env)
    }
  }

  workflow_name = aws_glue_workflow.glue_workflows[lookup(each.value, "associated_workflow_map_key")].name
  #ej: workflow_name = aws_glue_workflow.glue_workflows["workflow6"].name

  tags       = local.tags
}