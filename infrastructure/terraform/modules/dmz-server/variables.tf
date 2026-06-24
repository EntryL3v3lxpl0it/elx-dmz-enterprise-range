variable "project" {
  type    = string
  default = "elx-training-range"
}

variable "cohort_id" {
  type = string
}

variable "team_id" {
  type = string
}

variable "domain" {
  type = string
}

variable "expires_at" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "dmz_subnet_id" {
  type = string
}

variable "student_source_cidr" {
  type        = string
  description = "Temporary source CIDR allowed to reach DMZ HTTP/SSH during MVP testing. Replace with WireGuard later."
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "ami_id" {
  type        = string
  description = "Ubuntu AMI ID for the selected AWS region."
}

variable "ssh_key_name" {
  type        = string
  description = "Existing EC2 key pair name for instructor SSH during MVP testing."
}
