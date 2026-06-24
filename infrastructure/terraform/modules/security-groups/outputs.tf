output "gateway_sg_id" {
  value = aws_security_group.gateway.id
}

output "dmz_app_sg_id" {
  value = aws_security_group.dmz_app.id
}

output "intapp_sg_id" {
  value = aws_security_group.intapp.id
}
