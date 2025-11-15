#!/bin/bash

source ./secrets.env

./teardown.sh

# Create EC2 instance on LocalStack
./create-security-groups.sh
./create-vpc-subnet.sh
# ./create-ec2.sh

