moved {
  from = aws_security_group.mysql_internal
  to   = aws_security_group.db_internal["mysql"]
}

resource "aws_security_group" "db_internal" {
  for_each = local.db_security_groups

  name        = "acme-${var.env_name}-${each.key}-internal"
  description = each.value.description
  vpc_id      = aws_vpc.main.id

  ingress {
    description = each.value.description
    from_port   = each.value.port
    to_port     = each.value.port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "acme-${var.env_name}-${each.key}-internal" })
}

resource "aws_security_group" "alb_public" {
  name        = "acme-${var.env_name}-alb-public"
  description = "Allow HTTP and HTTPS inbound traffic for the public load balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "acme-${var.env_name}-alb-public" })
}
