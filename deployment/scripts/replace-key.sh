#!/bin/bash
source ./secrets.env
set -euo pipefail
KEY_NAME="emb0x-key"
DATA_DIR="data"

# Delete existing key locally if present
rm -f "$DATA_DIR/${KEY_NAME}.pem"

# If key exists, delete to allow fresh PEM
if aws ec2 describe-key-pairs --key-names "$KEY_NAME" --region "$AWS_REGION" >/dev/null 2>&1; then
  echo "Deleting existing AWS key pair $KEY_NAME to issue a fresh PEM..."
  aws ec2 delete-key-pair --key-name "$KEY_NAME" --region "$AWS_REGION"
  echo "Deleted existing key pair $KEY_NAME"
fi

# Create new one and place PEM file in data/
echo "Creating new AWS key pair $KEY_NAME..."
aws ec2 create-key-pair \
  --key-name "$KEY_NAME" \
  --query 'KeyMaterial' \
  --output text \
  --region "$AWS_REGION" > "$DATA_DIR/${KEY_NAME}.pem"
chmod 400 "$DATA_DIR/${KEY_NAME}.pem"
echo "Saved PEM: $DATA_DIR/${KEY_NAME}.pem"

echo "Adding new key to known hosts..."
./add-known-host.sh
echo "...Key replacement complete."
