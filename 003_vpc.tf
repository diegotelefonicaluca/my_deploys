# https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/2.70.0
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.70.0"

  name = format("vpc-%s-%s", local.tags.project-name, local.tags.env)

  cidr = var.cidr

  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  default_vpc_enable_dns_hostnames  = true
  enable_dns_hostnames              = true
  enable_nat_gateway                = true
  enable_s3_endpoint                = true
  #enable_glue_endpoint              = true
  #enable_rds_endpoint               = true
  #enable_ssm_endpoint               = true
  #glue_endpoint_security_group_ids  = [aws_security_group.rds_aurora_vpc_access.id, aws_security_group.my_dbs_access.id]
  #rds_endpoint_security_group_ids   = [aws_security_group.rds_aurora_vpc_access.id, aws_security_group.my_dbs_access.id]
  #ssm_endpoint_security_group_ids   = [aws_security_group.rds_aurora_vpc_access.id, aws_security_group.my_dbs_access.id]
  # glue_endpoint_subnet_ids #If omitted, private subnets will be used.

  # Public access AURORA
  # https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/2.25.0#public-access-to-rds-instances

  tags = local.tags
}