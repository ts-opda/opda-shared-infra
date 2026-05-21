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

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs for the NLB"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for the ECS service"
}

variable "vpc_endpoints_security_group_id" {
  type        = string
  description = "Security group ID attached to VPC interface endpoints"
}

variable "image_uri" {
  type        = string
  description = "Full ECR image URI for the mTLS proxy container"
}

variable "routes_ssm_path" {
  type        = string
  description = "SSM path prefix for GetParametersByPath route discovery (e.g. /opda/proxy/routes/)"
}

variable "ca_trusted_list" {
  type        = string
  description = "PEM bundle of CAs trusted for inbound client cert verification"
}

variable "server_tls_certificate" {
  type        = string
  description = "PEM certificate (fullchain) for inbound server TLS — must be from a publicly-trusted CA"
}

variable "server_tls_key" {
  type        = string
  description = "PEM private key matching server_tls_certificate"
  sensitive   = true
}

variable "external_hostname" {
  type        = string
  description = "Hostname label for the Route53 record (e.g. 'dev' produces dev.<external_domain_name>)"
}

variable "external_domain_name" {
  type        = string
  description = "Base domain name (e.g. api.smartpropdata.org.uk)"
}

variable "external_hosted_zone_id" {
  type        = string
  description = "Route53 hosted zone ID for external_domain_name"
}

variable "container_port" {
  type        = number
  description = "Port the mTLS proxy container listens on"
  default     = 443
}

variable "cpu" {
  type        = number
  description = "CPU units for the Fargate task"
  default     = 256
}

variable "memory" {
  type        = number
  description = "Memory (MiB) for the Fargate task"
  default     = 512
}
