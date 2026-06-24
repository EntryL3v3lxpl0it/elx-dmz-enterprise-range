output "vpc_id" {
  value = aws_vpc.this.id
}

output "vpc_cidr" {
  value = aws_vpc.this.cidr_block
}

output "subnet_ids" {
  description = "Map of zone name -> subnet id."
  value       = { for k, s in aws_subnet.this : k => s.id }
}

output "public_route_table_id" {
  value = aws_route_table.public.id
}

output "private_route_table_id" {
  value = aws_route_table.private.id
}

output "s3_prefix_list_id" {
  description = "S3 gateway endpoint prefix list id (for SG egress rules). Empty if disabled."
  value       = var.enable_s3_endpoint ? aws_vpc_endpoint.s3[0].prefix_list_id : ""
}
