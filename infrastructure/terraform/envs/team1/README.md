# team1 environment

Minimal, segmented, NAT-less range foundation in `us-east-2`.

## Prerequisites
- Terraform >= 1.10 (for native S3 state locking via `use_lockfile`).
- AWS credentials for the dedicated lab account (least privilege).
- The bootstrap stack applied once (creates the state bucket): see `../../bootstrap`.

## One-time bootstrap (creates the state bucket)
```bash
cd ../../bootstrap
terraform init
terraform apply
# note the state_bucket_name output
```

## Configure this environment
```bash
cp backend.hcl.example backend.hcl          # fill in the real bucket name (gitignored)
cp terraform.tfvars.example terraform.tfvars # fill in your IP, SSH key, email (gitignored)
```

## Plan / apply / destroy
```bash
terraform init -backend-config=backend.hcl
terraform fmt -check -recursive
terraform validate
terraform plan -out tfplan
terraform apply tfplan
# ... lab session ...
terraform destroy        # ephemeral posture (A-10): destroy when not in use
```

## Network-only first apply (optional)
Set `enable_workload_hosts = false` to stand up only the VPC/subnets/gateway/budget,
then flip to `true` to add the DMZ app and internal app hosts.

## Provisioning egress
Private hosts have no internet route. To install packages, set
`enable_provisioning_egress = true` while running Ansible against the gateway proxy,
then set it back to `false`. Egress is explicit and temporary (Decision #12).

## Cost
Hard cap $50/month; target $25–35. Hosts are small (t3.micro/t3.small). The strongest
cost control is `terraform destroy`. No NAT Gateway, no ALB, no RDS, no managed search.
