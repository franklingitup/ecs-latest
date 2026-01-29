resource "aws_s3_bucket" "metrics_storage" {
  bucket = "${var.project_name}-metrics-storage-${data.aws_caller_identity.current.account_id}"
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role_policy" "ecs_task_s3_policy" {
  name = "${var.project_name}-s3-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:ListBucket",
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Effect   = "Allow"
        Resource = [
          aws_s3_bucket.metrics_storage.arn,
          "${aws_s3_bucket.metrics_storage.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_ecs_task_definition" "thanos_query" {
  family                   = "${var.project_name}-thanos-query"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "thanos-query"
      image = "thanosio/thanos:v0.32.0"
      args  = [
        "query",
        "--grpc-address=0.0.0.0:10901",
        "--http-address=0.0.0.0:9091",
        "--endpoint=prometheus.local:10901" # Target the sidecar
      ]
      portMappings = [
        {
          containerPort = 9091
          hostPort      = 9091
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.logs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "thanos-query"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "thanos_query" {
  name            = "thanos-query"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.thanos_query.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = local.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.thanos_query.arn
    container_name   = "thanos-query"
    container_port   = 9091
  }

  service_registries {
    registry_arn = aws_service_discovery_service.thanos_query.arn
  }
}

resource "aws_service_discovery_service" "thanos_query" {
  name = "thanos-query"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id
    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_lb_target_group" "thanos_query" {
  name        = "${var.project_name}-thanos-tg"
  port        = 9091
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = local.vpc_id

  health_check {
    path = "/-/healthy"
    matcher = "200"
  }
}

resource "aws_lb_listener" "thanos_query" {
  load_balancer_arn = aws_lb.main.arn
  port              = "9091"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.thanos_query.arn
  }
}
