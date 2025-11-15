#!/bin/bash

set -x

export AWS_PAGER="" # disable pager
IMAGE_ID="ami-022814934cf926361" # This is the Ubuntu Jammy LTS release
SECURITY_GROUP_ID=$(cat data/security-group-id.txt)
SUBNET_ID=$(cat data/subnet-id.txt)
KEY_NAME="emb0x-key"

# Configure AWS for the EC2 creation
aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"
aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"
aws configure set region "$AWS_REGION"

# TEMPORARY: Teardown any existing instance with the same Name tag
# EC2 teardown - first, due to network dependencies
INSTANCE_IDS=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=emb0x-instance" \
    --query "Reservations[*].Instances[*].InstanceId" \
    --output text \
    --region "$AWS_REGION")

if [ -n "$INSTANCE_IDS" ]; then
    aws ec2 terminate-instances --instance-ids $INSTANCE_IDS --region "$AWS_REGION"
    aws ec2 wait instance-terminated --instance-ids $INSTANCE_IDS --region "$AWS_REGION"
    echo "Terminated instances: $INSTANCE_IDS"
else
    echo "No EC2 instances with Name=emb0x-instance found."
fi

# Create the instance
INSTANCE_ID=$(aws ec2 run-instances \
    --region $AWS_REGION \
    --image-id $IMAGE_ID \
    --count 1 \
    --instance-type t3.micro \
    --key-name $KEY_NAME \
    --security-group-ids $SECURITY_GROUP_ID \
    --subnet-id $SUBNET_ID \
    --user-data file://ec2-init.sh \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=emb0x-instance}]' \
    --query 'Instances[0].InstanceId' \
    --output text)

echo "$INSTANCE_ID" > data/instance-id.txt
echo "Created EC2 Instance: $INSTANCE_ID"

# Wait until instance is running
aws ec2 wait instance-running --instance-ids "$INSTANCE_ID" --region "$AWS_REGION"
# Optional: wait for both status checks to pass
# aws ec2 wait instance-status-ok --instance-ids "$INSTANCE_ID" --region "$AWS_REGION"

PUBLIC_IP=$(aws ec2 describe-instances \./l
  --instance-ids "$INSTANCE_ID" \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text \
  --region "$AWS_REGION")

echo "Public IP: $PUBLIC_IP"
