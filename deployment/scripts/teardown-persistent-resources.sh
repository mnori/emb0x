#!/bin/bash
# For testing. Deletes volume, deletes the VPC and Subnet as well. 
# Destroys your data!
source ./secrets.env

./teardown-subnet.sh
./teardown-vpc.sh

# Now get rid of the EBS volume(s)
set -euo pipefail
source ./secrets.env
: "${AWS_REGION:=eu-central-1}"
export AWS_PAGER=""

TAG_NAME="emb0x-mysql"

echo "Finding volumes tagged Name=${TAG_NAME}..."
VOLUME_IDS=$(aws ec2 describe-volumes \
  --filters "Name=tag:Name,Values=${TAG_NAME}" \
  --query "Volumes[].VolumeId" \
  --output text \
  --region "$AWS_REGION" || true)

[ -z "$VOLUME_IDS" ] && echo "None found." && exit 0
echo "Volumes: $VOLUME_IDS"

for VOL in $VOLUME_IDS; do
  [ -z "$VOL" ] && continue
  STATE=$(aws ec2 describe-volumes --volume-ids "$VOL" \
    --query "Volumes[0].State" --output text --region "$AWS_REGION" 2>/dev/null || echo "missing")
  echo "Processing $VOL (state=$STATE)"

  if [ "$STATE" = "in-use" ]; then
    ATT_INST=$(aws ec2 describe-volumes --volume-ids "$VOL" \
      --query "Volumes[0].Attachments[0].InstanceId" --output text --region "$AWS_REGION" 2>/dev/null || echo "None")
    echo "Detaching from instance $ATT_INST"
    aws ec2 detach-volume --volume-id "$VOL" --region "$AWS_REGION" || true

    # Wait until available or gone
    for i in $(seq 1 30); do
      STATE=$(aws ec2 describe-volumes --volume-ids "$VOL" \
        --query "Volumes[0].State" --output text --region "$AWS_REGION" 2>/dev/null || echo "missing")
      [ "$STATE" = "available" ] && break
      [ "$STATE" = "missing" ] && break
      sleep 4
    done
  fi

  STATE=$(aws ec2 describe-volumes --volume-ids "$VOL" \
    --query "Volumes[0].State" --output text --region "$AWS_REGION" 2>/dev/null || echo "missing")

  if [ "$STATE" = "available" ]; then
    if aws ec2 delete-volume --volume-id "$VOL" --region "$AWS_REGION"; then
      echo "Deleted $VOL"
    else
      echo "Delete failed $VOL"
    fi
  else
    echo "Skip $VOL (state=$STATE)"
  fi
done

# Clean local tracking files
rm -f data/ebs-db-volume-id.txt 2>/dev/null || true
rm -f data/mysql-volume-id.txt 2>/dev/null || true

echo "EBS volume teardown complete."