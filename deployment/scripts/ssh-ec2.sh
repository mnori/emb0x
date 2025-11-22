#!/bin/bash
# Doesn't work
source ./secrets.env
echo "SSHing into EC2 instance..."
PUBLIC_IP=$(cat data/public-ip.txt)
ssh-keygen -R $PUBLIC_IP
ssh-keyscan -H -t ed25519,rsa,ecdsa $PUBLIC_IP >> ~/.ssh/known_hosts
ssh -i data/emb0x-key.pem ubuntu@$PUBLIC_IP

# ssh -o StrictHostKeyChecking=accept-new -i data/emb0x-key.pem ubuntu@$(cat data/public-ip.txt)
# ./replace-key.sh
