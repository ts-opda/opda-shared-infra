variable "name" {
  type        = string
  description = "Prefix applied to all resources"
}

variable "cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones to create subnets in (at least 2 recommended)"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for public subnets, one per AZ"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for private subnets, one per AZ"
}

variable "tags" {
  type        = map(string)
  description = "Tags to add to all resources"
  default     = {}
}
