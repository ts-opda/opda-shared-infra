data "aws_region" "current" {}

# ─── IAM ─────────────────────────────────────────────────────────────────────

resource "aws_iam_role" "lambda" {
  name = "${var.name}-facade-authorizer-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy" "lambda_ssm" {
  name = "${var.name}-facade-authorizer-ssm-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowReadCertParams"
      Effect = "Allow"
      Action = ["ssm:GetParameter", "ssm:GetParameters"]
      Resource = [
        var.ssm_transport_certificate_arn,
        var.ssm_transport_key_arn,
        var.ssm_ca_trusted_list_arn,
      ]
    }]
  })
}

# ─── Security Group ──────────────────────────────────────────────────────────

resource "aws_security_group" "lambda" {
  name        = "${var.name}-facade-authorizer-sg"
  description = "Controls outbound access for the authorizer Lambda"
  vpc_id      = var.vpc_id

  egress {
    description     = "HTTPS to VPC endpoints (for SSM and introspection)"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [var.vpc_endpoints_security_group_id]
  }

  egress {
    description = "HTTPS to internet (for OAuth2 introspection endpoint)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-facade-authorizer-sg" })
}

# ─── CloudWatch Log Group ────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.name}-facade-authorizer"
  retention_in_days = 30

  tags = var.tags
}

# ─── Lambda Function ─────────────────────────────────────────────────────────

resource "aws_lambda_function" "authorizer" {
  function_name = "${var.name}-facade-authorizer"
  role          = aws_iam_role.lambda.arn
  package_type  = "Image"
  image_uri     = var.image_uri
  architectures = ["arm64"]
  memory_size   = var.memory_size
  timeout       = var.timeout

  reserved_concurrent_executions = var.reserved_concurrent_executions

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      INTROSPECTION_ENDPOINT         = "${var.alb_authentication_issuer}/token/introspection"
      CLIENT_ID                      = var.client_id
      CLIENT_CERT_HEADER             = "Tls-Certificate"
      SSM_TRANSPORT_KEY_NAME         = var.ssm_transport_key_name
      SSM_TRANSPORT_CERTIFICATE_NAME = var.ssm_transport_certificate_name
      SSM_CA_TRUSTED_LIST_NAME       = var.ssm_ca_trusted_list_name
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda]

  tags = var.tags
}

# ─── Lambda Permission ───────────────────────────────────────────────────────

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.authorizer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_execution_arn}/*/*"
}
