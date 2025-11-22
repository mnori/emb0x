set -euo pipefail
PUBLIC_IP=$(tr -d '\r\n' < data/public-ip.txt)
id deployer >/dev/null 2>&1 || { echo "No deployer user"; exit 0; }
DEPLOYER_HOME=$(eval echo ~deployer)
mkdir -p "$DEPLOYER_HOME/.ssh"
KNOWN="$DEPLOYER_HOME/.ssh/known_hosts"
grep -v "^$PUBLIC_IP[[:space:]]" "$KNOWN" 2>/dev/null > "${KNOWN}.tmp" || true
mv "${KNOWN}.tmp" "$KNOWN" 2>/dev/null || true
ssh-keyscan -H -T 5 -t rsa,ecdsa,ed25519 "$PUBLIC_IP" 2>/dev/null >> "$KNOWN" || true
chown deployer:deployer "$KNOWN"
chmod 600 "$KNOWN"
echo "Known host updated for $PUBLIC_IP"
