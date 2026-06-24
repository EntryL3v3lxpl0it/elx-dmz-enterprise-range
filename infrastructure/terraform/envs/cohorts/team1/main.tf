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
