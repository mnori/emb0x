FROM ubuntu:22.04

# We are root at the moment. Create a non-root user
RUN useradd -ms /bin/bash deployer
RUN echo "force_color_prompt=yes" >> /home/deployer/.bashrc

# Set environment variables to avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/usr/bin:${PATH}"

# Update the package list and install dependencies
RUN apt-get update && apt-get install -y coreutils curl unzip

# Verify the tail command as root
RUN /usr/bin/tail --version

# Fix permissions for tail (if needed)
RUN chmod 777 /usr/bin/tail 

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws

# Verify AWS CLI installation
RUN aws --version

# Switch to the non-root user
USER deployer

# Verify the tail command as deployer
RUN /usr/bin/tail --version

# Set the working directory
WORKDIR /app/deployer

# Keep the container running
ENTRYPOINT ["tail", "-f", "/dev/null"]