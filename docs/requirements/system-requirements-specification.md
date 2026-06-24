# ELX DMZ-to-Enterprise Offensive Security Training Range
## System Requirements Specification v1.0

## 1. Purpose

The ELX DMZ-to-Enterprise Offensive Security Training Range shall provide a controlled, authorized, black-box training environment where students exploit public-facing vulnerable business applications, collect evidence, capture dynamic flags, submit a formal PDF report, and review telemetry.

## 2. Training Objectives

Students shall demonstrate:

- Scope interpretation and rules-of-engagement discipline.
- Host discovery and service enumeration.
- Web and API application mapping.
- Vulnerability validation using evidence.
- Controlled initial access through intentional lab weaknesses.
- Internal service discovery through approved exploit chains.
- Formal reporting with root cause, impact, and remediation.
- Telemetry review using instructor-approved logs.

## 3. Locked Architecture Decisions

| Area | Decision |
|---|---|
| Cloud Provider | AWS |
| Region | us-west-2 |
| Runtime | Ephemeral, built on demand and destroyed after use |
| Team Isolation | Per-team VPC |
| Domain Pattern | teamN.elx-lab.local |
| Team 1 Domain | team1.elx-lab.local |
| Authentication | WireGuard VPN per team |
| CI/CD | GitHub Actions |
| IaC | Terraform |
| Configuration | Ansible |
| App Runtime | Docker Compose |
| Source Visibility | Hidden from students |
| Flag Model | Dynamic per build/reset |
| Report Submission | PDF upload through scoring portal |

## 4. MVP Scope

The MVP shall include:

- One Team 1 VPC.
- One DMZ subnet.
- One Ubuntu DMZ server.
- One vulnerable web application: northstar-portal.
- One dynamic flag.
- One scoring API.
- One local Docker Compose deployment.
- One Terraform skeleton.
- One Ansible skeleton.
- One deploy workflow.
- One destroy workflow.

## 5. MVP Vulnerability

The first vulnerability shall be an intentional IDOR in the customer profile workflow of northstar-portal.

## 6. Safety Requirements

- The environment shall use synthetic data only.
- The environment shall not use production credentials.
- Student access shall be limited to authorized targets.
- Internal subnet access shall not be directly reachable by students.
- Ephemeral infrastructure shall be destroyed after use.
- Logs, scores, reports, and metadata shall be archived before teardown.

## 7. Acceptance Criteria

The MVP is complete when:

- The local deployment starts with Docker Compose.
- northstar-portal is reachable locally.
- The dynamic flag generator creates a unique flag.
- The flag is injected into seeded application data.
- The scoring API accepts the correct flag.
- The scoring API rejects an incorrect flag.
- Terraform validates.
- Ansible syntax checks pass.
- GitHub workflow syntax exists for deploy and destroy.
