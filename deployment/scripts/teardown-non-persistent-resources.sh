#!/bin/bash
source ./secrets.env

# Teardown any existing resources because otherwise Bezos will ask for a pound of flesh
# But not the EBS cos that persists the data
echo "Tearing down non persistent resources..."
./teardown-ec2.sh
./teardown-eni.sh
./teardown-security-groups.sh
echo "...Non persistent resource teardown complete."
