######################################
### S3 Buckets creation/definition ###
######################################
resource "aws_s3_bucket" "data_engineering_bucket" {
  bucket = format("%s-%s-%s", var.s3_de_bucket_name, local.tags.project-name, local.tags.env)
  acl           = "private"

  tags          =  local.tags
}

resource "aws_s3_bucket_public_access_block" "data_engineering_bucket_public_access_block" {
  bucket = aws_s3_bucket.data_engineering_bucket.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "datalake_bucket" {
  bucket    = format("%s-%s-%s", var.s3_datalake_bucket_name, local.tags.project-name, local.tags.env)
  acl       = "private"

  tags      =  local.tags
}

resource "aws_s3_bucket_public_access_block" "datalake_bucket_public_access_block" {
  bucket = aws_s3_bucket.datalake_bucket.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

# Create the directory structure into each bucket
resource "aws_s3_bucket_object" "de_dir_structure" {
  count  = length(var.de_s3_bucket_dirs)
  bucket = aws_s3_bucket.data_engineering_bucket.id
  key    = format("%s/",element(var.de_s3_bucket_dirs, count.index))
}

resource "aws_s3_bucket_object" "datalake_dir_structure" {
  count  = length(var.datalake_s3_bucket_dirs)
  bucket = aws_s3_bucket.datalake_bucket.id
  key    = format("%s/",element(var.datalake_s3_bucket_dirs, count.index))
}

/*
EJEMPLO PARA SINCRONIZAR CONTENIDOS EN S3
El comando s3 sync sincroniza el contenido de un bucket y un directorio, o el contenido de dos buckets
https://docs.aws.amazon.com/es_es/cli/latest/userguide/cli-services-s3-commands.html

resource "null_resource" "remove_and_upload_to_s3" {
  provisioner "local-exec" {
    command = "aws s3 sync ${path.module}/s3Contents s3://${aws_s3_bucket.site.id}"
  }
}
*/
