#!/bin/bash
set -euo pipefail

KEY="data/emb0x-key.pem"
IP=$(tr -d '\r\n' < data/public-ip.txt)

[ -f "$KEY" ] || { echo "Missing $KEY"; exit 1; }
[ -n "$IP" ] || { echo "Missing public IP"; exit 1; }

echo "Streaming /var/log/cloud-init-output.log (Ctrl-C to stop)..."
ssh-keygen -R "$IP" 2>/dev/null || true
ssh-keyscan -H -t ed25519,rsa,ecdsa "$IP" 2>/dev/null >> ~/.ssh/known_hosts || true

# Tail in real time; -t allocates TTY so tail updates continuously
ssh -t -o StrictHostKeyChecking=accept-new -i "$KEY" ubuntu@"$IP" 'sudo tail -n 50 -f /var/log/cloud-init-output.log'