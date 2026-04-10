variable "name" {
  type        = string
  description = "Prefix applied to all resources"
}

variable "tags" {
  type        = map(string)
  description = "Tags to add to all resources"
  default     = {}
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for the Lambda VPC config"
}

variable "vpc_endpoints_security_group_id" {
  type        = string
  description = "Security group ID attached to VPC interface endpoints"
}

variable "image_uri" {
  type        = string
  description = "Full ECR image URI for the authorizer Lambda container"
}

variable "alb_authentication_issuer" {
  type        = string
  description = "OAuth2 issuer URL (no trailing slash). Used to derive the introspection endpoint."

  validation {
    condition     = !endswith(var.alb_authentication_issuer, "/")
    error_message = "alb_authentication_issuer must not have a trailing slash"
  }
}

variable "client_id" {
  type        = string
  description = "OAuth2 client ID registered with the authorisation server"
}

variable "ssm_transport_certificate_name" {
  type        = string
  description = "SSM parameter name for the transport certificate PEM"
}

variable "ssm_transport_key_name" {
  type        = string
  description = "SSM parameter name for the transport key PEM"
}

variable "ssm_ca_trusted_list_name" {
  type        = string
  description = "SSM parameter name for the CA trusted list PEM bundle"
}

variable "ssm_transport_certificate_arn" {
  type        = string
  description = "ARN of the transport certificate SSM parameter (for IAM policy)"
}

variable "ssm_transport_key_arn" {
  type        = string
  description = "ARN of the transport key SSM parameter (for IAM policy)"
}

variable "ssm_ca_trusted_list_arn" {
  type        = string
  description = "ARN of the CA trusted list SSM parameter (for IAM policy)"
}

variable "api_execution_arn" {
  type        = string
  description = "Execution ARN of the API Gateway (used to scope the Lambda invoke permission)"
}

variable "memory_size" {
  type        = number
  description = "Lambda memory in MB"
  default     = 128
}

variable "timeout" {
  type        = number
  description = "Lambda timeout in seconds"
  default     = 30
}

variable "reserved_concurrent_executions" {
  type        = number
  description = "Reserved concurrent executions for the Lambda (-1 for unreserved)"
  default     = -1
}
