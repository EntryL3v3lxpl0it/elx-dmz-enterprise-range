output "vpc_id" {
  value = aws_vpc.this.id
}

output "vpc_cidr" {
  value = aws_vpc.this.cidr_block
}

output "dmz_subnet_id" {
  value = aws_subnet.dmz.id
}

output "dmz_cidr" {
  value = aws_subnet.dmz.cidr_block
}

output "internal_subnet_id" {
  value = aws_subnet.internal.id
}

output "monitor_subnet_id" {
  value = aws_subnet.monitor.id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.this.id
}
