# Enterprise Target State

The Fortune 500-style end goal the MVP builds toward. Documented now; implemented in later phases.

## Zones (full, 8)
1. **public-edge** — gateway, controlled ingress (WireGuard/allowlist), reverse proxy, egress, package proxy.
2. **dmz-apps** — corporate portal, helpdesk/ticketing, HR/employee directory, partner/vendor API, legacy app (intentionally vulnerable, lab-only).
3. **cloud-services** — cloud-hosted app server, object-storage simulation, CI/CD runner, secrets/config-exposure and IAM-boundary scenarios.
4. **internal-apps** — internal APIs, database, file share, Linux app host, Windows app host.
5. **identity-ad** — Samba AD DC (Windows AD DS as a later realism module), DNS, Kerberos, LDAP, Group Policy sim, 500+ synthetic identity objects, groups, service accounts.
6. **on-prem-sim** — legacy Windows server, Linux server, file server, admin workstation sim, jump/management host.
7. **monitoring** — Zeek/Suricata (Security Onion when budget allows a temporary larger window); web/DNS/auth/Windows event logs centralized.
8. **scoring** — dynamic flags, static evidence objectives, PDF report submission, rubric, reset automation, instructor solution guide.

## Application surface (9 categories)
Corporate portal, helpdesk/ticketing, HR/employee directory, partner/vendor API, legacy
application, internal admin portal, internal API, file-share-backed workflow, database-backed
business application. All weaknesses intentionally introduced, lab-only, documented with CWE mapping.

## Identity model (target)
500+ **synthetic** AD/LDAP identity objects across 14 categories (Executive Leadership, IT,
SecOps, Software Engineering, Finance, HR, Legal, Sales, Marketing, Operations, Customer
Support, Vendors/Contractors, Service Accounts, Privileged Admin), mapped to the
Tier 0/1/2 / Standard / Service-Account model. These are identity objects, **not machines**.

## Attack paths (target)
At least 6 chained paths (external web → internal data; helpdesk → credential exposure;
DMZ foothold → AD enumeration; cloud misconfig → secret exposure; internal service →
privilege escalation; weak RBAC → unauthorized business-data access). Each carries a
student objective, instructor-only solution, evidence checklist, detection opportunities,
and remediation.

## Public exposure model (target)
No genuine internet exposure. Multiple web apps are reached over the tunnel through a
**private reverse proxy** on the edge — not via public IPs on each app. This is the agreed
direction (reverse proxy, not per-app public IPs).

## Multi-team (target)
Per-team environment instantiated from a Terraform template (or workspace), with per-team
flags, state key, and (if teams must coexist in one account) a distinct VPC CIDR.

## Non-goals
No internet exposure, no real malware/persistence/stealth/destructive payloads, no real PII,
no third-party targeting.
