variable "name_prefix" { type = string }
variable "environment" { type = string }
variable "vpc_id" { type = string }
variable "vpc_cidr" { type = string }

variable "allowed_ingress_cidrs" {
  description = "Allowlisted PUBLIC source CIDRs permitted to reach the gateway (WireGuard + admin SSH). Never 0.0.0.0/0."
  type        = list(string)
  validation {
    condition     = !contains(var.allowed_ingress_cidrs, "0.0.0.0/0")
    error_message = "0.0.0.0/0 is not permitted. Provide explicit allowlisted source CIDRs."
  }
}

variable "wireguard_port" {
  type    = number
  default = 51820
}

variable "wireguard_client_cidr" {
  description = "In-tunnel WireGuard client CIDR (used to permit student access to DMZ apps over the VPN)."
  type        = string
  default     = "10.99.0.0/24"
}

variable "s3_prefix_list_id" {
  description = "Prefix list id of the S3 gateway endpoint (for egress to S3). Empty to skip."
  type        = string
  default     = ""
}

variable "enable_provisioning_egress" {
  description = "When true, allow private hosts to reach the gateway package/cache proxy. Keep false except during provisioning."
  type        = bool
  default     = false
}

variable "proxy_port" {
  description = "Gateway package/cache proxy port (e.g., apt-cacher-ng 3142)."
  type        = number
  default     = 3142
}

variable "dmz_to_intapp_ports" {
  description = "TCP ports the DMZ app host may open to the internal app host (placeholders refined per attack path)."
  type        = list(number)
  default     = [8080, 5432]
}
