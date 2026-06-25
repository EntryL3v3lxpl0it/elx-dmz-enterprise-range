# Enterprise Cyber TTP Training Pipeline

## Project Purpose

This project documents the full design, build, testing, validation, and continuous improvement process for an enterprise-like cyber range used for learning, training, and practicing modern cybersecurity tradecraft.

The purpose of this range is to provide a controlled, authorized, and reproducible environment for developing skills across:

* Penetration testing
* Exploit development
* Security research
* Vulnerability analysis
* Cyber defense
* Threat hunting
* Detection engineering
* Purple-team validation
* Adversary emulation
* Incident response readiness

This repository is structured as a professional journal and training pipeline. It records each phase of the project, including planning, architecture, infrastructure design, lab development, attack-path design, defensive telemetry, detection logic, validation steps, lessons learned, and after-action reporting.

## Project Vision

The goal is to build more than a collection of labs. The goal is to design a governed training system that reflects how modern enterprise environments are planned, attacked, defended, monitored, and improved.

This project is intended to show how offensive security, exploit research, and defensive engineering connect in practice. Each lab and scenario should help answer three questions:

1. What weakness, misconfiguration, or behavior is being tested?
2. How can that behavior be safely validated in a controlled environment?
3. How should defenders detect, investigate, contain, and remediate it?

## Why This Project Exists

Modern cybersecurity training often separates offensive and defensive disciplines. Penetration testers learn exploitation. Defenders learn alert triage. Detection engineers learn telemetry and analytics. Security researchers study root cause and exploitability.

In real environments, those disciplines are connected.

A realistic training range should help practitioners understand the full lifecycle:

* How systems are designed
* How weaknesses are introduced
* How attackers chain weaknesses together
* How defenders collect telemetry
* How detections are created and validated
* How findings are documented
* How risk is communicated
* How systems are improved

This repository documents that lifecycle step by step.

## Professional Journal

This GitHub repository serves as a public professional journal for my cybersecurity development. It documents my process, technical decisions, failures, corrections, lessons learned, and growth as I continue building expertise in penetration testing, exploit development, security research, cyber defense, and detection engineering.

The intent is not to publish unrestricted offensive tradecraft. The intent is to document a responsible, evidence-driven training system that can help others learn how to think, test, validate, document, and defend.

## Training the Next Generation

A secondary goal of this project is to create a resource that can help train the next generation of security professionals.

Students and early-career practitioners should not learn cybersecurity as a random collection of tools. They should learn it as a disciplined process built on:

* Scope
* Authorization
* Documentation
* Evidence
* Reproducibility
* Safety
* Technical accuracy
* Defensive context
* Clear communication

This project is designed to model that standard.

## Operating Principles

All work in this repository is based on the following principles:

1. **Authorized environments only**
   All offensive testing, exploit validation, and adversary emulation are performed only in controlled lab environments created for training and research.

2. **Documentation at every phase**
   Each phase is documented, including design decisions, assumptions, constraints, commands, validation steps, expected results, errors, and lessons learned.

3. **Evidence-driven practice**
   Claims must be supported by logs, screenshots, packet captures, source code review, telemetry, or repeatable validation steps.

4. **Offense informs defense**
   Offensive activity is used to understand exposure, validate exploitability, and improve defensive visibility.

5. **Detection is a first-class objective**
   Labs are not complete when exploitation succeeds. Labs are complete when the behavior is understood, telemetry is collected, detections are tested, and mitigations are documented.

6. **Safe publication boundaries**
   Public content focuses on methodology, architecture, lab design, defensive analytics, root-cause analysis, mitigations, and controlled demonstrations. Sensitive data, customer information, credentials, and unsafe turnkey exploit material are not published.

7. **Reproducibility matters**
   The range should be rebuildable, testable, and explainable. Infrastructure, scripts, documentation, and validation steps should support repeatable learning.

## Scope of the Range

The range is intended to simulate enterprise-like conditions, including:

* Public-facing DMZ services
* Internal services
* Identity and access controls
* Linux and Windows hosts
* Web applications and APIs
* File-sharing services
* Logging and telemetry pipelines
* Security monitoring
* Detection engineering workflows
* Attack-path validation
* Defensive response and remediation

The range will evolve over time as new scenarios, controls, detections, and training objectives are added.

## Expected Outcomes

By documenting this project publicly, the repository should demonstrate:

* Enterprise cyber range design
* Infrastructure-as-code discipline
* Secure lab architecture
* Threat-informed scenario development
* Penetration testing methodology
* Exploitability validation
* Detection engineering
* Purple-team reporting
* Defensive control validation
* Technical writing and mentorship readiness

The final objective is to create a structured, professional, and repeatable training pipeline that helps bridge the gap between learning cybersecurity concepts and practicing them in realistic enterprise conditions.
# elx-dmz-enterprise-range

A controlled, authorized, **lab-only** offensive-security training range simulating a
Fortune 500-style enterprise. For penetration-testing practice, exploit *validation*,
detection engineering, purple-team exercises, and professional reporting.

> ⚠️ **Authorized use only.** Every vulnerability is intentionally introduced and lab-only.
> No real malware, persistence, stealth tooling, or instructions for attacking third-party
> systems. The range is not internet-exposed (VPN / source-IP allowlist).

## Layout
```text
docs/             architecture (+ decision-log), student, instructor, operations, identity, attack-paths, detection
infrastructure/
  terraform/      VPC, security groups, compute, budget, S3 backend (Phase 1)
  ansible/        host configuration (Phase 1b+)
services/         intentionally-vulnerable apps (Phase 2+)
scripts/          reset / cost tooling
tests/            validation
```

## Start here
- Architecture: `docs/architecture/overview.md`, `network-design.md`, `enterprise-target-state.md`
- Decisions: `docs/architecture/decision-log.md`
- Terraform: `infrastructure/terraform/README.md`

## Standards alignment
MITRE ATT&CK, CWE, CVSS, OWASP Top 10 / WSTG, NIST SP 800-115, CIS Controls.
