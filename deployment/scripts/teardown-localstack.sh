#!/bin/bash

echo "Tearing down LocalStack environment..."

# Remove all LocalStack containers only if any exist
CONTAINERS=$(docker ps -aq --filter "ancestor=localstack/localstack")
if [ -n "$CONTAINERS" ]; then
    docker rm -f $CONTAINERS
fi

# Remove LocalStack volumes only if any exist
VOLUMES=$(docker volume ls -q --filter "name=localstack")
if [ -n "$VOLUMES" ]; then
    docker volume rm $VOLUMES
fi

echo "...Done"