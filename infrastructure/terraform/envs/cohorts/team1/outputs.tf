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
