# Backend is configured at init time to keep account-specific values out of
# the public repo (Decision #8 / A-11):
#
#   terraform init -backend-config=backend.hcl
#
# See backend.hcl.example for the expected keys. The real backend.hcl is gitignored.
terraform {
  backend "s3" {}
}
