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
