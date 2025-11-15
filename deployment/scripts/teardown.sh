#!/bin/bash
# Stops terminal being held up by AWS CLI pagers
: "${AWS_REGION:=$AWS_REGION}"
export AWS_PAGER=""

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

# Security group teardown
# Tear down ALL security groups named emb0x-security-group in this region (after EC2 termination)
# Security group teardown (delete all named emb0x-security-group and wait)
echo "Deleting security groups named emb0x-security-group..."
SG_IDS=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=emb0x-security-group" \
  --query "SecurityGroups[].GroupId" \
  --output text \
  --region "$AWS_REGION")

if [ -z "$SG_IDS" ]; then
  echo "No matching security groups found."
else
  for SG_ID in $SG_IDS; do
    [ -z "$SG_ID" ] && continue
    # Skip default SGs (defensive)
    SG_NAME=$(aws ec2 describe-security-groups \
      --group-ids "$SG_ID" \
      --query "SecurityGroups[0].GroupName" \
      --output text \
      --region "$AWS_REGION" 2>/dev/null)
    if [ "$SG_NAME" = "default" ]; then
      echo "Skipping default group $SG_ID"
      continue
    fi
    echo "Deleting $SG_ID"
    aws ec2 delete-security-group --group-id "$SG_ID" --region "$AWS_REGION" || echo "Initial delete failed for $SG_ID (in use)."
  done

  # Wait until none remain (poll)
  ATTEMPTS=0
  while [ $ATTEMPTS -lt 20 ]; do
    REMAINING=$(aws ec2 describe-security-groups \
      --filters "Name=group-name,Values=emb0x-security-group" \
      --query "SecurityGroups[].GroupId" \
      --output text \
      --region "$AWS_REGION")
    if [ -z "$REMAINING" ]; then
      echo "All emb0x-security-group security groups deleted."
      break
    fi
    echo "Still present (attempt $ATTEMPTS): $REMAINING"
    sleep 3
    ATTEMPTS=$((ATTEMPTS+1))
    # Retry delete on remaining
    for SG_ID in $REMAINING; do
      [ -z "$SG_ID" ] && continue
      aws ec2 delete-security-group --group-id "$SG_ID" --region "$AWS_REGION" >/dev/null 2>&1
    done
  done
  [ -n "$REMAINING" ] && echo "Timeout waiting for full deletion. Remaining: $REMAINING"
fi

# Subnet teardown - this must happen prior to VPC teardown
SUBNET_IDS=$(aws ec2 describe-subnets \
  --filters "Name=tag:Name,Values=emb0x-subnet" \
  --query "Subnets[].SubnetId" \
  --output text \
  --region "$AWS_REGION")

if [ -n "$SUBNET_IDS" ]; then
  for SUBNET_ID in $SUBNET_IDS; do
    echo "Deleting subnet: $SUBNET_ID"
    aws ec2 delete-subnet --subnet-id "$SUBNET_ID" --region "$AWS_REGION" 2>/dev/null || echo "Could not delete subnet $SUBNET_ID."
  done
else
  echo "No subnets named emb0x-subnet found."
fi

# Delete all VPCs tagged emb0x-vpc
VPC_IDS=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=emb0x-vpc" \
  --query "Vpcs[].VpcId" \
  --output text \
  --region "$AWS_REGION")

if [ -n "$VPC_IDS" ]; then
  for VPC_ID in $VPC_IDS; do
    echo "Deleting tagged VPC: $VPC_ID"
    aws ec2 delete-vpc --vpc-id "$VPC_ID" --region "$AWS_REGION" 2>/dev/null || echo "Could not delete VPC $VPC_ID (dependencies present)."
  done
else
  echo "No tagged VPCs (emb0x-vpc) found."
fi
