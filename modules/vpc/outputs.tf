output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "vpc_endpoints_security_group_id" {
  description = "ID of the security group attached to all VPC interface endpoints"
  value       = aws_security_group.vpc_endpoints.id
}

output "execute_api_vpc_endpoint_id" {
  description = "ID of the execute-api VPC endpoint (needed for private API GW resource policy)"
  value       = aws_vpc_endpoint.execute_api.id
}
