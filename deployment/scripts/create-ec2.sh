#!/bin/bash

# Dummy values for LocalStack (these can be anything)
IMAGE_ID="ami-12345678"
SECURITY_GROUP_ID="sg-12345678"
SUBNET_ID="subnet-12345678"
KEY_NAME="localstack-key"

export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

aws configure

aws ec2 run-instances \
    --endpoint-url http://localhost:4566 \
    --region us-east-1 \
    --image-id $IMAGE_ID \
    --count 1 \
    --instance-type t2.micro \
    --key-name $KEY_NAME \
    --security-group-ids $SECURITY_GROUP_ID \
    --subnet-id $SUBNET_ID \
    --user-data file://user-data.sh \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=emb0x-instance}]'