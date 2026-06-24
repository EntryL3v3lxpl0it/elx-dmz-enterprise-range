variable "aws_region" {
  type    = string
  default = "us-west-2"
}

variable "cohort_id" {
  type    = string
  default = "cohort-dev"
}

variable "team_id" {
  type    = string
  default = "team1"
}

variable "domain" {
  type    = string
  default = "team1.elx-lab.local"
}

variable "expires_at" {
  type    = string
  default = "manual-dev"
}

variable "student_source_cidr" {
  type        = string
  description = "Authorized source CIDR for MVP HTTP/SSH access."
  default     = "0.0.0.0/32"
}

variable "ami_id" {
  type        = string
  description = "Ubuntu AMI ID for us-west-2."
  default     = "ami-REPLACE_ME"
}

variable "ssh_key_name" {
  type        = string
  description = "Existing EC2 key pair name."
  default     = "REPLACE_ME"
}

variable "dmz_instance_type" {
  type    = string
  default = "t3.micro"
}
