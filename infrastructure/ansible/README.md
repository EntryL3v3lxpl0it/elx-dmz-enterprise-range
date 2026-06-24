# Ansible — Phase 1b baseline (team1)

Configures the three Phase 1 hosts created by Terraform so the range is operational,
repeatable, and ready for later service deployment. **No vulnerable apps, AD, users,
scoring, or monitoring are configured here.**

## How Ansible fits the architecture
Terraform builds the network + hosts (no public attack surface, no NAT Gateway). Ansible
then configures them over SSH. The **gateway** (public-edge) is the only SSH entry point;
the **dmz** and **internal** hosts are private and reached via `ProxyJump` through the
gateway. Package installs on private hosts use the gateway package proxy **only** when
provisioning egress is temporarily enabled.

## Hosts & roles
| Group | Host | Roles | Notes |
|-------|------|-------|-------|
| gateway | team1-gateway | common, gateway, package-proxy | infrastructure only; IP forwarding off by default |
| dmz | team1-dmz-app | common, docker, dmz-host | Docker installed; no apps yet |
| internal | team1-int-app | common, docker, internal-host | Docker installed; no apps yet |

## 1. Create inventory from Terraform outputs
Option A (helper script, low-risk):
```bash
cd <repo-root>
SSH_KEY=~/.ssh/elx-team1.pem ./scripts/gen-team1-inventory.sh
```
Option B (manual): copy `inventories/team1.ini.example` to `inventories/team1.ini` and fill in
`gateway_public_ip`, `dmz_app_private_ip`, `intapp_private_ip` from:
```bash
terraform -chdir=infrastructure/terraform/envs/team1 output
```
`inventories/team1.ini` is gitignored (real IPs never committed).

## 2. Test SSH
Gateway (direct):
```bash
ssh -i ~/.ssh/elx-team1.pem ubuntu@<gateway_public_ip>
```
Private hosts (through the gateway):
```bash
ssh -i ~/.ssh/elx-team1.pem -o ProxyJump=ubuntu@<gateway_public_ip> ubuntu@<dmz_private_ip>
ssh -i ~/.ssh/elx-team1.pem -o ProxyJump=ubuntu@<gateway_public_ip> ubuntu@<internal_private_ip>
```

## 3. Run (working dir: infrastructure/ansible)
```bash
cd infrastructure/ansible
ansible --version
ansible-inventory -i inventories/team1.ini --graph
ansible all -i inventories/team1.ini -m ping
ansible-playbook -i inventories/team1.ini playbooks/site.yml --syntax-check
ansible-playbook -i inventories/team1.ini playbooks/site.yml
ansible-playbook -i inventories/team1.ini playbooks/site.yml --check   # idempotency dry-run
```

## 4. Provisioning egress (temporary, explicit)
Private hosts have no internet route. To install OS packages on dmz/internal:
1. Terraform: set `enable_provisioning_egress = true`, `terraform apply`.
2. Ansible: set `enable_provisioning_egress: true` and `gateway_private_ip: <10.50.10.x>`
   (e.g., `-e enable_provisioning_egress=true -e gateway_private_ip=<ip>`), run the playbook.
   This starts apt-cacher-ng on the gateway and points private hosts' apt at it.
3. **When done:** set both back to false, re-apply Terraform and re-run the playbook. The
   proxy is stopped/disabled and the apt proxy file is removed.

`gateway_acts_as_nat` (Terraform) / break-glass NAT (Ansible) are **break-glass only** and do
not create a working NAT path by themselves.

## Idempotency
Re-running any playbook should report `changed=0` after the first successful run. All tasks use
declarative `state:` and cached apt. Confirm with a second run or `--check`.

## Safety
No secrets in this tree. Private keys, real inventories, tfvars, and generated credentials are
gitignored. No vulnerable services are deployed in Phase 1b.
