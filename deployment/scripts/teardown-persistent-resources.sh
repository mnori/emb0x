#!/bin/bash
# For testing. Deletes volume, deletes the VPC and Subnet as well. 
# Destroys your data!
source ./secrets.env
echo "Tearing down persistent resources..."
./teardown-subnet.sh
./teardown-vpc.sh
./teardown-database-ebs-volumes.sh
echo "...Persistent resource teardown complete."
