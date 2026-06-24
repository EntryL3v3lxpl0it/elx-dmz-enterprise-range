variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "az" {
  type    = string
  default = "us-east-2a"
}

variable "name_prefix" {
  type    = string
  default = "elx"
}

variable "environment" {
  type    = string
  default = "team1"
}

variable "owner" {
  type    = string
  default = "Brian"
}

variable "vpc_cidr" {
  type    = string
  default = "10.50.0.0/16"
}

variable "subnets" {
  description = <<-EOT
    Phase 1 MVP subset of the reserved 8-zone enterprise model (VPC 10.50.0.0/16).
    ONLY these three zones are deployed in Phase 1. The remaining zones are
    RESERVED in the CIDR plan below (see docs/architecture/network-design.md) and
    are implemented in later phases:

      10.50.10.0/24  public-edge     (DEPLOYED - gateway / controlled ingress+egress)
      10.50.20.0/24  dmz-apps        (DEPLOYED - vulnerable DMZ application host)
      10.50.30.0/24  cloud-services  (RESERVED - later)
      10.50.40.0/24  internal-apps   (DEPLOYED - internal application host)
      10.50.50.0/24  identity-ad     (RESERVED - later; Samba AD DC)
      10.50.60.0/24  on-prem-sim     (RESERVED - later)
      10.50.70.0/24  monitoring      (RESERVED - later; co-located in Phase 1)
      10.50.80.0/24  scoring         (RESERVED - later)
  EOT
  type = map(object({
    cidr   = string
    public = bool
  }))
  default = {
    "public-edge"   = { cidr = "10.50.10.0/24", public = true }
    "dmz-apps"      = { cidr = "10.50.20.0/24", public = false }
    "internal-apps" = { cidr = "10.50.40.0/24", public = false }
  }
}

variable "allowed_ingress_cidrs" {
  description = "Allowlisted PUBLIC source CIDRs for WireGuard + admin SSH (e.g., your IP /32). Never 0.0.0.0/0."
  type        = list(string)
}

variable "wireguard_client_cidr" {
  type    = string
  default = "10.99.0.0/24"
}

variable "ssh_public_key" {
  description = "SSH public key material for the admin key pair."
  type        = string
}

variable "enable_workload_hosts" {
  type    = bool
  default = true
}

variable "enable_provisioning_egress" {
  description = "Temporarily allow private hosts to reach the gateway package proxy. Keep false unless provisioning."
  type        = bool
  default     = false
}

variable "budget_notification_emails" {
  type = list(string)
}

variable "gateway_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "workload_instance_type" {
  type    = string
  default = "t3.small"
}
