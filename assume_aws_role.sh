#!/bin/bash

#ARN of the role to assume
role_arn='arn:aws:iam::758498799551:role/Brandpower-PRE-admin'

#Identifier for the assumed role session
role_session_name='mahou-pre-session'

profile_name='mahou-pre'

temp_role=$(aws sts assume-role --role-arn $role_arn --role-session-name $role_session_name)

export AWS_ACCESS_KEY_ID=$(echo $temp_role | jq -r .Credentials.AccessKeyId)
export AWS_SECRET_ACCESS_KEY=$(echo $temp_role | jq -r .Credentials.SecretAccessKey)
export AWS_SESSION_TOKEN=$(echo $temp_role | jq -r .Credentials.SessionToken)

aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID --profile $profile_name
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY --profile $profile_name
aws configure set aws_session_token $AWS_SESSION_TOKEN --profile $profile_name

expiration="$(echo $temp_role | jq -r .Credentials.Expiration)"

echo "Credentials expire at ${expiration}"