#!/bin/bash

# Create a subnet in the VPC
VPC_ID=$(cat data/vpc-id.txt)
SUBNET_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 10.0.1.0/24 \
    --region $AWS_REGION \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=emb0x-subnet}]' \
    --query 'Subnet.SubnetId' --output text)

echo "Created Subnet: $SUBNET_ID"
echo "$SUBNET_ID" > data/subnet-id.txt
