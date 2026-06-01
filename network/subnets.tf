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
