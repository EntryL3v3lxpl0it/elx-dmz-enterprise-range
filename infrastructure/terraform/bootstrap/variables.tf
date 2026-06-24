variable "aws_region" {
  description = "AWS region for the Terraform state bucket."
  type        = string
  default     = "us-east-2"
}

variable "state_bucket_name" {
  description = "Override the state bucket name. If empty, defaults to elx-tfstate-<account-id>-<region>."
  type        = string
  default     = ""
}

variable "owner" {
  description = "Owner tag value."
  type        = string
  default     = "Brian"
}
