# ---------------------------------------------------------------------------
# Deny-by-default security groups. Each SG starts with NO rules; only the
# explicitly justified flows below are added. No rule uses 0.0.0.0/0 ingress.
# Only the gateway has open egress (it is the controlled internet edge).
# ---------------------------------------------------------------------------

# === Gateway (edge): WireGuard ingress, admin SSH, controlled egress ===
resource "aws_security_group" "gateway" {
  name        = "${var.name_prefix}-${var.environment}-sg-gateway"
  description = "Edge gateway: WireGuard ingress, admin SSH, package proxy, internet egress."
  vpc_id      = var.vpc_id
  tags        = { Name = "${var.name_prefix}-${var.environment}-sg-gateway", Zone = "public-edge" }
}

resource "aws_vpc_security_group_ingress_rule" "gw_wireguard" {
  for_each          = toset(var.allowed_ingress_cidrs)
  security_group_id = aws_security_group.gateway.id
  description       = "WireGuard from allowlist"
  cidr_ipv4         = each.value
  ip_protocol       = "udp"
  from_port         = var.wireguard_port
  to_port           = var.wireguard_port
}

resource "aws_vpc_security_group_ingress_rule" "gw_ssh" {
  for_each          = toset(var.allowed_ingress_cidrs)
  security_group_id = aws_security_group.gateway.id
  description       = "Admin SSH from allowlist"
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

# Private hosts reach the gateway proxy ONLY when provisioning egress is enabled.
resource "aws_vpc_security_group_ingress_rule" "gw_proxy" {
  count             = var.enable_provisioning_egress ? 1 : 0
  security_group_id = aws_security_group.gateway.id
  description       = "Package/cache proxy from inside the VPC (provisioning only)"
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "tcp"
  from_port         = var.proxy_port
  to_port           = var.proxy_port
}

resource "aws_vpc_security_group_egress_rule" "gw_all" {
  security_group_id = aws_security_group.gateway.id
  description       = "Controlled internet egress (edge)"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# === DMZ app host: vulnerable web app + reverse proxy (private) ===
resource "aws_security_group" "dmz_app" {
  name        = "${var.name_prefix}-${var.environment}-sg-dmz-app"
  description = "DMZ application host (intentionally vulnerable, lab-only)."
  vpc_id      = var.vpc_id
  tags        = { Name = "${var.name_prefix}-${var.environment}-sg-dmz-app", Zone = "dmz-apps" }
}

# Students reach DMZ web ports over the VPN tunnel.
resource "aws_vpc_security_group_ingress_rule" "dmz_http_tunnel" {
  for_each          = toset(["80", "443"])
  security_group_id = aws_security_group.dmz_app.id
  description       = "HTTP/S from WireGuard client subnet"
  cidr_ipv4         = var.wireguard_client_cidr
  ip_protocol       = "tcp"
  from_port         = tonumber(each.value)
  to_port           = tonumber(each.value)
}

resource "aws_vpc_security_group_ingress_rule" "dmz_ssh_admin" {
  security_group_id            = aws_security_group.dmz_app.id
  description                  = "Admin SSH from gateway only"
  referenced_security_group_id = aws_security_group.gateway.id
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
}

resource "aws_vpc_security_group_egress_rule" "dmz_to_intapp" {
  for_each                     = toset([for p in var.dmz_to_intapp_ports : tostring(p)])
  security_group_id            = aws_security_group.dmz_app.id
  description                  = "DMZ app to internal app/db backend"
  referenced_security_group_id = aws_security_group.intapp.id
  ip_protocol                  = "tcp"
  from_port                    = tonumber(each.value)
  to_port                      = tonumber(each.value)
}

resource "aws_vpc_security_group_egress_rule" "dmz_dns" {
  security_group_id = aws_security_group.dmz_app.id
  description       = "DNS to VPC resolver"
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "udp"
  from_port         = 53
  to_port           = 53
}

resource "aws_vpc_security_group_egress_rule" "dmz_s3" {
  count             = var.enable_s3_egress_rules ? 1 : 0
  security_group_id = aws_security_group.dmz_app.id
  description       = "HTTPS to S3 gateway endpoint"
  prefix_list_id    = var.s3_prefix_list_id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "dmz_proxy" {
  count                        = var.enable_provisioning_egress ? 1 : 0
  security_group_id            = aws_security_group.dmz_app.id
  description                  = "Package proxy to gateway (provisioning only)"
  referenced_security_group_id = aws_security_group.gateway.id
  ip_protocol                  = "tcp"
  from_port                    = var.proxy_port
  to_port                      = var.proxy_port
}

# === Internal app host: internal service + DB + lightweight collector ===
resource "aws_security_group" "intapp" {
  name        = "${var.name_prefix}-${var.environment}-sg-intapp"
  description = "Internal application host (service, DB, lightweight log collector)."
  vpc_id      = var.vpc_id
  tags        = { Name = "${var.name_prefix}-${var.environment}-sg-intapp", Zone = "internal-apps" }
}

resource "aws_vpc_security_group_ingress_rule" "intapp_from_dmz" {
  for_each                     = toset([for p in var.dmz_to_intapp_ports : tostring(p)])
  security_group_id            = aws_security_group.intapp.id
  description                  = "Backend access from DMZ app host"
  referenced_security_group_id = aws_security_group.dmz_app.id
  ip_protocol                  = "tcp"
  from_port                    = tonumber(each.value)
  to_port                      = tonumber(each.value)
}

resource "aws_vpc_security_group_ingress_rule" "intapp_ssh_admin" {
  security_group_id            = aws_security_group.intapp.id
  description                  = "Admin SSH from gateway only"
  referenced_security_group_id = aws_security_group.gateway.id
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
}

resource "aws_vpc_security_group_egress_rule" "intapp_dns" {
  security_group_id = aws_security_group.intapp.id
  description       = "DNS to VPC resolver"
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "udp"
  from_port         = 53
  to_port           = 53
}

resource "aws_vpc_security_group_egress_rule" "intapp_s3" {
  count             = var.enable_s3_egress_rules ? 1 : 0
  security_group_id = aws_security_group.intapp.id
  description       = "HTTPS to S3 gateway endpoint"
  prefix_list_id    = var.s3_prefix_list_id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "intapp_proxy" {
  count                        = var.enable_provisioning_egress ? 1 : 0
  security_group_id            = aws_security_group.intapp.id
  description                  = "Package proxy to gateway (provisioning only)"
  referenced_security_group_id = aws_security_group.gateway.id
  ip_protocol                  = "tcp"
  from_port                    = var.proxy_port
  to_port                      = var.proxy_port
}
