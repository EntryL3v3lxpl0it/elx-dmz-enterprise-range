# Identity Model (design)

Design only — no users created in Phase 1. Target: **500+ synthetic AD/LDAP identity
objects** (A-04), seeded deterministically from fake data (no real PII), reproducible on reset.
These are identity objects (users, groups, service accounts), **not machines**.

## Phase 1 platform
**Samba AD DC** (A-07), deployed in the reserved `identity-ad` zone (`10.50.50.0/24`) in a
later phase. Windows Server AD DS is a deferred realism module.

## Department distribution (target ~550, buffer above 500)
Executive Leadership, Information Technology, Security Operations, Software Engineering,
Finance, Human Resources, Legal, Sales, Marketing, Operations, Customer Support,
Vendors/Contractors, Service Accounts, Privileged Admin.

## Access tiers
- Tier 0: Domain/Enterprise Admins, Identity administrators
- Tier 1: Server/Security admins, Backup operators, Helpdesk admins
- Tier 2: Application/Database admins, DevOps users, Cloud operators
- Standard: Employees, Contractors, Department users, Service-desk users
- Service: Web app, Database, Backup, CI/CD, Monitoring service accounts

## Rules
Tier separation enforced via group membership/login restrictions (tier-crossing is an
intended attack-path objective, not a default). Generation is seeded/deterministic. A small
set of intentionally weak credentials and misconfigured service accounts is tied to specific
objectives and documented as lab-only.
