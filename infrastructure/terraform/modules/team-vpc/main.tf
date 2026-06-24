resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name         = "${var.team_id}-vpc"
    Project      = var.project
    CohortID     = var.cohort_id
    TeamID       = var.team_id
    Domain       = var.domain
    ExpiresAt    = var.expires_at
    ManagedBy    = "terraform"
    RuntimeModel = "on-demand"
  }
}

resource "aws_subnet" "dmz" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.dmz_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name         = "${var.team_id}-dmz"
    Project      = var.project
    CohortID     = var.cohort_id
    TeamID       = var.team_id
    Domain       = var.domain
    ExpiresAt    = var.expires_at
    ManagedBy    = "terraform"
    RuntimeModel = "on-demand"
  }
}

resource "aws_subnet" "internal" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.internal_cidr
  availability_zone = var.availability_zone

  tags = {
    Name         = "${var.team_id}-internal"
    Project      = var.project
    CohortID     = var.cohort_id
    TeamID       = var.team_id
    Domain       = var.domain
    ExpiresAt    = var.expires_at
    ManagedBy    = "terraform"
    RuntimeModel = "on-demand"
  }
}

resource "aws_subnet" "monitor" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.monitor_cidr
  availability_zone = var.availability_zone

  tags = {
    Name         = "${var.team_id}-monitor"
    Project      = var.project
    CohortID     = var.cohort_id
    TeamID       = var.team_id
    Domain       = var.domain
    ExpiresAt    = var.expires_at
    ManagedBy    = "terraform"
    RuntimeModel = "on-demand"
  }
}
