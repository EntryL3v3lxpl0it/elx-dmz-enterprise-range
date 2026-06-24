# Architecture Overview

`elx-dmz-enterprise-range` is a controlled, authorized, **lab-only** offensive-security
training range that simulates a Fortune 500-style enterprise. It is built in three tiers:
an MVP Foundation, a Near-Term Enterprise Simulation, and a Full Target State.

## Three tiers (read this first)

| Tier | What exists | Status |
|------|-------------|--------|
| **MVP Foundation** | 1 VPC, 3 subnets (public-edge, dmz-apps, internal-apps), gateway + 1 vulnerable DMZ app host + 1 internal app host, $50 budget, S3 state, lightweight/co-located monitoring | **Phase 1 (current)** |
| **Near-Term Enterprise Simulation** | Multiple web apps behind a private reverse proxy, cloud-services zone, internal app tier (Linux + Windows), file/DB services, initial Samba AD identity model, Zeek/Suricata-lite | Later |
| **Full Target State** | All 8 zones, 9 app categories, 500+ synthetic identities, 6+ attack paths, full detection + scoring, multi-team templating | Later |

> Phase 1 is the **MVP Foundation only**. The deployed subset is intentionally minimal;
> the enterprise zones are reserved in the CIDR plan and documented, not implemented.

## Reconciled architecture (target flow)

```text
Student / Team
   │  VPN / allowlisted access (no public attack surface)
   ▼
Public Edge / Gateway        (WireGuard, controlled ingress + egress, package proxy)
   │  reverse proxy / controlled ingress
   ▼
DMZ Applications             (intentionally vulnerable, lab-only)
   ▼
Cloud Services Simulation
   ▼
Internal Applications
   ▼
Identity / Active Directory  (Samba AD DC; 500+ SYNTHETIC identity objects, not hosts)
   ▼
On-Prem Simulation
   ▼
Monitoring / Detection
   ▼
Instructor / Scoring
```

### Phase 1 deployed subset

```text
Student ──VPN──> Public Edge / Gateway ──> Private DMZ App Host ──> Private Internal App Host
```

## Design principles

1. **Deny-by-default segmentation.** Each zone is a subnet with explicit, justified flows only.
2. **No public attack surface.** Ingress is WireGuard / source-IP allowlist; no `0.0.0.0/0` ingress.
3. **Gateway is infrastructure, not a target.** Students never land on the host that controls VPN, egress, proxy, and admin access.
4. **NAT-less egress.** Private subnets have no default route; AWS access via free gateway endpoints; package installs via the gateway proxy during controlled provisioning only.
5. **Reproducible by IaC.** Terraform provisions; Ansible (later) configures; ephemeral build/test/destroy.
6. **Cost-governed.** $50/month hard cap; no NAT Gateway, ALB, RDS, managed search, or Windows AD DS in the MVP.

## Identity note

The "500 users" requirement means **500+ synthetic Active Directory / LDAP identity objects**
(users, groups, service accounts) seeded from deterministic fake data — **not 500 machines**.
See `docs/identity/identity-model.md` (later phase) and the decision log.

## Related docs
- `network-design.md` — CIDR plan, zones, ingress/egress, segmentation.
- `enterprise-target-state.md` — the full Fortune 500-style end state.
- `decision-log.md` — locked decisions and reconciliation record.
