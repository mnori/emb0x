#!/bin/bash
source ./secrets.env
VOL_FILE="data/ebs-db-volume-id.txt"

# Ensure VPC / Subnet exist (for AZ lookup)
./create-vpc.sh
./create-subnet.sh

SUBNET_ID=$(tr -d '\r\n' < data/subnet-id.txt)

# Current subnet AZ
SUBNET_AZ=$(aws ec2 describe-subnets \
  --subnet-ids "$SUBNET_ID" \
  --query 'Subnets[0].AvailabilityZone' \
  --output text \
  --region "$AWS_REGION")

if [ -s "$VOL_FILE" ]; then
  EXISTING_VOL_ID=$(tr -d '\r\n' < "$VOL_FILE")
  # Describe existing volume
  VOL_STATE=$(aws ec2 describe-volumes \
    --volume-ids "$EXISTING_VOL_ID" \
    --query 'Volumes[0].State' \
    --output text --region "$AWS_REGION" 2>/dev/null || echo "missing")
  if [ "$VOL_STATE" = "missing" ]; then
    echo "Stored volume ID not found; creating new volume."
  else
    VOL_AZ=$(aws ec2 describe-volumes \
      --volume-ids "$EXISTING_VOL_ID" \
      --query 'Volumes[0].AvailabilityZone' \
      --output text --region "$AWS_REGION")
    if [ "$VOL_AZ" = "$SUBNET_AZ" ]; then
      echo "Volume already exists: $EXISTING_VOL_ID in AZ $VOL_AZ"
      # Write AZ summary
      echo "VOLUME_ID=$EXISTING_VOL_ID" > data/ebs-db-volume-summary.txt
      echo "AVAILABILITY_ZONE=$VOL_AZ" >> data/ebs-db-volume-summary.txt
      exit 0
    else
      echo "Volume AZ mismatch (volume: $VOL_AZ, subnet: $SUBNET_AZ). Cloning to correct AZ..."
      SNAP_ID=$(aws ec2 create-snapshot \
        --volume-id "$EXISTING_VOL_ID" \
        --tag-specifications 'ResourceType=snapshot,Tags=[{Key=Name,Value=emb0x-mysql-copy}]' \
        --query 'SnapshotId' --output text --region "$AWS_REGION")
      echo "Snapshot: $SNAP_ID (waiting completed state)"
      aws ec2 wait snapshot-completed --snapshot-ids "$SNAP_ID" --region "$AWS_REGION"
      NEW_VOL_ID=$(aws ec2 create-volume \
        --snapshot-id "$SNAP_ID" \
        --availability-zone "$SUBNET_AZ" \
        --volume-type gp3 \
        --tag-specifications 'ResourceType=volume,Tags=[{Key=Name,Value=emb0x-mysql}]' \
        --query 'VolumeId' --output text --region "$AWS_REGION")
      echo "Created new volume in correct AZ: $NEW_VOL_ID"
      echo "$NEW_VOL_ID" > "$VOL_FILE"
      echo "VOLUME_ID=$NEW_VOL_ID" > data/ebs-db-volume-summary.txt
      echo "AVAILABILITY_ZONE=$SUBNET_AZ" >> data/ebs-db-volume-summary.txt
      exit 0
    fi
  fi
fi

# Create fresh volume (first time or missing old)
NEW_VOL_ID=$(aws ec2 create-volume \
  --availability-zone "$SUBNET_AZ" \
  --size 20 \
  --volume-type gp3 \
  --tag-specifications 'ResourceType=volume,Tags=[{Key=Name,Value=emb0x-mysql}]' \
  --query 'VolumeId' --output text --region "$AWS_REGION")

echo "Created volume: $NEW_VOL_ID (AZ=$SUBNET_AZ)"
echo "$NEW_VOL_ID" > "$VOL_FILE"
echo "VOLUME_ID=$NEW_VOL_ID" > data/ebs-db-volume-summary.txt
echo "AVAILABILITY_ZONE=$SUBNET_AZ" >> data/ebs-db-volume-summary.txt
