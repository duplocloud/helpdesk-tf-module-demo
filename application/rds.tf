resource "aws_db_subnet_group" "orders" {
  name       = "acme-${var.env_name}-db-subnet-group"
  subnet_ids = local.private_subnet_ids
  tags       = merge(local.common_tags, { Name = "acme-${var.env_name}-db-subnet-group" })
}

resource "aws_db_instance" "orders_db" {
  identifier             = "acme-${var.env_name}-orders"
  engine                 = "postgres"
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  allocated_storage      = 20
  username               = "appuser"
  password               = "ChangeMe-S3cret!"
  db_subnet_group_name   = aws_db_subnet_group.orders.name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  publicly_accessible    = false
  skip_final_snapshot    = true
  apply_immediately      = true

  tags = merge(local.common_tags, { Name = "acme-${var.env_name}-orders" })
}
