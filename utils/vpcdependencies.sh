#!/bin/bash
VPC_ID="vpc-06540cad509bec8de"

aws ec2 describe-internet-gateways --filters 'Name=attachment.vpc-id,Values='$VPC_ID | grep InternetGatewayId
aws ec2 describe-subnets --filters 'Name=vpc-id,Values='$VPC_ID | grep SubnetId
aws ec2 describe-route-tables --filters 'Name=vpc-id,Values='$VPC_ID | grep RouteTableId
aws ec2 describe-network-acls --filters 'Name=vpc-id,Values='$VPC_ID | grep NetworkAclId
aws ec2 describe-vpc-peering-connections --filters 'Name=requester-vpc-info.vpc-id,Values='$VPC_ID | grep VpcPeeringConnectionId
aws ec2 describe-vpc-endpoints --filters 'Name=vpc-id,Values='$VPC_ID | grep VpcEndpointId
aws ec2 describe-nat-gateways --filter 'Name=vpc-id,Values='$VPC_ID | grep NatGatewayId
aws ec2 describe-security-groups --filters 'Name=vpc-id,Values='$VPC_ID | grep GroupId
aws ec2 describe-instances --filters 'Name=vpc-id,Values='$VPC_ID | grep InstanceId
aws ec2 describe-vpn-connections --filters 'Name=vpc-id,Values='$VPC_ID | grep VpnConnectionId
aws ec2 describe-vpn-gateways --filters 'Name=attachment.vpc-id,Values='$VPC_ID | grep VpnGatewayId
aws ec2 describe-network-interfaces --filters 'Name=vpc-id,Values='$VPC_ID | grep NetworkInterfaceId