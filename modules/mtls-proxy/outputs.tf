output "nlb_dns_name" {
  description = "DNS name of the NLB (also registered in Route53)"
  value       = aws_lb.main.dns_name
}

output "ssm_transport_certificate_name" {
  description = "SSM parameter name for the transport certificate"
  value       = aws_ssm_parameter.transport_certificate.name
}

output "ssm_transport_key_name" {
  description = "SSM parameter name for the transport key"
  value       = aws_ssm_parameter.transport_key.name
}

output "ssm_ca_trusted_list_name" {
  description = "SSM parameter name for the CA trusted list"
  value       = aws_ssm_parameter.ca_trusted_list.name
}

output "ssm_transport_certificate_arn" {
  description = "ARN of the transport certificate SSM parameter"
  value       = aws_ssm_parameter.transport_certificate.arn
}

output "ssm_transport_key_arn" {
  description = "ARN of the transport key SSM parameter"
  value       = aws_ssm_parameter.transport_key.arn
}

output "ssm_ca_trusted_list_arn" {
  description = "ARN of the CA trusted list SSM parameter"
  value       = aws_ssm_parameter.ca_trusted_list.arn
}
