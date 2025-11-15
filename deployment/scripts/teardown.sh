#!/bin/bash
: "${AWS_REGION:=$AWS_REGION}"
export AWS_PAGER=""

# EC2 teardown - first, due to network dependencies
INSTANCE_IDS=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=emb0x-instance" \
    --query "Reservations[*].Instances[*].InstanceId" \
    --output text \
    --region "$AWS_REGION")

if [ -n "$INSTANCE_IDS" ]; then
    aws ec2 terminate-instances --instance-ids $INSTANCE_IDS --region "$AWS_REGION"
    echo "Terminated instances: $INSTANCE_IDS"
else
    echo "No EC2 instances with Name=emb0x-instance found."
fi

# Security group teardown
# Tear down ALL security groups named emb0x-security-group in this region (after EC2 termination)
SG_IDS=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=emb0x-security-group" \
  --query "SecurityGroups[].GroupId" \
  --output text \
  --region "$AWS_REGION")

if [ -n "$SG_IDS" ]; then
  for SG_ID in $SG_IDS; do
    echo "Deleting security group: $SG_ID"
    aws ec2 delete-security-group --group-id "$SG_ID" --region "$AWS_REGION" 2>/dev/null || echo "Could not delete $SG_ID (in use or default)."
  done
else
  echo "No security groups named emb0x-security-group found."
fi

# Subnet teardown - this must happen prior to VPC teardown
SUBNET_IDS=$(aws ec2 describe-subnets \
  --filters "Name=tag:Name,Values=emb0x-subnet" \
  --query "Subnets[].SubnetId" \
  --output text \
  --region "$AWS_REGION")

if [ -n "$SUBNET_IDS" ]; then
  for SUBNET_ID in $SUBNET_IDS; do
    echo "Deleting subnet: $SUBNET_ID"
    aws ec2 delete-subnet --subnet-id "$SUBNET_ID" --region "$AWS_REGION" 2>/dev/null || echo "Could not delete subnet $SUBNET_ID."
  done
else
  echo "No subnets named emb0x-subnet found."
fi

# Delete all VPCs tagged emb0x-vpc
VPC_IDS=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=emb0x-vpc" \
  --query "Vpcs[].VpcId" \
  --output text \
  --region "$AWS_REGION")

if [ -n "$VPC_IDS" ]; then
  for VPC_ID in $VPC_IDS; do
    echo "Deleting tagged VPC: $VPC_ID"
    aws ec2 delete-vpc --vpc-id "$VPC_ID" --region "$AWS_REGION" 2>/dev/null || echo "Could not delete VPC $VPC_ID (dependencies present)."
  done
else
  echo "No tagged VPCs (emb0x-vpc) found."
fi
