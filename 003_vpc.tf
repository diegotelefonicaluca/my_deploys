#####################################################################
### Self access SG
#####################################################################
resource "aws_security_group" "rds_aurora_vpc_access" {
  name        = format("%s-%s-allow_self_access", local.tags.project-name, local.tags.env)
  description = "Allow traffic from resources with same SG"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Self access"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

#######################################################################
### Access from my public IP to my DBs
#######################################################################
data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

resource "aws_security_group" "my_dbs_access" {
  name        = format("%s-%s-MyDBsSG", local.tags.project-name, local.tags.env)
  description = "Allow traffic from my publicIP to the DBs in the migration"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Postgres Access from my publicIP"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

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
  enable_glue_endpoint              = true
  enable_rds_endpoint               = true
  enable_ssm_endpoint               = true
  glue_endpoint_security_group_ids  = [aws_security_group.rds_aurora_vpc_access.id, aws_security_group.my_dbs_access.id]
  rds_endpoint_security_group_ids   = [aws_security_group.rds_aurora_vpc_access.id, aws_security_group.my_dbs_access.id]
  ssm_endpoint_security_group_ids   = [aws_security_group.rds_aurora_vpc_access.id, aws_security_group.my_dbs_access.id]
  # glue_endpoint_subnet_ids #If omitted, private subnets will be used.

  # Public access AURORA
  # https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/2.25.0#public-access-to-rds-instances

  tags = local.tags
}