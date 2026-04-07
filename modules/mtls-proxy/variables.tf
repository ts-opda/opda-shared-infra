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
  description = "Full ECR image URI for the mTLS proxy container (e.g. 123456789012.dkr.ecr.eu-west-2.amazonaws.com/opda-shared-services:mtls-1.0.0)"
}

variable "api_invoke_url" {
  type        = string
  description = "The invoke URL of the private API Gateway (set as PROXY_HOST_TARGET)"
}

variable "transport_certificate" {
  type        = string
  description = "Transport certificate PEM"
}

variable "transport_key" {
  type        = string
  description = "Transport private key PEM"
  sensitive   = true
}

variable "ca_trusted_list" {
  type        = string
  description = "PEM bundle of trusted CAs for mTLS client cert verification"
}

variable "external_domain_name" {
  type        = string
  description = "Base domain name; a Route53 CNAME record will be created at matls-<name>.<domain>"
}

variable "external_hosted_zone_id" {
  type        = string
  description = "Route53 hosted zone ID to create the CNAME record in"
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
