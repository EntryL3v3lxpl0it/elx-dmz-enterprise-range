module "team_vpc" {
  source = "../../../modules/team-vpc"

  cohort_id         = var.cohort_id
  team_id           = var.team_id
  domain            = var.domain
  vpc_cidr          = "10.101.0.0/16"
  dmz_cidr          = "10.101.10.0/24"
  internal_cidr     = "10.101.20.0/24"
  monitor_cidr      = "10.101.30.0/24"
  availability_zone = "${var.aws_region}a"
  expires_at        = var.expires_at
}

module "dmz_server" {
  source = "../../../modules/dmz-server"

  cohort_id           = var.cohort_id
  team_id             = var.team_id
  domain              = var.domain
  expires_at          = var.expires_at
  vpc_id              = module.team_vpc.vpc_id
  dmz_subnet_id       = module.team_vpc.dmz_subnet_id
  student_source_cidr = var.student_source_cidr
  ami_id              = var.ami_id
  ssh_key_name        = var.ssh_key_name
  instance_type       = var.dmz_instance_type
}
