#!/bin/bash
source ./secrets.env

# Ensure VPC / Subnet exist (for AZ lookup)
./create-vpc.sh
./create-subnet.sh
./create-database-ebs-volume.sh
