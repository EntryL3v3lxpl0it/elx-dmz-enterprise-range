# Cost Control

Default posture: **ephemeral and minimal** (A-10). Build, test, document, destroy.

## Guardrails
- Hard cap **$50/month** (Decision #3); target $25–35. Alerts at 50/80/100% (ACTUAL) + 100% (FORECASTED).
- Smallest viable instances (t3.micro gateway, t3.small workloads). Single AZ, `us-east-2`.
- Multi-service hosts via Docker Compose to reduce instance count (A-06).
- Tagged `Project / Environment / Owner / CostControl` (+ `ManagedBy`, `Ephemeral`) for attribution and bulk teardown.

## Explicit Phase 1 exclusions (A-12, cost-risk)
NAT Gateway, load balancers (ALB/ELB), RDS, managed OpenSearch, always-on Windows hosts,
full Security Onion. Replaced by: gateway package-proxy egress, NGINX reverse-proxy container,
containerized DB, lightweight log collector.

## Accuracy note: public IPv4
AWS bills **all public IPv4 addresses, including in-use Elastic IPs** (~$0.005/hr ≈ $3.6/mo if
always on). Only the single gateway EIP is public. Under the ephemeral destroy/recreate model
the real cost is hours-based and negligible; the EIP is released on `terraform destroy`.

## Strongest control
`terraform destroy` at end of session. See `reset-procedure.md`.
