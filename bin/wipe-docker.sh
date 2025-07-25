#!/bin/bash
# This script will remove all Docker containers, images, volumes, and networks.
# A fresh start! Docker getting a detox.
docker rm -f $(docker ps -aq) 2>/dev/null
docker rmi -f $(docker images -aq) 2>/dev/null
docker volume rm $(docker volume ls -q) 2>/dev/null
docker network rm $(docker network ls -q) 2>/dev/null
docker system prune -af --volumes 2>/dev/null
