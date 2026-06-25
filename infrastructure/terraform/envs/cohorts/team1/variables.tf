variable "aws_region" {
  description = "AWS region for the team1 environment."
  type        = string
  default     = "us-east-2"
}

variable "cohort_id" {
  description = "Cohort identifier used for tagging."
  type        = string
  default     = "cohort-dev"
}

variable "team_id" {
  description = "Team identifier used for naming and tagging."
  type        = string
  default     = "team1"
}

variable "domain" {
  description = "Internal lab domain for the team."
  type        = string
  default     = "team1.elx-lab.local"
}

variable "expires_at" {
  description = "Expiration marker used for tagging and cleanup tracking."
  type        = string
  default     = "manual-dev"
}

variable "student_source_cidr" {
  description = "Authorized student or instructor source IPv4 CIDR for SSH and HTTP access. Must be a /32; never use 0.0.0.0/0."
  type        = string

  validation {
    condition     = can(cidrhost(var.student_source_cidr, 0)) && !contains(["0.0.0.0/0", "0.0.0.0/32"], var.student_source_cidr)
    error_message = "student_source_cidr must be a valid IPv4 CIDR and must not be 0.0.0.0/0 or 0.0.0.0/32."
  }
}

variable "ami_id" {
  description = "Ubuntu AMI ID for us-east-2."
  type        = string

  validation {
    condition     = can(regex("^ami-[0-9a-f]+$", var.ami_id))
    error_message = "ami_id must be a valid AMI ID such as ami-0123456789abcdef0."
  }
}

variable "ssh_key_name" {
  description = "Existing AWS EC2 key pair name used for SSH access."
  type        = string

  validation {
    condition     = length(trimspace(var.ssh_key_name)) > 0 && var.ssh_key_name != "REPLACE_ME"
    error_message = "ssh_key_name must be an existing EC2 key pair name and must not be REPLACE_ME."
  }
}

variable "dmz_instance_type" {
  description = "EC2 instance type for the DMZ host."
  type        = string
  default     = "t3.micro"
}
