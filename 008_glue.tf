
# TODO: Revisar políticas para hacerlas más específicas, sobre todo las de
# RDS y S3, tanto para los crawlers como los jobs 

###############################################################
###################### Data Catalog ###########################
###############################################################


/*# Landing Database
resource "aws_glue_catalog_database" "db_landing" {
  name        = var.db_catalog
  description = "Data infered from Crawlers"
}


# Crawlers # 
resource "aws_glue_crawler" "crawler_list" {
  database_name = aws_glue_catalog_database.db_landing.name
  name          = "${var.crawler}-${local.tags.env}"
  role          = aws_iam_role.glue_full_access_s3_rds_logs.arn

  s3_target {
    path = "s3://${var.raw_data_bucket}-${local.tags.env}/"
  }
}*/

###############################################################
######################## ETL ##################################
###############################################################
# https://www.terraform.io/docs/providers/aws/r/glue_connection.html
resource "aws_glue_connection" "rds_aurora_postgres_serverless" {

  name = format("%s_%s_%s", local.tags.project-name, var.connection_name, local.tags.env)

  connection_properties = {
    JDBC_CONNECTION_URL = format("jdbc:postgresql://%s:5432/%s", module.db.this_rds_cluster_endpoint, var.database)
    PASSWORD            = data.aws_kms_secrets.rds_aurora.plaintext[format("%s-rds-aurora-password-%s", local.tags["project-name"], local.tags["env"])]
    USERNAME            = var.db_master_username
  }

  physical_connection_requirements {
    availability_zone      = var.azs[0]
    security_group_id_list = [aws_security_group.rds_aurora_vpc_access.id]
    subnet_id              = module.vpc.public_subnets[0]
  }
}

/*
resource "aws_s3_bucket_object" "glue_facebook" {
  #depends_on = ["${data.archive_file.lambda_do_evaluation}"]
  bucket = aws_s3_bucket.app-bucket.id
  key    = "app/glue/facebook_to_rds.py"
  source = "${path.module}/glue/src/facebook/facebook_to_rds.py"

  etag = file("${path.module}/glue/src/facebook/facebook_to_rds.py")

  tags = local.tags
}

# https://www.terraform.io/docs/providers/aws/r/glue_job.html
resource "aws_glue_job" "facebook" {
  name     = "facebook_${local.tags.project-name}_${local.tags.env}"
  role_arn = aws_iam_role.glue_full_access_s3_rds_logs.arn

  # https://docs.aws.amazon.com/glue/latest/dg/release-notes.html
  glue_version = "1.0"
  max_capacity = "2"

  connections = [aws_glue_connection.rds_aurora_postgres_data.id]

  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.app-bucket.id}/${aws_s3_bucket_object.glue_facebook.key}"
  }

  tags = local.tags
}
*/
