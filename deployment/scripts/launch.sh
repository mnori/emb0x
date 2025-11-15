#!/bin/bash

source ./secrets.env

./teardown.sh

# Create EC2 instance on LocalStack
./create-vpc-subnet.sh
./create-security-groups.sh
./create-ec2.sh

