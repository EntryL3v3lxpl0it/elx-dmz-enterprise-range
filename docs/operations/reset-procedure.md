# Reset & Teardown Procedure

Phase 1 default is **destroy/recreate** (A-08). Snapshots/AMIs are an optional later
optimization only if rebuild time becomes a problem.

## Reset (destroy/recreate — primary)
1. `terraform destroy` the team environment (e.g., `team1`).
2. `terraform apply` to recreate VPC/subnets/hosts.
3. Reconfigure hosts with Ansible:
   ```bash
   cd infrastructure/ansible
   ./../../scripts/gen-team1-inventory.sh   # or run from repo root
   ansible-playbook -i inventories/team1.ini playbooks/site.yml
   ```
   (Vulnerable services/identities are added in later phases, not Phase 1b.)
4. Reseed identities into Samba AD/LDAP from deterministic seed data (no real PII).
5. Generate fresh dynamic flags per team; update the (private) flag manifest.
6. Run the post-deploy validation checklist.

## Teardown
1. `terraform destroy`.
2. Verify no orphaned resources (volumes, snapshots, ENIs, SGs) via tag `Project=elx-dmz-enterprise-range`.
3. Confirm spend returns to baseline.

## Safety
- Destroy/recreate is inherently repeatable.
- Teardown targets only project-tagged resources.
- Never destroy the remote Terraform state backend during routine teardown (`prevent_destroy` is set).
