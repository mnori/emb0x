#!/bin/sh

# Start the MinIO server in the background
minio server /data --console-address ":9001" &

# Wait for MinIO to start
echo "Waiting for MinIO to start..."
until curl -s http://localhost:9000/minio/health/live > /dev/null; do
    sleep 2
done
echo "MinIO is up and running."

# Configure the MinIO client
mc alias set local http://localhost:9000 admin confidentcats4eva

# Create the bucket if it doesn't exist
mc mb local/audio-files || echo "Bucket already exists"

# Set the bucket policy to public read
mc anonymous set public local/audio-files

# Keep the container running
wait