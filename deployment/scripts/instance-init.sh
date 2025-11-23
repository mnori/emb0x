#!/bin/bash
# This file is used to install and configure the necessary compoents on 
# EC2 instance the first time it boots.

set -e

echo "Starting instance-init.sh..."

set -x 

apt-get update
apt-get install -y software-properties-common 
add-apt-repository -y universe
apt-get update

# Git clone repo
echo "Fetching codebase..."
cd /home/ubuntu
if [ ! -d emb0x ]; then
  git clone https://github.com/mnori/emb0x.git emb0x || echo "Clone failed"
else
  cd emb0x && git pull || echo "Pull failed"
fi
chown -R ubuntu:ubuntu /home/ubuntu/emb0x
echo "Codebase ready at /home/ubuntu/emb0x"

# Install Docker
echo "Installing Docker and Docker Compose..."
curl -fsSL https://get.docker.com | sh
mkdir -p /usr/lib/docker/cli-plugins
COMPOSE_VERSION=v2.24.6
curl -SL https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-$(uname -m) -o /usr/lib/docker/cli-plugins/docker-compose
chmod +x /usr/lib/docker/cli-plugins/docker-compose
docker compose version
echo "...Docker and Docker Compose installed."

# Wait for attached EBS device (if present)
echo "MySQL EBS volume setup..."
DEVICE=""
for i in $(seq 1 30); do
  echo "Checking for attached EBS device (attempt $i)..."
  for cand in /dev/xvdf /dev/sdf /dev/nvme1n1; do
    if [ -b "$cand" ]; then DEVICE="$cand"; break; fi
  done
  [ -n "$DEVICE" ] && break
  sleep 2
done
echo "Found device: $DEVICE"

if [ -n "$DEVICE" ]; then
  echo "Found attached EBS device: $DEVICE"
  if ! blkid "$DEVICE" >/dev/null 2>&1; then mkfs.ext4 -F "$DEVICE"; fi
  mkdir -p /data/mysql
  UUID=$(blkid -s UUID -o value "$DEVICE")
  grep -q "$UUID" /etc/fstab || echo "UUID=$UUID /data/mysql ext4 defaults,nofail 0 2" >> /etc/fstab
  mount -a
  chown 999:ubuntu /data/mysql
  chmod 770 /data/mysql
  sudo chown ubuntu:ubuntu /data/mysql
  sudo chmod 750 /data/mysql
  echo "EBS device $DEVICE mounted to /data/mysql"
fi
echo "...MySQL EBS volume setup complete."

# Needed for MySQL to start
echo "MYSQL_ROOT_PASSWORD=confidentcats4eva\n" >> /home/ubuntu/emb0x/.env

# Start stack (assumes compose.yml already on instance)
cd /home/ubuntu/emb0x
docker compose -f compose-production.yml up -d
echo "...Docker Compose stack started."

echo "Reached end of instance-init.sh deployment script."
