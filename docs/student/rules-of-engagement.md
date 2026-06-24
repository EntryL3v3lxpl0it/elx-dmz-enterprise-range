# Rules of Engagement (Students)

By accessing the range you accept these rules. Violations end access.

## Scope
- In scope: only the hosts, apps, and identities in your assigned range (your team's VPC and
  the CIDRs listed in `getting-started.md`).
- Out of scope: the gateway internals, monitoring/scoring infrastructure, other teams'
  environments, the AWS account/management plane, and anything not explicitly assigned.

## Hard prohibitions
1. Do not attack anything outside your assigned range (internet, AWS account, instructor infra, other students).
2. Do not attempt to break out of the range to the underlying AWS account.
3. No real malware, ransomware, or destructive payloads.
4. No DoS that prevents others from working unless an objective explicitly authorizes a bounded demo.
5. No exfiltration to systems outside the range.
6. Do not share flags or solution material.

## Conduct
Treat it as an authorized engagement: stay in scope, collect evidence, document reproduction
steps, report professionally. If you find an unintended (real) platform vulnerability, **stop
and report it** — do not exploit it.

## Evidence & reporting standard
Each finding: title, affected component, attack surface, weakness (CWE), severity (CVSS if
supportable), preconditions, evidence, root cause, impact, exploitability, reproduction steps,
expected vs. observed, remediation, residual risk.

## Safety
Everything here is intentionally vulnerable and lab-only. These techniques are legal here
because you are authorized and the targets are owned training assets — not elsewhere.
