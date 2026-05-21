output "endpoint" {
  description = "Public mTLS endpoint URL (e.g. https://dev.api.smartpropdata.org.uk)"
  value       = local.endpoint
}

output "nlb_dns_name" {
  description = "Raw NLB DNS name"
  value       = aws_lb.main.dns_name
}

output "ssm_ca_trusted_list_name" {
  description = "SSM parameter name for the CA trusted list"
  value       = aws_ssm_parameter.ca_trusted_list.name
}

output "ssm_ca_trusted_list_arn" {
  description = "ARN of the CA trusted list SSM parameter"
  value       = aws_ssm_parameter.ca_trusted_list.arn
}
