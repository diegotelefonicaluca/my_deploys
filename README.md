# CÓMO USAR ESTE TERRAFORM

  

## 1. INTRODUCCION
La presente implementación soporta la creación de los siguientes recursos en AWS:

# 2. CONFIGURAR VARIABLES

# 3. EJECUTAR DESPLIEGUE

## 3.1 BEFORE TERRAFORM INIT

 - **Config backend**:

	- Create a bucket, with the name specified into main.tf backend config, to store the terraform deployment states.

  

	- Create a DynamoDB Table with the name specified into main.tf backend config and with LockID key.


- **Set AWS CLI**:

	- Set AWS CLI profile:
	`export AWS_PROFILE="profuturo-dev"`
	
	- Assume target AWS Account Role (in case it is needed).

  

## 3.2 TERRAFORM INIT, PLAN & APPLY

- Init terraform with env backend config.:
`terraform init --backend-config="./backends/DEV/backend.tfvars"`

- Create new workspace with the environment name: i.e.: "dev"
`terraform workspace new dev`

- Plan the deployment
`terraform plan -var-file="./backends/DEV/config.tfvars" -out="./plans/dev-plan"`

- Apply the Terraform plan
`terraform apply "./plans/dev-plan"`

  

## 3.3 TERRAFORM DESTROY
`terraform destroy -var-file="./DEV/config.tfvars"`