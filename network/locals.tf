data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs                  = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  public_subnet_cidrs  = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, i + 1)]
  private_subnet_cidrs = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, i + 11)]
  nat_count            = var.multi_az_nat ? var.az_count : 1
  common_tags          = { env = var.env_name }

  db_security_groups = {
    mysql    = { port = 3306, description = "Allow MySQL traffic within the VPC" }
    postgres = { port = 5432, description = "Allow PostgreSQL traffic within the VPC" }
    mssql    = { port = 1433, description = "Allow MSSQL traffic within the VPC" }
    oracle   = { port = 1521, description = "Allow Oracle DB traffic within the VPC" }
    redis    = { port = 6379, description = "Allow Redis traffic within the VPC" }
  }
}
