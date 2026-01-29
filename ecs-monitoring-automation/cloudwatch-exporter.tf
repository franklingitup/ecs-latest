resource "aws_ecs_task_definition" "cloudwatch_exporter" {
  family                   = "${var.project_name}-cw-exporter"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "cloudwatch-exporter"
      image = var.cloudwatch_exporter_image
      portMappings = [
        {
          containerPort = 9106
          hostPort      = 9106
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.logs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "cw-exporter"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "cloudwatch_exporter" {
  name            = "cloudwatch-exporter"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.cloudwatch_exporter.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = local.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.cloudwatch_exporter.arn
  }
}

resource "aws_service_discovery_service" "cloudwatch_exporter" {
  name = "cloudwatch-exporter"

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
