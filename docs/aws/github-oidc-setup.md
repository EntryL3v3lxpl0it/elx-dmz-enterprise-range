# GitHub OIDC Setup for AWS Deployment

## Purpose

This document defines the AWS authentication model for GitHub Actions deployment of the ELX DMZ-to-Enterprise Offensive Security Training Range.

The repository shall use GitHub OpenID Connect to assume an AWS IAM role. Long-lived AWS access keys shall not be stored in GitHub repository secrets.

## Required GitHub Repository

```text
EntryL3v3lxpl0it/elx-dmz-enterprise-range
Required AWS Region
us-west-2
Required GitHub Secret
AWS_DEPLOY_ROLE_ARN

This secret stores the IAM role ARN, not static access keys.

Required GitHub Actions Permissions
permissions:
  id-token: write
  contents: read
Deployment Role Scope

The initial MVP deployment role shall allow only the resources required for the Team 1 MVP:

VPC
Subnets
Internet gateway
Route table
Route table association
Security group
Security group ingress and egress rules
EC2 instance
EC2 instance tags

The role shall be restricted after the MVP stabilizes.

Trust Policy Requirements

The AWS IAM role trust policy shall restrict access to this repository and branch.

Expected repository subject pattern:

repo:EntryL3v3lxpl0it/elx-dmz-enterprise-range:ref:refs/heads/main
Operational Rule

Deployment is allowed only through approved GitHub Actions workflows or instructor-approved local Terraform commands.
