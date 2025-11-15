#!/bin/bash

# EC2 teardown - first, due to network dependencies
if [ -f instance-id.txt ]; then
    INSTANCE_ID=$(cat instance-id.txt)
    aws ec2 terminate-instances --instance-ids "$INSTANCE_ID" --region "$AWS_REGION"
else
    echo "instance-id.txt not found. Skipping EC2 teardown."
fi

# Security group teardown
if [ -f security-group-id.txt ]; then
    SECURITY_GROUP_ID=$(cat security-group-id.txt)
    aws ec2 delete-security-group --group-id "$SECURITY_GROUP_ID" --region "$AWS_REGION"
else
    echo "security-group-id.txt not found. Skipping security group teardown."
fi

# Subnet teardown - this must happen prior to VPC teardown
if [ -f subnet-id.txt ]; then
    SUBNET_ID=$(cat subnet-id.txt)
    aws ec2 delete-subnet --subnet-id "$SUBNET_ID" --region "$AWS_REGION"
else
    echo "subnet-id.txt not found. Skipping subnet teardown."
fi

# VPC teardown
if [ -f vpc-id.txt ]; then
    VPC_ID=$(cat vpc-id.txt)
    aws ec2 delete-vpc --vpc-id "$VPC_ID" --region "$AWS_REGION"
else
    echo "vpc-id.txt not found. Skipping VPC teardown."
fi
