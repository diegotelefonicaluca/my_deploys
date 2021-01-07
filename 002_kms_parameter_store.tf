# This data are into main.tf
# data "aws_region" "current" {}
# data "aws_caller_identity" "current" {}

# KMS key ************************************************************************
resource "aws_kms_key" "kms_key" {
  description             = "kms key"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

resource "aws_kms_alias" "mahou_kms_key" {
  name          = format("alias/%s-kms-key-%s", local.tags["project-name"], local.tags["env"])
  target_key_id = aws_kms_key.kms_key.key_id
}
# output "kms_key_id" {
#   value = "${aws_kms_key.kms_key.key_id}"
# }

# KMS rds_aurora secret *******************************************************************
# Encrypt plaintext
data "aws_kms_ciphertext" "rds_aurora_password" {
  key_id = aws_kms_key.kms_key.key_id

  plaintext = var.db_kms_pass
}
# Create kms secret with encrpted password
data "aws_kms_secrets" "rds_aurora" {
  secret {
    name    = format("%s-rds-aurora-password-%s", local.tags["project-name"], local.tags["env"])
    payload = data.aws_kms_ciphertext.rds_aurora_password.ciphertext_blob
  }
}

# AURORA Parameter Store ***************************************************************
resource "aws_ssm_parameter" "rds_aurora" {
  name        = format("/%s/%s/db/aurora/postgres/password", local.tags["env"], local.tags["project-name"])
  description = "data db password"
  type        = "SecureString"
  value       = var.db_kms_pass

  tags = local.tags
}