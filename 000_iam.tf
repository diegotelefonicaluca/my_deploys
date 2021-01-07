#----000_iam.tf----

/*
  Definition of Policies and Roles 
*/

/***********************************************************
IAM POLICIES
*/
######################################
### Policies for Glue Service Role ###
######################################

#TODO cambiar el data por el bucket cuando se cree nuevo
resource "aws_iam_policy" "s3_full_access" {
  name        = format("AmazonS3FullAccess_%s_%s", local.tags.project-name, local.tags.env)
  path        = "/"
  description = format("Allow full access just to %s-* bucket", data.aws_s3_bucket.data_engineering_bucket.id)

  policy      = templatefile("./iam_policies/AmazonS3FullAccess.tmpl", 
    { data_engineering_bucket_arn = format("%s", data.aws_s3_bucket.data_engineering_bucket.arn),
      raw_bucket_arn = format("%s", aws_s3_bucket.raw_bucket.arn),
      account_id = format("%s", data.aws_caller_identity.current.account_id)
    }
  )
}

# Policy used by AWS Glue service Role
resource "aws_iam_policy" "glue_service_role_policy" {
  name        = format("GlueServiceRolePolicy_%s_%s", local.tags.project-name, local.tags.env)
  path        = "/"
  description = "Custom policy to be used for AWS Glue to access resources"

  policy      = templatefile("./iam_policies/GlueServiceRolePolicy.tmpl", {})
}

# política para el SSM
resource "aws_iam_policy" "ssm_getParameters" {
  name        = format("ssm_getParameters_%s_%s", local.tags.project-name, local.tags.env)
  path        = "/"
  description = "Permite el acceso sobre las acciones de Get Parameter"

  policy      = templatefile("./iam_policies/SsmParameters.tmpl", 
    { region = format("%s", data.aws_region.current.name)
      account_id = format("%s", data.aws_caller_identity.current.account_id)
    }
  )
}

/***********************************************************
IAM ROLES creation
*/

# Role for AWS Glue service
resource "aws_iam_role" "glue_service_role" {
  name                  = format("AWSGlueServiceRole_%s_%s", local.tags.project-name, local.tags.env)
  description           = "Role used for AWS Glue service to access other resources"
  force_detach_policies = true
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "glue.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = local.tags
}

/***********************************************************
IAM ROLES POLICY ATTACHMENT
*/
resource "aws_iam_role_policy_attachment" "glue_role_policy_attachment" {
  role      = aws_iam_role.glue_service_role.name
  policy_arn = aws_iam_policy.glue_service_role_policy.arn
}

resource "aws_iam_role_policy_attachment" "glue_s3_policy_attachment" {
  role          = aws_iam_role.glue_service_role.name
  policy_arn    = aws_iam_policy.s3_full_access.arn
}

resource "aws_iam_role_policy_attachment" "glue_rds_policy_attachment" {
  role          = aws_iam_role.glue_service_role.name
  policy_arn    = "arn:aws:iam::aws:policy/AmazonRDSDataFullAccess"
}

resource "aws_iam_role_policy_attachment" "glue_ssm_policy_attachment" {
  role          = aws_iam_role.glue_service_role.name
  policy_arn    = aws_iam_policy.ssm_getParameters.arn
}