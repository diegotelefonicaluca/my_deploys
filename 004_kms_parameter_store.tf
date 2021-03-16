# KMS key ************************************************************************
resource "aws_kms_key" "kms_key" {
  description             = "kms key"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

resource "aws_kms_alias" "kms_alias" {
  name          = format("alias/%s-kms-key-%s", local.tags["project-name"], local.tags["env"])
  target_key_id = aws_kms_key.kms_key.key_id
}

# KMS rds_aurora secret *******************************************************************
# Encrypt plaintext
data "aws_kms_ciphertext" "rds_aurora_password" {
  key_id = aws_kms_key.kms_key.key_id

  plaintext = var.db_pass
}
# Create kms secret with encrypted password
data "aws_kms_secrets" "rds_aurora" {
  secret {
    name    = format("%s-rds-aurora-password-%s", local.tags["project-name"], local.tags["env"])
    payload = data.aws_kms_ciphertext.rds_aurora_password.ciphertext_blob
  }
}

# Parameter Store ***************************************************************
# AURORA 
resource "aws_ssm_parameter" "rds_aurora_pass" {
  name        = format("/%s/db/aurora/postgres/password", local.tags["env"])
  description = "data db password"
  type        = "SecureString"
  value       = var.db_pass

  tags = local.tags
}

resource "aws_ssm_parameter" "glue_catalog_connection" {
  name        = format("/%s/glue/catalog/connections/profuturodb", local.tags["env"])
  description = "Connection name to Profuturo DB for Glue"
  type        = "String"
  value       = aws_glue_connection.rds_aurora_connection.name

  tags = local.tags
}

# Glue Jobs
resource "aws_ssm_parameter" "glue_jobs_parameters" {
  for_each    = var.ssm_parameters_glue
  name        = replace(lookup(each.value, "name"), "{env}", local.tags["env"])
  description = lookup(each.value, "description")
  type        = lookup(each.value, "type")
  value       = lookup(each.value, "value")
  tags = local.tags
}