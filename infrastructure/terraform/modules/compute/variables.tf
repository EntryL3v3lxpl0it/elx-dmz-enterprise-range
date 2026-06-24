variable "name_prefix" { type = string }
variable "environment" { type = string }
variable "ami_id" { type = string }
variable "key_name" {
  description = "Name of an existing aws_key_pair for SSH."
  type        = string
}

variable "subnet_ids" {
  description = "Map of zone name -> subnet id (expects keys: mgmt, dmz, intapp)."
  type        = map(string)
}

variable "gateway_sg_id" { type = string }
variable "dmz_app_sg_id" { type = string }
variable "intapp_sg_id" { type = string }

variable "gateway_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "workload_instance_type" {
  type    = string
  default = "t3.small"
}

variable "enable_workload_hosts" {
  description = "Deploy the DMZ app + internal app hosts. Set false for a network-only first apply."
  type        = bool
  default     = true
}

variable "gateway_acts_as_nat" {
  description = <<-EOT
    BREAK-GLASS ONLY. Default false. When true, only disables the gateway's
    source/dest check. It does NOT add a private default route to the gateway ENI
    or open the gateway SG, so it does not by itself create a working NAT path.
    Normal egress is the app-layer package proxy (Decision #12). Use this flag only
    during an explicit, temporary incident alongside manual route/iptables changes,
    then revert.
  EOT
  type        = bool
  default     = false
}

variable "root_volume_size" {
  type    = number
  default = 20
}
