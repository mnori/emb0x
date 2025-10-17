#!/bin/bash
docker run -d --name localstack -p 4566:4566 -p 4571:4571 localstack/localstack