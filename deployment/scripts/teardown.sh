#!/bin/bash

# Security group teardown
if [ -f security-group-id.txt ]; then
    SECURITY_GROUP_ID=$(cat security-group-id.txt)
    aws ec2 delete-security-group --group-id "$SECURITY_GROUP_ID" --region eu-central-1
else
    echo "security-group-id.txt not found. Skipping security group teardown."
fi

# VPC teardown
if [ -f subnet-id.txt ]; then
    SUBNET_ID=$(cat subnet-id.txt)
    aws ec2 delete-subnet --subnet-id "$SUBNET_ID" --region eu-central-1
else
    echo "subnet-id.txt not found. Skipping subnet teardown."
fi

# VPC teardown
if [ -f vpc-id.txt ]; then
    VPC_ID=$(cat vpc-id.txt)
    aws ec2 delete-vpc --vpc-id "$VPC_ID" --region eu-central-1
else
    echo "vpc-id.txt not found. Skipping VPC teardown."
fi

