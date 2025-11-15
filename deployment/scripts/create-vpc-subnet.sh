#!/bin/bash

# Create a VPC (if needed)
VPC_ID=$(aws ec2 create-vpc \
    --cidr-block 10.0.0.0/16 \
    --region $AWS_REGION \
    --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=emb0x-vpc}]' \
    --query 'Vpc.VpcId' --output text)

echo "Created VPC: $VPC_ID"
echo "$VPC_ID" > data/vpc-id.txt

# Create a subnet in the VPC
SUBNET_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 10.0.1.0/24 \
    --region $AWS_REGION \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=emb0x-subnet}]' \
    --query 'Subnet.SubnetId' --output text)

echo "Created Subnet: $SUBNET_ID"
echo "$SUBNET_ID" > data/subnet-id.txt
