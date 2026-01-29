$ErrorActionPreference = "Stop"

Write-Host "ECS Monitoring Automation - Setup Script" -ForegroundColor Cyan

# Check for Terraform
if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
    Write-Error "Terraform is not installed. Please install Terraform first."
}

# Prompt for Region
$region = Read-Host "Enter AWS Region (default: us-east-1)"
if ([string]::IsNullOrWhiteSpace($region)) { $region = "us-east-1" }

# Prompt for Network Creation
$createNetwork = Read-Host "Do you want to create a new VPC and Network Layer? (y/n) [Default: y]"
$tfVarsContent = ""

if ($createNetwork -eq 'n') {
    Write-Host "You chose to use an existing VPC." -ForegroundColor Yellow
    $vpcId = Read-Host "Enter your existing VPC ID (e.g., vpc-12345678)"
    $privateSubnets = Read-Host "Enter Private Subnet IDs (comma separated, e.g., subnet-a,subnet-b)"
    $publicSubnets = Read-Host "Enter Public Subnet IDs for LB (comma separated, e.g., subnet-c,subnet-d)"

    $privateSubnetsList = $privateSubnets -split "," | ForEach-Object { "`"$_`"" }
    $publicSubnetsList = $publicSubnets -split "," | ForEach-Object { "`"$_`"" }
    $privateSubnetsString = "[" + ($privateSubnetsList -join ", ") + "]"
    $publicSubnetsString = "[" + ($publicSubnetsList -join ", ") + "]"

    $tfVarsContent = @"
aws_region = "$region"
create_network = false
vpc_id = "$vpcId"
private_subnet_ids = $privateSubnetsString
public_subnet_ids = $publicSubnetsString
"@
} else {
    Write-Host "Creating a new isolated network (VPC + NAT Gateway)..." -ForegroundColor Green
    $tfVarsContent = @"
aws_region = "$region"
create_network = true
"@
}

$tfVarsContent | Out-File -FilePath "terraform.tfvars" -Encoding ASCII
Write-Host "Created terraform.tfvars." -ForegroundColor Green

# Initializing
Write-Host "Initializing Terraform..."
terraform init

Write-Host "Planning deployment..."
terraform plan -out=tfplan

$confirm = Read-Host "Do you want to apply this plan? (y/n)"
if ($confirm -eq 'y') {
    terraform apply tfplan
    Write-Host "Deployment Complete!" -ForegroundColor Green
    
    # Get Outputs
    $promUrl = terraform output -raw prometheus_url
    $grafUrl = terraform output -raw grafana_url
    
    Write-Host "`nAccess your services here:"
    Write-Host "Prometheus: $promUrl" -ForegroundColor Yellow
    Write-Host "Grafana: $grafUrl" -ForegroundColor Yellow
    Write-Host "(Default Grafana creds: admin / admin)"
    
    if ($createNetwork -ne 'n') {
        Write-Host "NOTE: A new VPC with Private Subnets and NAT Gateway was created." -ForegroundColor Cyan
    }
} else {
    Write-Host "Deployment cancelled."
}
