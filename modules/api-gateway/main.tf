data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ─── CloudWatch Logs ─────────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "access_logs" {
  name              = "/aws/apigateway/${var.name}-facade-access-logs"
  retention_in_days = var.access_log_retention_days

  tags = var.tags
}

# IAM role allowing API GW to write to CloudWatch Logs
resource "aws_iam_role" "api_gw_logging" {
  name = "${var.name}-facade-apigw-logging-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "apigateway.amazonaws.com" }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "api_gw_logging" {
  role       = aws_iam_role.api_gw_logging.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_api_gateway_account" "main" {
  cloudwatch_role_arn = aws_iam_role.api_gw_logging.arn
}

# ─── REST API ─────────────────────────────────────────────────────────────────

resource "aws_api_gateway_rest_api" "main" {
  name = "${var.name}-facade"
  body = var.openapi_body

  endpoint_configuration {
    types            = ["PRIVATE"]
    vpc_endpoint_ids = [var.execute_api_vpc_endpoint_id]
  }

  # Resource policy: allow invocations arriving via the VPC endpoint only
  policy = data.aws_iam_policy_document.api_resource_policy.json

  tags = var.tags
}

data "aws_iam_policy_document" "api_resource_policy" {
  statement {
    sid    = "AllowVpcEndpointInvoke"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions   = ["execute-api:Invoke"]
    resources = ["arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*/*/*/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceVpce"
      values   = [var.execute_api_vpc_endpoint_id]
    }
  }
}

# ─── Deployment & Stage ──────────────────────────────────────────────────────

resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  # Re-deploy whenever the OpenAPI body changes
  triggers = {
    redeployment = sha256(var.openapi_body)
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "main" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  deployment_id = aws_api_gateway_deployment.main.id
  stage_name    = var.stage_name

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.access_logs.arn
  }

  depends_on = [aws_api_gateway_account.main]

  tags = var.tags
}
