#!/bin/bash
source ./secrets.env
echo "Creating non persistent resources..."
./create-security-groups.sh
./create-ec2.sh
echo "...Non persistent resource creation complete."
