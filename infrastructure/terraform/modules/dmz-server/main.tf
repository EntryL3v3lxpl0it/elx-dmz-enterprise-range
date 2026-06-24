resource "aws_security_group" "dmz_web" {
  name        = "${var.team_id}-dmz-web-sg"
  description = "DMZ web server security group for ELX training range"
  vpc_id      = var.vpc_id

  tags = {
    Name         = "${var.team_id}-dmz-web-sg"
    Project      = var.project
    CohortID     = var.cohort_id
    TeamID       = var.team_id
    Domain       = var.domain
    ExpiresAt    = var.expires_at
    ManagedBy    = "terraform"
    RuntimeModel = "on-demand"
  }
}

resource "aws_vpc_security_group_ingress_rule" "http_from_student" {
  security_group_id = aws_security_group.dmz_web.id
  cidr_ipv4         = var.student_source_cidr
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
  description       = "Temporary MVP HTTP access from authorized student/instructor source"
}

resource "aws_vpc_security_group_ingress_rule" "ssh_from_student" {
  security_group_id = aws_security_group.dmz_web.id
  cidr_ipv4         = var.student_source_cidr
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
  description       = "Temporary MVP SSH access from authorized instructor source"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_egress_mvp" {
  security_group_id = aws_security_group.dmz_web.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Temporary MVP egress for package installation; restrict later"
}

resource "aws_instance" "dmz_web" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.dmz_subnet_id
  vpc_security_group_ids      = [aws_security_group.dmz_web.id]
  associate_public_ip_address = true
  key_name                    = var.ssh_key_name

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name         = "dmz-web.${var.domain}"
    Project      = var.project
    CohortID     = var.cohort_id
    TeamID       = var.team_id
    Domain       = var.domain
    ExpiresAt    = var.expires_at
    ManagedBy    = "terraform"
    RuntimeModel = "on-demand"
    Role         = "dmz-web"
  }
}
