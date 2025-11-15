#!/bin/bash

# Security group creation script for Emb0x deployment
# ENDPOINT="--endpoint-url http://localhost:4566"
REGION="--region ${AWS_REGION}"

# Variables
VPC_ID=$(cat vpc-id.txt)
# VPC_ID=$(aws ec2 describe-vpcs $ENDPOINT $REGION --query "Vpcs[0].VpcId" --output text)
SECURITY_GROUP_NAME="emb0x-security-group"

# Check if the security group already exists
# EXISTING_SECURITY_GROUP_ID=$(aws ec2 describe-security-groups \
#     $ENDPOINT $REGION \
#     --filters "Name=group-name,Values=$SECURITY_GROUP_NAME" \
#     --query "SecurityGroups[0].GroupId" \
#     --output text 2>/dev/null)

# if [ "$EXISTING_SECURITY_GROUP_ID" != "None" ]; then
#     echo "Security group '$SECURITY_GROUP_NAME' already exists with ID: $EXISTING_SECURITY_GROUP_ID"
#     SECURITY_GROUP_ID=$EXISTING_SECURITY_GROUP_ID
# else
# Create the security group
SECURITY_GROUP_ID=$(aws ec2 create-security-group \
    $ENDPOINT $REGION \
    --group-name $SECURITY_GROUP_NAME \
    --description "Security group for Emb0x instance" \
    --vpc-id $VPC_ID \
    --query "GroupId" \
    --output text)

echo "$SECURITY_GROUP_ID" > security-group-id.txt

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

echo "$SECURITY_GROUP_ID" > security-group-id.txt
# fi