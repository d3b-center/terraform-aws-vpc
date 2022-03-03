output "id" {
  value       = aws_vpc.default.id
  description = "ID of the VPC."
}

output "public_subnet_ids" {
  value       = aws_subnet.public.*.id
  description = "A list of VPC public subnet IDs."
}

output "private_subnet_ids" {
  value       = aws_subnet.private.*.id
  description = "A list of VPC private subnet IDs."
}

output "vpc_endpoint_security_group_id" {
  value       = aws_security_group.vpc_endpoint.id
  description = "Security group associated with the interface VPC endpoints for adding rules."
}

output "bastion_security_group_id" {
  value       = aws_security_group.bastion.id
  description = "Security group associated with the bastion for adding rules."
}

output "bastion_iam_role_name" {
  value       = aws_iam_role.bastion.name
  description = "IAM role associated with the bastion for attaching IAM policies."
}

output "cidr_block" {
  value       = var.cidr_block
  description = "The CIDR range for the entire VPC."
}

output "ipv6_cidr_block" {
  value       = aws_vpc.default.ipv6_cidr_block
  description = "The IPv6 CIDR range for the entire VPC."
}

output "nat_gateway_ips" {
  value       = [aws_eip.nat.*.public_ip]
  description = "Public IP addresses of the VPC NAT gateways."
}
