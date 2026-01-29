resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = local.public_subnet_ids
}

output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "prometheus_url" {
  value = "http://${aws_lb.main.dns_name}:9090"
}

output "grafana_url" {
  value = "http://${aws_lb.main.dns_name}:3000"
}
