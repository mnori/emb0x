#!/bin/bash

# Create a VPC (if needed)
VPC_ID=$(aws ec2 create-vpc \
    --cidr-block 10.0.0.0/16 \
    --region $AWS_REGION \
    --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=emb0x-vpc}]' \
    --query 'Vpc.VpcId' --output text)

echo "Created VPC: $VPC_ID"
echo "$VPC_ID" > data/vpc-id.txt
