#!/bin/bash
set -euo pipefail

: "${AWS_REGION:=eu-central-1}"
export AWS_PAGER=""

mkdir -p data

# Config (adjust if needed)
IMAGE_ID="ami-022814934cf926361"
INSTANCE_TYPE="t3.micro"
KEY_NAME="emb0x-key"
INSTANCE_NAME="emb0x-instance"

# Required IDs from earlier scripts
SECURITY_GROUP_ID=$(cat data/security-group-id.txt)
SUBNET_ID=$(cat data/subnet-id.txt)

# Optional: terminate any existing instance with same Name tag (non-blocking)
# Cleanly collect existing, non-terminated instance IDs
# Collect non-terminated, tagged instances
RAW_IDS=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=${INSTANCE_NAME}" \
            "Name=instance-state-name,Values=running,pending,stopping,stopped" \
  --query "Reservations[].Instances[].InstanceId" \
  --output text \
  --region "$AWS_REGION" || true)

# Normalize (strip CRLF, remove duplicates)
EXISTING_IDS=""
for ID in $RAW_IDS; do
  CLEAN_ID=$(echo "$ID" | tr -d '\r')
  [[ -n "$CLEAN_ID" ]] && EXISTING_IDS+=" $CLEAN_ID"
done
EXISTING_IDS=$(echo "$EXISTING_IDS" | xargs -n1 | sort -u | xargs)

if [ -n "$EXISTING_IDS" ]; then
  echo "Found candidate instances: $EXISTING_IDS"
  VALID_IDS=()
  for ID in $EXISTING_IDS; do
    STATE=$(aws ec2 describe-instances --instance-ids "$ID" \
      --query "Reservations[0].Instances[0].State.Name" \
      --output text --region "$AWS_REGION" 2>/dev/null || echo "missing")
    if [[ "$STATE" == "running" || "$STATE" == "stopped" || "$STATE" == "pending" || "$STATE" == "stopping" ]]; then
      VALID_IDS+=("$ID")
      echo "Keep $ID (state=$STATE)"
    else
      echo "Skip $ID (state=$STATE)"
    fi
  done

  if [ ${#VALID_IDS[@]} -gt 0 ]; then
    echo "Terminating: ${VALID_IDS[*]}"
    aws ec2 terminate-instances --instance-ids "${VALID_IDS[@]}" --region "$AWS_REGION"
    aws ec2 wait instance-terminated --instance-ids "${VALID_IDS[@]}" --region "$AWS_REGION"
  else
    echo "No valid instances to terminate."
  fi
else
  echo "No existing instances to terminate."
fi

# Launch new instance
INSTANCE_ID=$(aws ec2 run-instances \
  --region "$AWS_REGION" \
  --image-id "$IMAGE_ID" \
  --count 1 \
  --instance-type "$INSTANCE_TYPE" \
  --key-name "$KEY_NAME" \
  --subnet-id "$SUBNET_ID" \
  --security-group-ids "$SECURITY_GROUP_ID" \
  --user-data file://ec2-init.sh \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${INSTANCE_NAME}}]" \
  --query "Instances[0].InstanceId" \
  --output text)

echo "$INSTANCE_ID" > data/instance-id.txt
echo "Instance created: $INSTANCE_ID (waiting for running state...)"

# ...existing code...
aws ec2 wait instance-running --instance-ids "$INSTANCE_ID" --region "$AWS_REGION"

# Ensure VPC has IGW + default route
VPC_ID=$(aws ec2 describe-subnets --subnet-ids "$SUBNET_ID" \
  --query 'Subnets[0].VpcId' --output text --region "$AWS_REGION")

IGW_ID=$(aws ec2 describe-internet-gateways \
  --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
  --query 'InternetGateways[0].InternetGatewayId' \
  --output text --region "$AWS_REGION")

if [ -z "$IGW_ID" ] || [ "$IGW_ID" = "None" ]; then
  IGW_ID=$(aws ec2 create-internet-gateway \
    --query 'InternetGateway.InternetGatewayId' --output text --region "$AWS_REGION")
  aws ec2 attach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID" --region "$AWS_REGION"
fi

ROUTE_TABLE_ID=$(aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'RouteTables[0].RouteTableId' \
  --output text --region "$AWS_REGION")
if [ -z "$ROUTE_TABLE_ID" ] || [ "$ROUTE_TABLE_ID" = "None" ]; then
  ROUTE_TABLE_ID=$(aws ec2 create-route-table --vpc-id "$VPC_ID" \
    --query 'RouteTable.RouteTableId' --output text --region "$AWS_REGION")
fi

aws ec2 create-route \
  --route-table-id "$ROUTE_TABLE_ID" \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id "$IGW_ID" \
  --region "$AWS_REGION" >/dev/null 2>&1 || true

aws ec2 associate-route-table \
  --route-table-id "$ROUTE_TABLE_ID" \
  --subnet-id "$SUBNET_ID" \
  --region "$AWS_REGION" >/dev/null 2>&1 || true

# Allocate or reuse Elastic IP
if [ -s data/eip-allocation-id.txt ]; then
  EIP_ALLOC_ID=$(cat data/eip-allocation-id.txt)
else
  EIP_ALLOC_ID=$(aws ec2 allocate-address --domain vpc --query 'AllocationId' --output text --region "$AWS_REGION")
  echo "$EIP_ALLOC_ID" > data/eip-allocation-id.txt
fi

# Disassociate existing
CURRENT_ASSOC=$(aws ec2 describe-addresses --allocation-ids "$EIP_ALLOC_ID" \
  --query 'Addresses[0].AssociationId' --output text --region "$AWS_REGION" || echo "None")
if [ "$CURRENT_ASSOC" != "None" ] && [ -n "$CURRENT_ASSOC" ]; then
  aws ec2 disassociate-address --association-id "$CURRENT_ASSOC" --region "$AWS_REGION"
fi

# Associate Elastic IP
aws ec2 associate-address --allocation-id "$EIP_ALLOC_ID" --instance-id "$INSTANCE_ID" --region "$AWS_REGION"

# Get stable public IP
PUBLIC_IP=$(aws ec2 describe-addresses \
  --allocation-ids "$EIP_ALLOC_ID" \
  --query 'Addresses[0].PublicIp' --output text --region "$AWS_REGION")
echo "$PUBLIC_IP" > data/public-ip.txt

echo "Elastic IP: $PUBLIC_IP"
echo "Saved: instance-id.txt eip-allocation-id.txt public-ip.txt"