#!/bin/bash
source ./secrets.env # just so you can run it on its own for testing

# Stops terminal being held up by AWS CLI pagers
: "${AWS_REGION:=$AWS_REGION}"
INSTANCE_NAME="emb0x-instance"
export AWS_PAGER=""

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