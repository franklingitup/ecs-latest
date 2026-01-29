variable "aws_region" {
  description = "The AWS region to deploy to"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name to prefix resources"
  type        = string
  default     = "ecs-monitoring"
}

variable "create_network" {
  description = "Whether to create a new network stack (VPC, Subnets, NAT)"
  type        = bool
  default     = true
}

variable "vpc_cidr" {
  description = "CIDR block for the new VPC (used if create_network is true)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_id" {
  description = "Existing VPC ID (required if create_network is false)"
  type        = string
  default     = ""
}

variable "public_subnet_ids" {
  description = "Existing Public Subnet IDs (required if create_network is false)"
  type        = list(string)
  default     = []
}

variable "private_subnet_ids" {
  description = "Existing Private Subnet IDs (required if create_network is false)"
  type        = list(string)
  default     = []
}

variable "prometheus_image" {
  description = "Docker image for Prometheus"
  type        = string
  default     = "prom/prometheus:latest"
}

variable "grafana_image" {
  description = "Docker image for Grafana"
  type        = string
  default     = "grafana/grafana:latest"
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana"
  type        = string
  sensitive   = true
  default     = "admin"
}

variable "alertmanager_image" {
  description = "Docker image for Alertmanager"
  type        = string
  default     = "prom/alertmanager:latest"
}

variable "cloudwatch_exporter_image" {
  description = "Docker image for CloudWatch Exporter"
  type        = string
  default     = "prom/cloudwatch-exporter:latest"
}
