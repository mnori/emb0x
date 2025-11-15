#!/bin/bash

IMAGE_ID="ami-022814934cf926361" # This is the Ubuntu Jammy LTS release
SECURITY_GROUP_ID=$(cat security-group-id.txt)
SUBNET_ID=$(cat subnet-id.txt)
KEY_NAME="emb0x-key" # Make sure this key pair exists in your AWS account!

# aws configure
aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"
aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"
aws configure set region "$AWS_REGION"

# Need to do something about hardcoded region in the scripts
INSTANCE_ID=$(aws ec2 run-instances \
    --region $AWS_REGION \
    --image-id $IMAGE_ID \
    --count 1 \
    --instance-type t3.micro \
    --key-name $KEY_NAME \
    --security-group-ids $SECURITY_GROUP_ID \
    --subnet-id $SUBNET_ID \
    --user-data file://user-data.sh \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=emb0x-instance}]' \
    --query 'Instances[0].InstanceId' \
    --output text)

echo "$INSTANCE_ID" > instance-id.txt

echo "Created EC2 Instance: $INSTANCE_ID"