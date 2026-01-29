resource "aws_ecs_task_definition" "alertmanager" {
  family                   = "${var.project_name}-alertmanager"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "alertmanager"
      image = var.alertmanager_image
      portMappings = [
        {
          containerPort = 9093
          hostPort      = 9093
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.logs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "alertmanager"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "alertmanager" {
  name            = "alertmanager"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.alertmanager.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = local.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.alertmanager.arn
    container_name   = "alertmanager"
    container_port   = 9093
  }
}

resource "aws_lb_target_group" "alertmanager" {
  name        = "${var.project_name}-alert-tg"
  port        = 9093
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = local.vpc_id

  health_check {
    path = "/-/healthy"
    matcher = "200"
  }
}

resource "aws_lb_listener" "alertmanager" {
  load_balancer_arn = aws_lb.main.arn
  port              = "9093"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alertmanager.arn
  }
}
