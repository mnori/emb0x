#!/bin/bash

# Security group creation script for Emb0x deployment
REGION="--region ${AWS_REGION}"

# Variables
VPC_ID=$(cat data/vpc-id.txt)
SECURITY_GROUP_NAME="emb0x-security-group"

# Create the security group
SECURITY_GROUP_ID=$(aws ec2 create-security-group \
    $ENDPOINT $REGION \
    --group-name $SECURITY_GROUP_NAME \
    --description "Security group for Emb0x instance" \
    --vpc-id $VPC_ID \
    --query "GroupId" \
    --output text)

echo "$SECURITY_GROUP_ID" > data/security-group-id.txt

echo "Created Security Group: $SECURITY_GROUP_ID"

# Allow SSH (port 22)
aws ec2 authorize-security-group-ingress $ENDPOINT $REGION \
    --group-id $SECURITY_GROUP_ID \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0

# Allow HTTP (port 5000 for web app)
aws ec2 authorize-security-group-ingress $ENDPOINT $REGION \
    --group-id $SECURITY_GROUP_ID \
    --protocol tcp \
    --port 5000 \
    --cidr 0.0.0.0/0

# Allow MinIO (ports 9000 and 9001)
aws ec2 authorize-security-group-ingress $ENDPOINT $REGION \
    --group-id $SECURITY_GROUP_ID \
    --protocol tcp \
    --port 9000 \
    --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress $ENDPOINT $REGION \
    --group-id $SECURITY_GROUP_ID \
    --protocol tcp \
    --port 9001 \
    --cidr 0.0.0.0/0

# Allow MySQL (port 3306, optional)
aws ec2 authorize-security-group-ingress $ENDPOINT $REGION \
    --group-id $SECURITY_GROUP_ID \
    --protocol tcp \
    --port 3306 \
    --cidr 0.0.0.0/0

echo "Security group rules added."

echo "$SECURITY_GROUP_ID" > data/security-group-id.txt
