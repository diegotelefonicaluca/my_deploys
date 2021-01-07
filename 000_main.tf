locals {
  tags = merge(var.tags, map("env", terraform.workspace))
}

terraform {
  required_version = "~> 0.14.2"
  backend "s3" {}
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Current region and account
data "aws_region" "current" {}
data "aws_caller_identity" "current" {} #data.aws_caller_identity.current.account_id

######################################
### S3 Buckets creation/definition ###
######################################
//TODO cambiar el data por creación de los buckets
data "aws_s3_bucket" "data_engineering_bucket" {
  bucket = format("%s-%s", var.s3_de_bucket_name, local.tags.project-name)
}

resource "aws_s3_bucket" "raw_bucket" {
  bucket = format("%s-%s", var.s3_raw_bucket_name, local.tags.project-name)
}
