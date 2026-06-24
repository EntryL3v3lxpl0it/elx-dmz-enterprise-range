output "vpc_id" {
  value = module.network.vpc_id
}

output "subnet_ids" {
  value = module.network.subnet_ids
}

output "gateway_public_ip" {
  description = "WireGuard endpoint / admin SSH target."
  value       = module.compute.gateway_public_ip
}

output "gateway_private_ip" {
  value = module.compute.gateway_private_ip
}

output "dmz_app_private_ip" {
  value = module.compute.dmz_app_private_ip
}

output "intapp_private_ip" {
  value = module.compute.intapp_private_ip
}

output "budget_name" {
  value = module.budget.budget_name
}

output "next_steps" {
  value = <<-EOT
    Foundation applied. Next:
      1. Configure WireGuard + package proxy on the gateway (Ansible, Phase 1b).
      2. Set enable_provisioning_egress = true ONLY while provisioning private hosts, then back to false.
      3. terraform destroy when the lab session ends (ephemeral posture, A-10).
  EOT
}
