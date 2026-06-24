output "vpc_id" {
  value = aws_vpc.this.id
}

output "dmz_subnet_id" {
  value = aws_subnet.dmz.id
}

output "internal_subnet_id" {
  value = aws_subnet.internal.id
}

output "monitor_subnet_id" {
  value = aws_subnet.monitor.id
}
