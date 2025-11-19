#!/bin/bash
set -euo pipefail
source ./secrets.env
: "${AWS_REGION:=eu-central-1}"
mkdir -p data

# Require existing VPC ID file
if [ ! -s data/vpc-id.txt ]; then
  echo "Missing data/vpc-id.txt (run create-vpc.sh first)"
  exit 1
fi
VPC_ID=$(tr -d '\r\n' < data/vpc-id.txt)

# Reuse existing subnet with Name=emb0x-subnet in this VPC
EXISTING_SUBNET_ID=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=emb0x-subnet" \
  --query 'Subnets[0].SubnetId' \
  --output text \
  --region "$AWS_REGION")

if [ -n "$EXISTING_SUBNET_ID" ] && [ "$EXISTING_SUBNET_ID" != "None" ]; then
  echo "Subnet already exists: $EXISTING_SUBNET_ID"
  echo "$EXISTING_SUBNET_ID" > data/subnet-id.txt
  exit 0
fi

# Create subnet
SUBNET_ID=$(aws ec2 create-subnet \
  --vpc-id "$VPC_ID" \
  --cidr-block 10.0.1.0/24 \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=emb0x-subnet}]' \
  --query 'Subnet.SubnetId' \
  --output text \
  --region "$AWS_REGION")

echo "Created Subnet: $SUBNET_ID"
echo "$SUBNET_ID" > data/subnet-id.txt
