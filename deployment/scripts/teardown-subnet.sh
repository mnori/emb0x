#!/bin/bash

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