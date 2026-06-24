variable "aws_region" {
  description = "AWS region (used for gateway endpoint service names)."
  type        = string
}

variable "name_prefix" {
  description = "Short prefix for resource names (e.g., elx)."
  type        = string
}

variable "environment" {
  description = "Environment / team identifier (e.g., team1)."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "az" {
  description = "Single Availability Zone for Phase 1 (cost). e.g., us-east-2a."
  type        = string
}

variable "subnets" {
  description = <<-EOT
    Map of subnets to create. Key is the zone name. Each value:
      cidr   = subnet CIDR
      public = true to route 0.0.0.0/0 via the Internet Gateway (egress edge only)
  EOT
  type = map(object({
    cidr   = string
    public = bool
  }))
}

variable "enable_s3_endpoint" {
  description = "Create a free S3 gateway endpoint for private-subnet AWS access."
  type        = bool
  default     = true
}

variable "enable_dynamodb_endpoint" {
  description = "Create a free DynamoDB gateway endpoint (off by default; only if needed)."
  type        = bool
  default     = false
}
