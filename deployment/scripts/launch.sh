#!/bin/bash

./teardown.sh

# Start LocalStack
./start-localstack.sh

# Wait until LocalStack responds to HTTP requests
until curl -sf http://localhost:4566 > /dev/null; do
    echo "Waiting for LocalStack to respond..."
    sleep 1
done

# Create EC2 instance on LocalStack
./create-security-groups.sh

