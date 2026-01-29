# ECS Monitoring Automation (Watchtower)

This repository provides a production-ready, standalone monitoring stack for AWS ECS Fargate.

## Features
- **Prometheus** for metric collection.
- **Alertmanager** for notifications.
- **Thanos** for long-term storage in S3 and aggregated querying.
- **CloudWatch Exporter** for AWS-native ECS metrics.
- **Grafana** with automated dashboard and datasource provisioning.
- **Service Discovery** via AWS Cloud Map.

## Prerequisites
- Terraform
- AWS CLI
- Docker (for building custom config images)

## Quick Start (Automated)
Run the following script to deploy the entire stack:
```powershell
.\deploy.ps1
```

## Manual Deployment
1. Initialize: `terraform init`
2. Apply: `terraform apply`

## Reusable Module Configuration
Update `terraform.tfvars` to customize the deployment:
```hcl
aws_region             = "us-east-1"
project_name           = "my-monitoring"
create_network         = true # Set to false if using existing VPC
```

## Customizing Configurations
The stack uses "baked" configurations for high reliability:

1. **Prometheus Rules**: Edit `custom-prometheus/rules.yml`.
2. **Alertmanager Config**: Edit `custom-alertmanager/alertmanager.yml`.
3. **CloudWatch Metrics**: Edit `custom-cloudwatch-exporter/config.yml`.
4. **Grafana Dashboards**: Add JSON files to `custom-grafana/provisioning/dashboards/`.

### Rebuilding Images
After updating configurations, rebuild and push the images:
```bash
docker build -t your-repo/prometheus:latest ./custom-prometheus
docker build -t your-repo/alertmanager:latest ./custom-alertmanager
docker build -t your-repo/grafana:latest ./custom-grafana
docker build -t your-repo/cw-exporter:latest ./custom-cloudwatch-exporter
```

## Architecture
See [ARCHITECTURE.md](./ARCHITECTURE.md) for detailed diagrams and data flow.
