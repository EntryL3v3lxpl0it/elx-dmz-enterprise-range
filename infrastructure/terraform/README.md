# infra/ — Terraform foundation

Infrastructure-as-code for the ELX DMZ Enterprise Range (Phase 1: `team1`). VPC `10.50.0.0/16`, `us-east-2`. Three of eight reserved zones are deployed (public-edge, dmz-apps, internal-apps); see `docs/architecture/network-design.md`.

## Layout
| Path | Purpose |
|------|---------|
| `bootstrap/` | One-time stack (local state) creating the encrypted, versioned S3 state bucket. |
| `modules/network/` | VPC, single-AZ subnets, IGW (edge only), private route table (no default route), free S3/DynamoDB gateway endpoints. |
| `modules/security-groups/` | Deny-by-default SGs (gateway, dmz-app, intapp). No `0.0.0.0/0` ingress. |
| `modules/compute/` | Edge gateway (EIP) + optional workload hosts. IMDSv2, encrypted EBS. |
| `modules/budget/` | $50/month cap with 50/80/100% alerts. |
| `envs/team1/` | The live environment composing the modules (S3 backend). |

## Design decisions honored
- **#3 Budget:** $50 cap, 50/80/100% alerts, ephemeral build/test/destroy, no cost-heavy managed services.
- **#8 State:** encrypted + versioned S3 backend in `us-east-2`, native locking (`use_lockfile = true`), no DynamoDB.
- **#12 Egress:** no NAT Gateway; private subnets have no default route; AWS access via free gateway endpoints; package installs via the gateway proxy during controlled provisioning only. `gateway_acts_as_nat` is **break-glass only** (inert by itself).

## What this foundation does NOT include (later phases)
- Ansible host configuration (WireGuard, package proxy, Docker, Samba AD) — Phase 1b.
- Intentionally-vulnerable applications — Phase 2.
- Synthetic identities, flags, scoring — Phase 2/3.
