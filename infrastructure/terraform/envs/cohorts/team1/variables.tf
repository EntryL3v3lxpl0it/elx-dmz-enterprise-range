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
