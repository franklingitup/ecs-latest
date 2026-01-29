resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

# Cloudwatch Log Group
resource "aws_cloudwatch_log_group" "logs" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7
}

resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "local"
  description = "Service discovery for monitoring stack"
  vpc         = local.vpc_id
}
