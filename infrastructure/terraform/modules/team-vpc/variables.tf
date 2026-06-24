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

variable "vpc_cidr" {
  type = string
}

variable "dmz_cidr" {
  type = string
}

variable "internal_cidr" {
  type = string
}

variable "monitor_cidr" {
  type = string
}

variable "availability_zone" {
  type = string
}

variable "expires_at" {
  type = string
}
