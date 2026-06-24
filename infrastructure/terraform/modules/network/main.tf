# ---------------------------------------------------------------------------
# Network foundation: one VPC, single-AZ subnets, an Internet Gateway used
# ONLY by the public (edge) subnet, and free gateway endpoints. No NAT Gateway.
# Private subnets have NO default route to the internet (Decision #12).
# ---------------------------------------------------------------------------

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.name_prefix}-${var.environment}-vpc"
    Zone = "core"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name_prefix}-${var.environment}-igw"
    Zone = "core"
  }
}

resource "aws_subnet" "this" {
  for_each = var.subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = var.az

  # No auto-assigned public IPv4 anywhere; the edge host uses a single EIP.
  map_public_ip_on_launch = false

  tags = {
    Name   = "${var.name_prefix}-${var.environment}-${each.key}"
    Zone   = each.key
    Public = tostring(each.value.public)
  }
}

# --- Routing -------------------------------------------------------------

# Public route table: default route to the Internet Gateway (edge egress).
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name_prefix}-${var.environment}-rt-public"
    Zone = "public"
  }
}

resource "aws_route" "public_default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

# Private route table: intentionally NO default route. Local + endpoints only.
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name_prefix}-${var.environment}-rt-private"
    Zone = "private"
  }
}

locals {
  public_subnet_keys  = [for k, v in var.subnets : k if v.public]
  private_subnet_keys = [for k, v in var.subnets : k if !v.public]
}

resource "aws_route_table_association" "public" {
  for_each       = toset(local.public_subnet_keys)
  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  for_each       = toset(local.private_subnet_keys)
  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.private.id
}

# --- Gateway endpoints (free; no IGW/NAT required) -----------------------

resource "aws_vpc_endpoint" "s3" {
  count             = var.enable_s3_endpoint ? 1 : 0
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id, aws_route_table.public.id]

  tags = {
    Name = "${var.name_prefix}-${var.environment}-vpce-s3"
    Zone = "core"
  }
}

resource "aws_vpc_endpoint" "dynamodb" {
  count             = var.enable_dynamodb_endpoint ? 1 : 0
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${var.aws_region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = {
    Name = "${var.name_prefix}-${var.environment}-vpce-dynamodb"
    Zone = "core"
  }
}

