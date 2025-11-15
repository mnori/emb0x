#!/bin/bash

echo "Getting the party started..."
source ./secrets.env
./teardown.sh
./create-vpc-subnet.sh
./create-security-groups.sh
./create-ec2.sh
echo "Deployment complete."