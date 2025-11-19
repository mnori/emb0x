#!/bin/bash
# For testing. Deletes volume, deletes the VPC and Subnet as well. 
# Destroys your data!
source ./secrets.env
./teardown-subnet.sh
./teardown-vpc.sh
./teardown-database-ebs-volumes.sh
