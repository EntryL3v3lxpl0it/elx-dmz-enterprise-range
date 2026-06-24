output "state_bucket_name" {
  description = "Name of the S3 bucket holding Terraform remote state."
  value       = aws_s3_bucket.tfstate.id
}

output "backend_hcl_hint" {
  description = "Values to place in envs/team1/backend.hcl (do not commit the real file)."
  value       = <<-EOT
    bucket       = "${aws_s3_bucket.tfstate.id}"
    key          = "elx-dmz-enterprise-range/team1/terraform.tfstate"
    region       = "${var.aws_region}"
    encrypt      = true
    use_lockfile = true
  EOT
}
