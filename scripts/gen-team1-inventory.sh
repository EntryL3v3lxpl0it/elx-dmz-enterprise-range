#!/usr/bin/env bash
set -euo pipefail

SSH_KEY="${SSH_KEY:-$HOME/.ssh/aws}"
TF_DIR="infrastructure/terraform/envs/cohorts/team1"
INV_DIR="infrastructure/ansible/inventories"
INV_FILE="${INV_DIR}/team1.ini"

mkdir -p "$INV_DIR"

terraform -chdir="$TF_DIR" init -reconfigure -backend-config=backend.hcl >/dev/null

DMZ_PUBLIC_IP="$(terraform -chdir="$TF_DIR" output -raw dmz_web_public_ip)"
DMZ_PRIVATE_IP="$(terraform -chdir="$TF_DIR" output -raw dmz_web_private_ip)"

cat > "$INV_FILE" <<EOT
[team1:children]
dmz

[dmz]
team1-dmz-web ansible_host=${DMZ_PUBLIC_IP} ansible_user=ubuntu ansible_ssh_private_key_file=${SSH_KEY}

[team1:vars]
ansible_python_interpreter=/usr/bin/python3
EOT

echo "[+] Wrote ${INV_FILE}"
echo "[+] DMZ public IP:  ${DMZ_PUBLIC_IP}"
echo "[+] DMZ private IP: ${DMZ_PRIVATE_IP}"
