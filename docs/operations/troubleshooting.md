# Operations Troubleshooting

Covers Ansible/SSH/package-proxy issues for the Phase 1b baseline.

## SSH failures
| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `Permission denied (publickey)` to gateway | Wrong key or user | Use the key from Terraform `aws_key_pair`; user is `ubuntu` |
| Gateway times out | Source IP not allowlisted | Add your `/32` to `allowed_ingress_cidrs` and re-apply Terraform; no `0.0.0.0/0` |
| Private host unreachable directly | By design (no public IP) | Use `ProxyJump` through the gateway |
| `ProxyJump` fails | Gateway SSH not working, or agent not forwarded | Verify gateway SSH first; key must reach the gateway |
| Host key prompt blocks automation | First connection | `host_key_checking=False` is set in `ansible.cfg` for the lab |

Quick checks:
```bash
ssh -i ~/.ssh/<key> ubuntu@<gateway_public_ip> 'echo gateway-ok'
ssh -i ~/.ssh/<key> -o ProxyJump=ubuntu@<gateway_public_ip> ubuntu@<dmz_private_ip> 'echo dmz-ok'
ansible all -i inventories/team1.ini -m ping
```

## Package-proxy failures
| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `apt update` hangs on private host | Provisioning egress disabled (expected default) | Enable temporarily (see README §4) |
| Proxy refused | apt-cacher-ng stopped (expected when egress off) | Enable egress; service starts only then |
| Private host can't reach proxy | SG provisioning egress off, or wrong `gateway_private_ip` | Set Terraform `enable_provisioning_egress=true`; set Ansible `gateway_private_ip` |
| Packages still fetched directly | apt proxy file missing | Confirm `enable_provisioning_egress=true` and `gateway_private_ip` set |

Verify on the gateway:
```bash
sudo systemctl status apt-cacher-ng
ss -ltnp | grep 3142          # should bind to the private IP, not 0.0.0.0
```

## Ansible failures
| Symptom | Cause | Fix |
|---------|-------|-----|
| `Missing sudo password` | `become` needs privilege | Cloud image `ubuntu` has passwordless sudo; verify it wasn't changed |
| `apt cache lock` | Unattended-upgrades running | Re-run; tasks are idempotent |
| Docker tasks skipped on gateway | `elx_install_docker: false` (intended) | Gateway needs no Docker in Phase 1b |

## Reset relationship
A clean rebuild is `terraform destroy` + `terraform apply` + re-run `site.yml`. See
`reset-procedure.md`.
