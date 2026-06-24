# Instructor Deployment Guide

> Phase 1 covers the Terraform foundation. Host configuration (WireGuard, package proxy,
> Docker, Samba AD) is Ansible, Phase 1b. This guide defines the intended workflow.

## Prerequisites
- AWS credentials for the dedicated lab account (least privilege), region `us-east-2`.
- Terraform >= 1.10 (native S3 locking). Bootstrap stack applied once (creates state bucket).

## Workflow
1. `infrastructure/terraform/bootstrap` -> `terraform init && terraform apply` (one time).
2. `envs/team1`: copy `backend.hcl.example` -> `backend.hcl`, `terraform.tfvars.example` -> `terraform.tfvars` (both gitignored).
3. `terraform init -backend-config=backend.hcl`, `terraform validate`, `terraform plan`.
4. `terraform apply` to build `team1`.
5. (Phase 1b) Configure the gateway (WireGuard + package proxy) and base hosts via Ansible.
6. Distribute WireGuard profiles / add student source IPs to the allowlist. No `0.0.0.0/0`.
7. `terraform destroy` at end of session (ephemeral posture).

## Provisioning egress
Private hosts have no internet route. Set `enable_provisioning_egress = true` only while
provisioning via the gateway proxy, then back to `false`. `gateway_acts_as_nat` is break-glass only.

## Instructor-only material
Solution guides, flag manifests, and generated credentials are kept private (A-11) and never
committed to the public history.
