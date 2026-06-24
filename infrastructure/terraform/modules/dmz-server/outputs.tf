output "instance_id" {
  value = aws_instance.dmz_web.id
}

output "public_ip" {
  value = aws_instance.dmz_web.public_ip
}

output "private_ip" {
  value = aws_instance.dmz_web.private_ip
}

output "security_group_id" {
  value = aws_security_group.dmz_web.id
}
