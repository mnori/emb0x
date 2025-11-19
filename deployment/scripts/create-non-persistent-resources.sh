#!/bin/bash
source ./secrets.env

echo "Creating resources..."
# Create the new versions of the stuff
# ./create-vpc.sh
# ./create-subnet.sh
./create-security-groups.sh
./create-ec2.sh
echo "...Resource creation complete."
