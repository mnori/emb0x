#!/bin/bash
source ./secrets.env
echo "Creating persistent resources..."
./create-vpc.sh
./create-subnet.sh
./create-database-ebs-volume.sh
echo "...Persistent resource creation complete."
