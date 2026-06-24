# ---------------------------------------------------------------------------
# team1 environment: composes network + security-groups + compute + budget
# into one minimal, segmented, NAT-less range foundation in us-east-2.
# ---------------------------------------------------------------------------

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "elx-dmz-enterprise-range"
      Environment = var.environment
      Owner       = var.owner
      CostControl = "true"
      ManagedBy   = "terraform"
      Ephemeral   = "true"
    }
  }
}

# Latest Ubuntu 24.04 LTS (Canonical) AMI.
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd*/ubuntu-noble-24.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "admin" {
  key_name   = "${var.name_prefix}-${var.environment}-admin"
  public_key = var.ssh_public_key
  tags       = { Name = "${var.name_prefix}-${var.environment}-admin" }
}

module "network" {
  source = "../../modules/network"

  name_prefix = var.name_prefix
  environment = var.environment
  aws_region  = var.aws_region
  vpc_cidr    = var.vpc_cidr
  az          = var.az
  subnets     = var.subnets

  enable_s3_endpoint       = true
  enable_dynamodb_endpoint = false
}

module "security_groups" {
  source = "../../modules/security-groups"

  name_prefix = var.name_prefix
  environment = var.environment
  vpc_id      = module.network.vpc_id
  vpc_cidr    = module.network.vpc_cidr

  allowed_ingress_cidrs      = var.allowed_ingress_cidrs
  wireguard_client_cidr      = var.wireguard_client_cidr
  s3_prefix_list_id          = module.network.s3_prefix_list_id
  enable_provisioning_egress = var.enable_provisioning_egress
}

module "compute" {
  source = "../../modules/compute"

  name_prefix = var.name_prefix
  environment = var.environment
  ami_id      = data.aws_ami.ubuntu.id
  key_name    = aws_key_pair.admin.key_name
  subnet_ids  = module.network.subnet_ids

  gateway_sg_id = module.security_groups.gateway_sg_id
  dmz_app_sg_id = module.security_groups.dmz_app_sg_id
  intapp_sg_id  = module.security_groups.intapp_sg_id

  gateway_instance_type  = var.gateway_instance_type
  workload_instance_type = var.workload_instance_type
  enable_workload_hosts  = var.enable_workload_hosts
}

module "budget" {
  source = "../../modules/budget"

  name_prefix         = var.name_prefix
  environment         = var.environment
  budget_limit        = "50"
  alert_thresholds    = [50, 80, 100]
  notification_emails = var.budget_notification_emails
}
