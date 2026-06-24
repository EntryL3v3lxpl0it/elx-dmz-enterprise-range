# Decision Log

Chronological record of locked decisions for `elx-dmz-enterprise-range`. Newest at the bottom.

## Assumptions (A-01 .. A-12) — locked
- A-01 AWS only, one dedicated lab account, region `us-east-2`.
- A-02 Phase 1 = one active team (`team1`); multi-team is a Terraform templating goal.
- A-03 No public attack surface; ingress WireGuard and/or source-IP allowlist; no `0.0.0.0/0`.
- A-04 "500 users" = 500+ seeded identity objects in Samba AD/LDAP, **not** 500 hosts.
- A-05 All vulnerabilities lab-only, intentional, documented, bounded to the range.
- A-06 Terraform provisions; Ansible configures; Docker Compose runs multiple services per host.
- A-07 Samba AD DC is the Phase 1 identity default; Windows Server AD DS deferred.
- A-08 Reset is destroy/recreate first; snapshots/AMIs optional later.
- A-09 Phase 1 monitoring lightweight; full Security Onion deferred.
- A-10 Default posture ephemeral: build, test, document, destroy.
- A-11 Public repo: architecture, IaC, safe app code, docs, validation logic. Private:
  instructor solutions, generated credentials, flag manifests, private keys, exploit answers.
- A-12 Out of Phase 1 (cost-risk): NAT Gateway, load balancers, RDS, managed OpenSearch,
  always-on Windows hosts, full Security Onion.

## Gate decisions
- **#3 Budget:** hard cap $50/month (target $25–35). Alerts at 50/80/100%. Required tags:
  `Project=elx-dmz-enterprise-range`, `Environment=team1`, `Owner=Brian`, `CostControl=true`.
  `terraform destroy` is part of the normal workflow.
- **#8 Terraform state:** encrypted, versioned S3 backend in `us-east-2` with native locking
  (`use_lockfile = true`); DynamoDB locking deferred. Backend values supplied at init via a
  gitignored `backend.hcl` (account IDs not committed).
- **#12 NAT-less egress:** no managed NAT Gateway. Private subnets have no default route.
  AWS access via free gateway endpoints (S3). Package installs via prebuilt images or the
  gateway package/cache proxy during controlled provisioning only; egress explicit and logged.

## Phase 1 reconciliation (candidate -> baseline)
**KEEP**
- Gateway is infrastructure, not the vulnerable target.
- Vulnerable DMZ app host is separate from the gateway.
- No NAT Gateway. No `0.0.0.0/0` ingress.
- S3 backend bootstrap pattern. $50 budget guardrail.
- Private workload hosts. `terraform destroy` as normal end-of-session workflow.

**REVISE (applied)**
- Repo: `infra/` -> `infrastructure/terraform/`.
- CIDR: VPC re-planned to `10.50.0.0/16`; zones renamed to public-edge / dmz-apps /
  internal-apps; full 8-zone CIDR plan reserved (only 3 deployed in Phase 1).
- `gateway_acts_as_nat` documented as **break-glass only** (inert by itself; default false).
- Architecture docs backfilled with MVP / Near-Term / Full distinction; this decision log added.
- DMZ web exposure direction: future **private reverse proxy**, not public IPs per app.
- AD / monitoring / cloud-services / on-prem zones documented now, implemented later.

**OPEN (deferred to Phase 1b)**
- WireGuard forwarding mode (masquerade vs route) determines the `dmz-apps` 80/443 ingress
  source. Decide before enabling student access. (Review item R2.)
- `compute` module is host-type-specific; refactor to a generic host map before Windows/AD/
  monitor hosts are added. (Review item R3.)

## Validation honesty
As of this reconciliation, Terraform `init`/`validate`/`fmt`/`plan` have **not** been run by
the assistant (no registry/AWS access in its environment). Only brace/paren balance and
`grep` checks were performed. Run the validation commands in your environment before any apply.

## WireGuard forwarding mode (decided)
**Decision: WireGuard routed mode.**
Reason: preserves student/client source IPs, improves logging and attribution, supports
cleaner security-group design, and better matches professional range operations.
Rejected alternative: masquerade/NAT mode — easier routing, but private hosts only see
gateway-sourced traffic, reducing attribution value.

Routed mode (when implemented in a later, explicitly-approved step) will use:
- A dedicated WireGuard client CIDR (`10.99.0.0/24`, already reserved; outside the VPC).
- VPC route-table entries for the WG client CIDR via the gateway ENI.
- Gateway IP forwarding enabled for routed VPN traffic (NOT masquerade).
- No iptables MASQUERADE by default.
- Security-group rules allowing only required traffic from the WG client CIDR.

**Resolves review item R2:** routed mode preserves client IPs, so the existing
`dmz-apps` 80/443 ingress source (`wireguard_client_cidr`) is **correct as written**.
No SG change is needed now.

### Terraform changes this implies LATER (not implemented now)
1. `modules/network` — add an `aws_route` in the **private** route table:
   destination `10.99.0.0/24` -> `network_interface_id` = gateway ENI (so replies to WG
   clients route back through the gateway). Requires exposing the gateway ENI id.
2. Gateway instance — `source_dest_check = false` is required for routed forwarding
   (forwarding packets whose src/dst is not the gateway itself). NOTE: the current
   `gateway_acts_as_nat` toggle disables source/dest check but is **mis-named** for routed
   mode (routed mode is not NAT). Recommend renaming/splitting later into
   `gateway_enable_routing` (routed WG, no masquerade) vs a separate break-glass NAT flag.
3. Ansible — set `gateway_enable_ip_forwarding: true` (routed) while keeping
   `gateway_enable_breakglass_nat: false`. WireGuard role/config to be added in its own phase.
These are identified for planning only. WireGuard is NOT implemented in this phase.

## Repo hygiene
Added a root `.gitignore` (global `*.tfstate`, `*.pem`, `*.key`, `**/backend.hcl`,
`**/terraform.tfvars`, `**/inventories/team1.ini`) in addition to the per-tree gitignores.
Verified via `git check-ignore` that secret-named files are ignored and `*.example` files are not.
