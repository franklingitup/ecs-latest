locals {
  vpc_id             = var.create_network ? aws_vpc.main[0].id : var.vpc_id
  public_subnet_ids  = var.create_network ? aws_subnet.public[*].id : var.public_subnet_ids
  private_subnet_ids = var.create_network ? aws_subnet.private[*].id : var.private_subnet_ids
}
