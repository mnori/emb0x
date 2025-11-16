#!/bin/bash

echo "Getting the party started..."
source ./secrets.env
./teardown-ec2.sh
./teardown-eni.sh
./teardown-security-groups.sh
./teardown-subnet.sh
./teardown-vpc.sh

# ./teardown.sh

./create-vpc.sh
./create-subnet.sh
./create-security-groups.sh
./create-ec2.sh
echo "Deployment process reached end."