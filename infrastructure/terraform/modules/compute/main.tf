# ---------------------------------------------------------------------------
# Compute: one edge gateway (public subnet, single EIP) plus optional
# workload hosts in private subnets. All EBS encrypted; IMDSv2 enforced;
# no auto public IPs. Hosts are configured later by Ansible (Phase 1b).
# ---------------------------------------------------------------------------

locals {
  common_metadata = {
    http_endpoint = "enabled"
    http_tokens   = "required" # IMDSv2 only
  }
}

# --- Edge gateway --------------------------------------------------------
resource "aws_instance" "gateway" {
  ami                         = var.ami_id
  instance_type               = var.gateway_instance_type
  subnet_id                   = var.subnet_ids["public-edge"]
  vpc_security_group_ids      = [var.gateway_sg_id]
  key_name                    = var.key_name
  associate_public_ip_address = false
  # BREAK-GLASS ONLY (see variable docs / decision-log): default keeps source/dest
  # check ENABLED. Flipping this alone does NOT create a working NAT path.
  source_dest_check = var.gateway_acts_as_nat ? false : true
  monitoring        = false

  metadata_options {
    http_endpoint = local.common_metadata.http_endpoint
    http_tokens   = local.common_metadata.http_tokens
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = var.root_volume_size
    encrypted   = true
  }

  user_data = <<-EOT
    #cloud-config
    hostname: ${var.name_prefix}-${var.environment}-gateway-01
    package_update: false
  EOT

  tags = {
    Name = "${var.name_prefix}-${var.environment}-gateway-01"
    Zone = "public-edge"
    Role = "gateway"
  }
}

resource "aws_eip" "gateway" {
  domain = "vpc"
  tags = {
    Name = "${var.name_prefix}-${var.environment}-eip-gateway"
    Zone = "public-edge"
    Role = "gateway"
  }
}

resource "aws_eip_association" "gateway" {
  instance_id   = aws_instance.gateway.id
  allocation_id = aws_eip.gateway.id
}

# --- DMZ app host (vulnerable, lab-only) ---------------------------------
resource "aws_instance" "dmz_app" {
  count                       = var.enable_workload_hosts ? 1 : 0
  ami                         = var.ami_id
  instance_type               = var.workload_instance_type
  subnet_id                   = var.subnet_ids["dmz-apps"]
  vpc_security_group_ids      = [var.dmz_app_sg_id]
  key_name                    = var.key_name
  associate_public_ip_address = false
  monitoring                  = false

  metadata_options {
    http_endpoint = local.common_metadata.http_endpoint
    http_tokens   = local.common_metadata.http_tokens
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = var.root_volume_size
    encrypted   = true
  }

  user_data = <<-EOT
    #cloud-config
    hostname: ${var.name_prefix}-${var.environment}-dmz-app-01
    package_update: false
  EOT

  tags = {
    Name = "${var.name_prefix}-${var.environment}-dmz-app-01"
    Zone = "dmz-apps"
    Role = "dmz-app"
  }
}

# --- Internal app host ---------------------------------------------------
resource "aws_instance" "intapp" {
  count                       = var.enable_workload_hosts ? 1 : 0
  ami                         = var.ami_id
  instance_type               = var.workload_instance_type
  subnet_id                   = var.subnet_ids["internal-apps"]
  vpc_security_group_ids      = [var.intapp_sg_id]
  key_name                    = var.key_name
  associate_public_ip_address = false
  monitoring                  = false

  metadata_options {
    http_endpoint = local.common_metadata.http_endpoint
    http_tokens   = local.common_metadata.http_tokens
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = var.root_volume_size
    encrypted   = true
  }

  user_data = <<-EOT
    #cloud-config
    hostname: ${var.name_prefix}-${var.environment}-intapp-01
    package_update: false
  EOT

  tags = {
    Name = "${var.name_prefix}-${var.environment}-intapp-01"
    Zone = "internal-apps"
    Role = "intapp"
  }
}
