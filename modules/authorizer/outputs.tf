output "function_arn" {
  description = "ARN of the authorizer Lambda function"
  value       = aws_lambda_function.authorizer.arn
}

output "function_invoke_arn" {
  description = "Invoke ARN of the authorizer Lambda (used in API GW OpenAPI integration)"
  value       = aws_lambda_function.authorizer.invoke_arn
}

output "function_name" {
  description = "Name of the authorizer Lambda function"
  value       = aws_lambda_function.authorizer.function_name
}
