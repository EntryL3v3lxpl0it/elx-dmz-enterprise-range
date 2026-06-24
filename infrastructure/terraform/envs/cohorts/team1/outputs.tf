output "vpc_id" {
  value = module.team_vpc.vpc_id
}

output "dmz_subnet_id" {
  value = module.team_vpc.dmz_subnet_id
}

output "internal_subnet_id" {
  value = module.team_vpc.internal_subnet_id
}

output "monitor_subnet_id" {
  value = module.team_vpc.monitor_subnet_id
}

output "dmz_web_instance_id" {
  value = module.dmz_server.instance_id
}

output "dmz_web_public_ip" {
  value = module.dmz_server.public_ip
}

output "dmz_web_private_ip" {
  value = module.dmz_server.private_ip
}
