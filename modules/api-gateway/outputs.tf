output "api_id" {
  description = "ID of the REST API"
  value       = aws_api_gateway_rest_api.main.id
}

output "execution_arn" {
  description = "Execution ARN of the REST API (used to scope Lambda invoke permissions)"
  value       = aws_api_gateway_rest_api.main.execution_arn
}

output "invoke_url" {
  description = "Invoke URL for the deployed stage (set as PROXY_HOST_TARGET on the mTLS proxy)"
  value       = aws_api_gateway_stage.main.invoke_url
}
