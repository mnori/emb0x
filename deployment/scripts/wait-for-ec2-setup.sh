#!/bin/bash
source ./secrets.env

# Wait for container to finish setup

PUBLIC_IP=$(cat data/public-ip.txt)
ssh-keygen -R $PUBLIC_IP
ssh-keyscan -H -t ed25519,rsa,ecdsa $PUBLIC_IP >> ~/.ssh/known_hosts

KEY_FILE="data/emb0x-key.pem"
START=$(date +%s)
MAX_WAIT=900
SLEEP=5

echo "Waiting for EC2 initialising script..."
while true; do
  ELAPSED=$(( $(date +%s) - START ))
  if [ $ELAPSED -ge $MAX_WAIT ]; then
    echo "Timeout waiting for cloud-init completion."
    exit 1
  fi

  CLOUD_STATUS=$(ssh -o BatchMode=yes -o ConnectTimeout=5 -i "$KEY_FILE" ubuntu@"$PUBLIC_IP" 'cloud-init status 2>/dev/null || true' 2>/dev/null || true)
  BOOT_DONE=$(ssh -o BatchMode=yes -o ConnectTimeout=5 -i "$KEY_FILE" ubuntu@"$PUBLIC_IP" 'test -f /var/lib/cloud/instance/boot-finished && echo yes || echo no' 2>/dev/null || true)
  INIT_MARK=$(ssh -o BatchMode=yes -o ConnectTimeout=5 -i "$KEY_FILE" ubuntu@"$PUBLIC_IP" 'test -f /var/log/emb0x-init-status.txt && echo yes || echo no' 2>/dev/null || true)

  if echo "$CLOUD_STATUS" | grep -q 'done'; then
    echo "cloud-init status: done"
    break
  fi
  if [ "$BOOT_DONE" = "yes" ]; then
    echo "boot-finished marker present"
    break
  fi
  if [ "$INIT_MARK" = "yes" ]; then
    echo "Custom INIT_OK marker found"
    break
  fi
  if echo "$CLOUD_STATUS" | grep -qi 'error'; then
    echo "cloud-init reported error:"
    ssh -i "$KEY_FILE" ubuntu@"$PUBLIC_IP" 'sudo tail -n 100 /var/log/cloud-init-output.log' || true
    exit 1
  fi

  sleep "$SLEEP"
done

echo "...Finished waiting for EC2 container intialiser script."

# Doing this means we can look at the logs easily in the IDE after the thing boots.
scp -i "$KEY_FILE" ubuntu@"$PUBLIC_IP":/var/log/cloud-init-output.log data/cloud-init-output.log || true
echo "Copied EC2 init log to data/cloud-init-output.log"
