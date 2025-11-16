#!/bin/bash

echo "Getting the party started..."
source ./secrets.env

# Teardown any existing resources because otherwise Bezos will ask for a pound of flesh
./teardown-ec2.sh
./teardown-eni.sh
./teardown-security-groups.sh
./teardown-subnet.sh
./teardown-vpc.sh

# Create the new versions of the stuff
./create-vpc.sh
./create-subnet.sh
./create-security-groups.sh
./create-ec2.sh

echo "Deployment process reached end."