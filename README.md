# opda-shared-infra

Reusable Terraform modules for OPDA API deployments. Per-API repos reference these via native Terraform git source — no submodules needed.

## Modules

| Module | Purpose |
|---|---|
| `modules/vpc` | VPC, public/private subnets, IGW, NAT gateway, all VPC endpoints |
| `modules/mtls-proxy` | ECS Fargate mTLS proxy, NLB, Route53, SSM cert parameters |
| `modules/authorizer` | Lambda authorizer container, IAM role, VPC security group |
| `modules/api-gateway` | Private REST API Gateway, deployment, stage, access logging |

## How to use from a per-API repo

Reference modules by git source with a pinned tag:

```hcl
module "vpc" {
  source = "git::https://github.com/tris/opda-shared-infra.git//modules/vpc?ref=v1.0.0"

  name                 = "opda-lr-facade"
  availability_zones   = ["eu-west-2a", "eu-west-2b"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
}

module "api_gateway" {
  source = "git::https://github.com/tris/opda-shared-infra.git//modules/api-gateway?ref=v1.0.0"

  name                        = "opda-lr-facade"
  openapi_body                = templatefile("${path.module}/openapi/api.yml", { ... })
  execute_api_vpc_endpoint_id = module.vpc.execute_api_vpc_endpoint_id
}

module "authorizer" {
  source = "git::https://github.com/tris/opda-shared-infra.git//modules/authorizer?ref=v1.0.0"

  name                           = "opda-lr-facade"
  image_uri                      = "<account>.dkr.ecr.eu-west-2.amazonaws.com/opda-shared-services:authorizer-1.0.0"
  vpc_id                         = module.vpc.vpc_id
  private_subnet_ids             = module.vpc.private_subnet_ids
  vpc_endpoints_security_group_id = module.vpc.vpc_endpoints_security_group_id
  alb_authentication_issuer      = var.alb_authentication_issuer
  client_id                      = var.client_id
  ssm_transport_certificate_name = module.mtls_proxy.ssm_transport_certificate_name
  ssm_transport_key_name         = module.mtls_proxy.ssm_transport_key_name
  ssm_ca_trusted_list_name       = module.mtls_proxy.ssm_ca_trusted_list_name
  ssm_transport_certificate_arn  = module.mtls_proxy.ssm_transport_certificate_arn
  ssm_transport_key_arn          = module.mtls_proxy.ssm_transport_key_arn
  ssm_ca_trusted_list_arn        = module.mtls_proxy.ssm_ca_trusted_list_arn
  api_execution_arn              = module.api_gateway.execution_arn
}

module "mtls_proxy" {
  source = "git::https://github.com/tris/opda-shared-infra.git//modules/mtls-proxy?ref=v1.0.0"

  name                            = "opda-lr-facade"
  image_uri                       = "<account>.dkr.ecr.eu-west-2.amazonaws.com/opda-shared-services:mtls-1.0.0"
  vpc_id                          = module.vpc.vpc_id
  public_subnet_ids               = module.vpc.public_subnet_ids
  private_subnet_ids              = module.vpc.private_subnet_ids
  vpc_endpoints_security_group_id = module.vpc.vpc_endpoints_security_group_id
  api_invoke_url                  = module.api_gateway.invoke_url
  transport_certificate           = var.transport_certificate
  transport_key                   = var.transport_key
  ca_trusted_list                 = var.ca_trusted_list
  external_domain_name            = var.external_domain_name
  external_hosted_zone_id         = var.external_hosted_zone_id
}
```

## Module reference

### `modules/vpc`

**Key inputs:** `name`, `cidr` (default `10.0.0.0/16`), `availability_zones`, `public_subnet_cidrs`, `private_subnet_cidrs`

**Outputs:** `vpc_id`, `public_subnet_ids`, `private_subnet_ids`, `vpc_endpoints_security_group_id`, `execute_api_vpc_endpoint_id`

Creates VPC endpoints for: S3 (gateway), execute-api, SSM, SSM Messages, KMS, ECR API, ECR DKR, CloudWatch Logs.

---

### `modules/mtls-proxy`

**Key inputs:** `name`, `image_uri`, `vpc_id`, `public_subnet_ids`, `private_subnet_ids`, `vpc_endpoints_security_group_id`, `api_invoke_url`, `transport_certificate`, `transport_key`, `ca_trusted_list`, `external_domain_name`, `external_hosted_zone_id`

**Outputs:** `nlb_dns_name`, `ssm_transport_certificate_name`, `ssm_transport_key_name`, `ssm_ca_trusted_list_name` (+ ARN variants)

Stores the transport certificate, key, and CA trusted list in SSM. Creates a Route53 CNAME at `matls-<name>.<external_domain_name>`.

---

### `modules/authorizer`

**Key inputs:** `name`, `image_uri`, `vpc_id`, `private_subnet_ids`, `vpc_endpoints_security_group_id`, `alb_authentication_issuer`, `client_id`, SSM param names + ARNs from mtls-proxy, `api_execution_arn`

**Outputs:** `function_arn`, `function_invoke_arn`, `function_name`

Derives `INTROSPECTION_ENDPOINT` as `${alb_authentication_issuer}/token/introspection`. The `CLIENT_CERT_HEADER` is hardcoded to `Tls-Certificate` (the header the mTLS proxy injects).

---

### `modules/api-gateway`

**Key inputs:** `name`, `openapi_body` (pre-rendered OpenAPI with Lambda ARNs substituted), `execute_api_vpc_endpoint_id`, `stage_name` (default `v1`)

**Outputs:** `api_id`, `execution_arn`, `invoke_url`

The resource policy restricts invocation to traffic arriving via the execute-api VPC endpoint. Deployment is triggered automatically when `openapi_body` changes.
