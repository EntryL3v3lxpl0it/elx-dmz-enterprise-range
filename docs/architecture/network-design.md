# Network Design

> Design baseline for Phase 1 Terraform (`infrastructure/terraform`). No infrastructure
> has been applied. Cost-risk items are excluded per the decision log.

## Region / account
- Account: one dedicated lab account (A-01).
- Region: `us-east-2`. Single AZ for Phase 1 (cost). Multi-AZ deferred.

## Reserved CIDR plan (canonical)

**VPC: `10.50.0.0/16`.** All eight enterprise zones are reserved now to prevent future
collisions. **Phase 1 deploys only three** (marked DEPLOYED); the rest are reserved.

| Zone | CIDR | Phase 1 |
|------|------|---------|
| public-edge    | `10.50.10.0/24` | **DEPLOYED** — gateway / controlled ingress + egress |
| dmz-apps       | `10.50.20.0/24` | **DEPLOYED** — vulnerable DMZ application host |
| cloud-services | `10.50.30.0/24` | RESERVED |
| internal-apps  | `10.50.40.0/24` | **DEPLOYED** — internal application host |
| identity-ad    | `10.50.50.0/24` | RESERVED — Samba AD DC |
| on-prem-sim    | `10.50.60.0/24` | RESERVED |
| monitoring     | `10.50.70.0/24` | RESERVED — co-located/lightweight in Phase 1 |
| scoring        | `10.50.80.0/24` | RESERVED |

WireGuard in-tunnel client subnet: `10.99.0.0/24` (outside the VPC range; no overlap).

## Ingress model
- Students connect via **WireGuard** terminating on the gateway (public-edge), and/or an
  instructor **source-IP allowlist**.
- **No security group permits `0.0.0.0/0`** ingress. Inbound is limited to the WireGuard
  UDP port from allowlisted source CIDRs (enforced by a Terraform `validation` block).
- The "public-facing" DMZ is **simulated**; apps are reachable only over the tunnel.

## Egress model (no NAT Gateway)
- `public-edge` route table: default route to the Internet Gateway (edge egress only).
- Private route table (`dmz-apps`, `internal-apps`, future zones): **no default route**.
- AWS access via the **free S3 gateway endpoint** (DynamoDB endpoint available, off by default).
- Package/image installs via the gateway's package/cache proxy, gated by
  `enable_provisioning_egress` (default **false**). Egress is explicit and temporary.
- `gateway_acts_as_nat` is **break-glass only** and does not by itself create a working NAT path.

## Segmentation (deny-by-default)
Default deny on inter-zone traffic. Phase 1 allowed flows:

| From | To | Ports | Reason |
|------|-----|-------|--------|
| WireGuard client subnet | dmz-apps | 80/443 | reach simulated public apps over tunnel |
| gateway | dmz-apps / internal-apps | 22 | admin SSH (bastion model) |
| dmz-apps | internal-apps | 8080/5432 (placeholders) | app → backend; refined per attack path |
| dmz-apps / internal-apps | gateway | proxy port | provisioning only (toggle off by default) |
| dmz-apps / internal-apps | VPC resolver | 53 | DNS |
| dmz-apps / internal-apps | S3 endpoint | 443 | AWS artifacts |
| gateway | internet | egress | controlled edge egress |

> Open item (deferred to Phase 1b): the `dmz-apps` 80/443 ingress source depends on the
> chosen WireGuard forwarding mode (masquerade vs route). Decide the mode before enabling
> student access so the SG source matches.

## Hosts (Phase 1)
- `elx-team1-gateway-01` (public-edge): WireGuard + egress + package proxy. **Infra only.**
- `elx-team1-dmz-app-01` (dmz-apps, private): intentionally-vulnerable web app + reverse proxy.
- `elx-team1-intapp-01` (internal-apps, private): internal service + DB + lightweight collector.

No host has a public IP except the single gateway EIP. All EBS encrypted; IMDSv2 enforced.

## Naming / tags
- Hosts: `elx-<env>-<role>-<nn>`. SGs: `elx-<env>-sg-<role>`. Subnets tagged `Zone=<zone>`.
- Default tags: `Project=elx-dmz-enterprise-range`, `Environment=team1`, `Owner=Brian`,
  `CostControl=true`, `ManagedBy=terraform`, `Ephemeral=true`.

## Configuration management (Ansible, Phase 1b)
Terraform builds the network and hosts; **Ansible** configures them:
- **SSH topology:** the gateway (public-edge) is the only SSH entry point. The `dmz-apps`
  and `internal-apps` hosts are private and reached via `ProxyJump` through the gateway
  (bastion model). This matches the security-group rules (admin SSH to private hosts only
  from the gateway SG).
- **Provisioning egress:** private hosts have no internet route. When OS packages are needed,
  `enable_provisioning_egress` is toggled on (Terraform SG rule + Ansible apt-cacher-ng on the
  gateway), then toggled back off. Egress is explicit and temporary; no NAT Gateway is used.
- **WireGuard mode:** **routed** (decided). Client source IPs are preserved end-to-end,
  so the `dmz-apps` 80/443 ingress from `wireguard_client_cidr` (10.99.0.0/24) is correct.
  Implementing routed WG later requires: a private-route-table entry for 10.99.0.0/24 via the
  gateway ENI, gateway IP forwarding ON (routed, no masquerade), and `source_dest_check=false`
  on the gateway. These Terraform changes are identified, not yet implemented.
- **Break-glass NAT:** `gateway_acts_as_nat` (Terraform) and `gateway_enable_breakglass_nat`
  (Ansible) only toggle source/dest check and IP forwarding respectively. A working NAT path
  additionally needs manual iptables MASQUERADE and a private default route, which are
  intentionally not automated.
- **Inventory:** generated from Terraform outputs into a gitignored `team1.ini` (no real IPs in
  the repo). See `infrastructure/ansible/README.md`.
