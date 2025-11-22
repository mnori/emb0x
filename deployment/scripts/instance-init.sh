#!/bin/bash
set -e

echo "Starting instance-init.sh..."

set -x 

apt-get update
apt-get install -y software-properties-common
add-apt-repository -y universe
apt-get update
apt-get install -y docker.io docker-compose-plugin
docker compose version

# apt-get update
# apt-get install -y docker.io docker-compose-plugin
# systemctl enable --now docker

# Wait for attached EBS device (if present)
DEVICE=""
for i in $(seq 1 30); do
  echo "Checking for attached EBS device (attempt $i)..."
  for cand in /dev/xvdf /dev/sdf /dev/nvme1n1; do
    if [ -b "$cand" ]; then DEVICE="$cand"; break; fi
  done
  [ -n "$DEVICE" ] && break
  sleep 2
done

if [ -n "$DEVICE" ]; then
  echo "Found attached EBS device: $DEVICE"
  if ! blkid "$DEVICE" >/dev/null 2>&1; then mkfs.ext4 -F "$DEVICE"; fi
  mkdir -p /data/mysql
  UUID=$(blkid -s UUID -o value "$DEVICE")
  grep -q "$UUID" /etc/fstab || echo "UUID=$UUID /data/mysql ext4 defaults,nofail 0 2" >> /etc/fstab
  mount -a
  chown 999:999 /data/mysql
  chmod 700 /data/mysql
  echo "EBS device $DEVICE mounted to /data/mysql"
fi

# Start stack (assumes compose.yml already on instance)
docker compose -f compose-production.yml up -d
# docker compose up -d || true

echo "instance-init.sh completed."

# #!/bin/bash
# # This script is used to initialise the "deployment" container
# sudo apt update
# sudo apt install -y docker.io
# sudo systemctl enable docker
# sudo systemctl start docker
# sudo curl -L "https://github.com/docker/compose/releases/download/2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
# sudo chmod +x /usr/local/bin/docker-compose
# docker --version
# docker-compose --version
