data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  ssm_base_path = "/${var.name}"
}

# ─── SSM Parameters ──────────────────────────────────────────────────────────

resource "aws_ssm_parameter" "transport_certificate" {
  name  = "${local.ssm_base_path}/transport_certificate"
  type  = "String"
  value = var.transport_certificate

  tags = var.tags
}

resource "aws_ssm_parameter" "transport_key" {
  name  = "${local.ssm_base_path}/transport_key"
  type  = "SecureString"
  value = var.transport_key

  tags = var.tags
}

resource "aws_ssm_parameter" "ca_trusted_list" {
  name  = "${local.ssm_base_path}/ca_trusted_list"
  type  = "String"
  value = var.ca_trusted_list
  tier  = "Intelligent-Tiering"

  tags = var.tags
}

# ─── NLB ─────────────────────────────────────────────────────────────────────

resource "aws_security_group" "nlb" {
  name        = "${var.name}-nlb-sg"
  description = "Allow external HTTPS to the NLB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-nlb-sg" })
}

resource "aws_lb" "main" {
  name               = "${var.name}-facade"
  load_balancer_type = "network"
  subnets            = var.public_subnet_ids
  security_groups    = [aws_security_group.nlb.id]
  internal           = false

  tags = var.tags
}

resource "aws_lb_target_group" "mtls" {
  name        = "${var.name}-mtls-tg"
  port        = var.container_port
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path     = "/health"
    protocol = "HTTPS"
    port     = "traffic-port"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mtls.arn
  }
}

# ─── ECS ─────────────────────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.name}-mtls"
  retention_in_days = 30

  tags = var.tags
}

resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_ssm" {
  name = "${var.name}-ecs-ssm-policy"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowReadCertParams"
      Effect = "Allow"
      Action = ["ssm:GetParameter", "ssm:GetParameters"]
      Resource = [
        aws_ssm_parameter.transport_key.arn,
        aws_ssm_parameter.transport_certificate.arn,
        aws_ssm_parameter.ca_trusted_list.arn,
      ]
    }]
  })
}

resource "aws_iam_role_policy" "ecs_apigw" {
  name = "${var.name}-ecs-apigw-policy"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowInvokeApiGw"
      Effect = "Allow"
      Action = ["execute-api:Invoke"]
      Resource = [
        "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*/*/*"
      ]
    }]
  })
}

resource "aws_security_group" "ecs" {
  name        = "${var.name}-ecs-sg"
  description = "Controls access to the Fargate mTLS proxy service"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [var.vpc_endpoints_security_group_id]
  }

  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [var.vpc_endpoints_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-ecs-sg" })
}

resource "aws_ecs_cluster" "main" {
  name = "${var.name}-cluster"

  tags = var.tags
}

resource "aws_ecs_task_definition" "main" {
  family                   = "${var.name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([{
    name      = "${var.name}-container"
    image     = var.image_uri
    essential = true

    portMappings = [{
      containerPort = var.container_port
      hostPort      = var.container_port
    }]

    environment = [
      { name = "PROXY_HOST_TARGET",              value = var.api_invoke_url },
      { name = "REGION",                         value = data.aws_region.current.name },
      { name = "SSM_TRANSPORT_KEY_NAME",         value = aws_ssm_parameter.transport_key.name },
      { name = "SSM_TRANSPORT_CERTIFICATE_NAME", value = aws_ssm_parameter.transport_certificate.name },
      { name = "SSM_CA_TRUSTED_LIST_NAME",       value = aws_ssm_parameter.ca_trusted_list.name },
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

resource "aws_ecs_service" "main" {
  name            = "${var.name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [aws_security_group.ecs.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.mtls.arn
    container_name   = "${var.name}-container"
    container_port   = var.container_port
  }

  depends_on = [aws_lb_listener.main]
}

# ─── Route53 ─────────────────────────────────────────────────────────────────

resource "aws_route53_record" "mtls" {
  count   = var.external_hosted_zone_id != "" && var.external_domain_name != "" ? 1 : 0

  name    = "matls-${var.name}.${var.external_domain_name}"
  type    = "CNAME"
  zone_id = var.external_hosted_zone_id
  ttl     = 60
  records = [aws_lb.main.dns_name]
}
