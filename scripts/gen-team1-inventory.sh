#!/usr/bin/env bash
# Generate infrastructure/ansible/inventories/team1.ini from Terraform outputs.
# LOW-RISK: reads `terraform output -json` and writes a LOCAL, gitignored file.
# It does NOT connect to hosts and does NOT handle secrets (SSH key path is yours).
#
# Usage:
#   SSH_KEY=~/.ssh/elx-team1.pem ./scripts/gen-team1-inventory.sh
#
set -euo pipefail

TF_DIR="infrastructure/terraform/envs/team1"
OUT="infrastructure/ansible/inventories/team1.ini"
SSH_KEY="${SSH_KEY:-~/.ssh/elx-team1.pem}"

command -v jq >/dev/null || { echo "jq is required"; exit 1; }

J="$(terraform -chdir="$TF_DIR" output -json)"
gw_pub=$(echo "$J"  | jq -r '.gateway_public_ip.value')
dmz_ip=$(echo "$J"  | jq -r '.dmz_app_private_ip.value')
int_ip=$(echo "$J"  | jq -r '.intapp_private_ip.value')

[ "$gw_pub" = "null" ] && { echo "gateway_public_ip not found; apply Terraform first"; exit 1; }

cat > "$OUT" <<INV
[gateway]
team1-gateway ansible_host=${gw_pub} ansible_user=ubuntu ansible_ssh_private_key_file=${SSH_KEY}

[dmz]
team1-dmz-app ansible_host=${dmz_ip} ansible_user=ubuntu ansible_ssh_private_key_file=${SSH_KEY} ansible_ssh_common_args='-o ProxyJump=ubuntu@${gw_pub}'

[internal]
team1-int-app ansible_host=${int_ip} ansible_user=ubuntu ansible_ssh_private_key_file=${SSH_KEY} ansible_ssh_common_args='-o ProxyJump=ubuntu@${gw_pub}'

[team1:children]
gateway
dmz
internal
INV

echo "Wrote $OUT (gitignored). Review it before use."
