data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs                  = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  public_subnet_cidrs  = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, i + 1)]
  private_subnet_cidrs = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, i + 11)]
  nat_count            = var.multi_az_nat ? var.az_count : 1
  common_tags          = { env = var.env_name }
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(local.common_tags, { Name = "acme-${var.env_name}-vpc" })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = merge(local.common_tags, { Name = "acme-${var.env_name}-igw" })
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.public_subnet_cidrs[0]
  availability_zone       = local.azs[0]
  map_public_ip_on_launch = true
  tags                    = merge(local.common_tags, { Name = "acme-${var.env_name}-public-1a", tier = "public" })
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.public_subnet_cidrs[1]
  availability_zone       = local.azs[1]
  map_public_ip_on_launch = true
  tags                    = merge(local.common_tags, { Name = "acme-${var.env_name}-public-1b", tier = "public" })
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_subnet_cidrs[0]
  availability_zone = local.azs[0]
  tags              = merge(local.common_tags, { Name = "acme-${var.env_name}-private-1a", tier = "private" })
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_subnet_cidrs[1]
  availability_zone = local.azs[1]
  tags              = merge(local.common_tags, { Name = "acme-${var.env_name}-private-1b", tier = "private" })
}

resource "aws_eip" "nat" {
  count  = local.nat_count
  domain = "vpc"
  tags   = merge(local.common_tags, { Name = "acme-${var.env_name}-nat-${count.index}" })
}

resource "aws_nat_gateway" "nat" {
  count         = local.nat_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = count.index == 0 ? aws_subnet.public_a.id : aws_subnet.public_b.id
  tags          = merge(local.common_tags, { Name = "acme-${var.env_name}-nat-${count.index}" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(local.common_tags, { Name = "acme-${var.env_name}-rt-public" })
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[0].id
  }

  tags = merge(local.common_tags, { Name = "acme-${var.env_name}-rt-private" })
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}
