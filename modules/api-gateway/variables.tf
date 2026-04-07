variable "name" {
  type        = string
  description = "Prefix applied to all resources"
}

variable "tags" {
  type        = map(string)
  description = "Tags to add to all resources"
  default     = {}
}

variable "openapi_body" {
  type        = string
  description = "Rendered OpenAPI 3.0 specification for the API (Lambda ARNs already substituted by the caller)"
}

variable "stage_name" {
  type        = string
  description = "API Gateway stage name"
  default     = "v1"
}

variable "execute_api_vpc_endpoint_id" {
  type        = string
  description = "ID of the execute-api VPC endpoint — used to scope the private API resource policy"
}

variable "access_log_retention_days" {
  type        = number
  description = "Retention period for API GW access logs in days"
  default     = 90
}
