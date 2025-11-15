#!/bin/bash
cd ..
docker compose down --remove-orphans
docker compose run deployment