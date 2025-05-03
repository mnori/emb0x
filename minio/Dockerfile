FROM quay.io/minio/minio

# Install the MinIO client (mc)
RUN curl -O https://dl.min.io/client/mc/release/linux-amd64/mc && \
    chmod +x mc && \
    mv mc /usr/local/bin/

# Set environment variables for MinIO credentials
ENV MINIO_ROOT_USER=admin
ENV MINIO_ROOT_PASSWORD=confidentcats4eva

# Copy the startup script into the container
COPY minio/configure-minio.sh /usr/local/bin/configure-minio.sh
RUN chmod +x /usr/local/bin/configure-minio.sh

# Start MinIO and run the configuration script
ENTRYPOINT ["/usr/local/bin/configure-minio.sh"]
