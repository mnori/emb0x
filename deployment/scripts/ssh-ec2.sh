#!/bin/bash
# Doesn't work
source ./secrets.env
echo "SSHing into EC2 instance..."
ssh -i data/emb0x-key.pem ubuntu@$(cat data/public-ip.txt)
