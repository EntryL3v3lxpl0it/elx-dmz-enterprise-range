output "gateway_public_ip" {
  description = "Elastic IP of the gateway (WireGuard endpoint / admin SSH)."
  value       = aws_eip.gateway.public_ip
}

output "gateway_private_ip" {
  value = aws_instance.gateway.private_ip
}

output "dmz_app_private_ip" {
  value = var.enable_workload_hosts ? aws_instance.dmz_app[0].private_ip : null
}

output "intapp_private_ip" {
  value = var.enable_workload_hosts ? aws_instance.intapp[0].private_ip : null
}

output "instance_ids" {
  value = compact(concat(
    [aws_instance.gateway.id],
    var.enable_workload_hosts ? [aws_instance.dmz_app[0].id, aws_instance.intapp[0].id] : []
  ))
}
