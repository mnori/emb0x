#!/bin/bash

# Reuse existing VPC with Name=emb0x-vpc
EXISTING_VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=emb0x-vpc" \
  --query 'Vpcs[0].VpcId' \
  --output text \
  --region "$AWS_REGION")

if [ -n "$EXISTING_VPC_ID" ] && [ "$EXISTING_VPC_ID" != "None" ]; then
  echo "VPC already exists: $EXISTING_VPC_ID"
  echo "$EXISTING_VPC_ID" > data/vpc-id.txt
  exit 0
fi

# Create new VPC
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --region "$AWS_REGION" \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=emb0x-vpc}]' \
  --query 'Vpc.VpcId' --output text)

echo "Created VPC: $VPC_ID"
echo "$VPC_ID" > data/vpc-id.txt
