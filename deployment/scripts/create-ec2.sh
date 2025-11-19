#!/bin/bash
set -euo pipefail

: "${AWS_REGION:=eu-central-1}"
export AWS_PAGER=""

# Config (adjust if needed)
IMAGE_ID="ami-022814934cf926361" # Ubuntu LTS AMI
INSTANCE_TYPE="t3.micro"
KEY_NAME="emb0x-key"
INSTANCE_NAME="emb0x-instance"

# Required IDs from earlier scripts
SECURITY_GROUP_ID=$(cat data/security-group-id.txt)
SUBNET_ID=$(cat data/subnet-id.txt)

# Launch new instance
INSTANCE_ID=$(aws ec2 run-instances \
  --region "$AWS_REGION" \
  --image-id "$IMAGE_ID" \
  --count 1 \
  --instance-type "$INSTANCE_TYPE" \
  --key-name "$KEY_NAME" \
  --subnet-id "$SUBNET_ID" \
  --security-group-ids "$SECURITY_GROUP_ID" \
  --user-data file://instance-init.sh \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${INSTANCE_NAME}}]" \
  --query "Instances[0].InstanceId" \
  --output text)

echo "$INSTANCE_ID" > data/instance-id.txt
echo "Instance created: $INSTANCE_ID (waiting for running state...)"

# ...existing code...
aws ec2 wait instance-running --instance-ids "$INSTANCE_ID" --region "$AWS_REGION"

# Attach DB volume if present
if [ -s data/ebs-db-volume-id.txt ]; then
  DB_VOLUME_ID=$(tr -d '\r\n' < data/ebs-db-volume-id.txt)
  VOLUME_AZ=$(aws ec2 describe-volumes --volume-ids "$DB_VOLUME_ID" \
    --query 'Volumes[0].AvailabilityZone' --output text --region "$AWS_REGION")
  INSTANCE_AZ=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" \
    --query 'Reservations[0].Instances[0].Placement.AvailabilityZone' --output text --region "$AWS_REGION")
  if [ "$VOLUME_AZ" = "$INSTANCE_AZ" ]; then
    echo "Attaching volume $DB_VOLUME_ID to instance $INSTANCE_ID"
    # Prevent Git Bash from converting /dev/sdf
    export MSYS_NO_PATHCONV=1
    export MSYS2_ARG_CONV_EXCL="/dev/sdf:/dev/xvdf"
    aws ec2 attach-volume \
      --volume-id "$DB_VOLUME_ID" \
      --instance-id "$INSTANCE_ID" \
      --device /dev/sdf \
      --region "$AWS_REGION"
    aws ec2 wait volume-in-use --volume-ids "$DB_VOLUME_ID" --region "$AWS_REGION"
  else
    echo "Skip attach: volume AZ $VOLUME_AZ != instance AZ $INSTANCE_AZ"
  fi
fi

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
# Reuse existing Elastic IP from public-ip.txt (if present)
EXISTING_PUBLIC_IP=""
if [ -s data/public-ip.txt ]; then
  EXISTING_PUBLIC_IP=$(tr -d '\r\n' < data/public-ip.txt)
fi

if [ -n "$EXISTING_PUBLIC_IP" ]; then
  # Find its allocation ID
  EIP_ALLOC_ID=$(aws ec2 describe-addresses \
    --public-ips "$EXISTING_PUBLIC_IP" \
    --query 'Addresses[0].AllocationId' \
    --output text --region "$AWS_REGION" 2>/dev/null || echo "None")
fi

# If no allocation ID found, fall back to existing file or allocate new
if [ -z "${EIP_ALLOC_ID:-}" ] || [ "$EIP_ALLOC_ID" = "None" ]; then
  if [ -s data/eip-allocation-id.txt ]; then
    EIP_ALLOC_ID=$(tr -d '\r\n' < data/eip-allocation-id.txt)
  fi
fi

if [ -z "${EIP_ALLOC_ID:-}" ] || [ "$EIP_ALLOC_ID" = "None" ]; then
  EIP_ALLOC_ID=$(aws ec2 allocate-address --domain vpc \
    --query 'AllocationId' --output text --region "$AWS_REGION")
  echo "$EIP_ALLOC_ID" > data/eip-allocation-id.txt
fi

# Disassociate if currently attached
CURRENT_ASSOC=$(aws ec2 describe-addresses --allocation-ids "$EIP_ALLOC_ID" \
  --query 'Addresses[0].AssociationId' --output text --region "$AWS_REGION" 2>/dev/null || echo "None")
[ "$CURRENT_ASSOC" != "None" ] && aws ec2 disassociate-address --association-id "$CURRENT_ASSOC" --region "$AWS_REGION" || true

# Associate Elastic IP to new instance
aws ec2 associate-address --allocation-id "$EIP_ALLOC_ID" --instance-id "$INSTANCE_ID" --region "$AWS_REGION"

# Refresh public IP (same as before if reused)
PUBLIC_IP=$(aws ec2 describe-addresses --allocation-ids "$EIP_ALLOC_ID" \
  --query 'Addresses[0].PublicIp' --output text --region "$AWS_REGION")
echo "$PUBLIC_IP" > data/public-ip.txt
echo "Elastic IP (retained): $PUBLIC_IP"