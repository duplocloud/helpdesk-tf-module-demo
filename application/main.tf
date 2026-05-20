data "aws_caller_identity" "current" {}

# Read the network root's outputs from S3 in the matching workspace.
data "terraform_remote_state" "network" {
  backend   = "s3"
  workspace = terraform.workspace
  config = {
    bucket = "tf-poc-state-805863115079-ap-south-1"
    key    = "network/terraform.tfstate"
    region = "ap-south-1"
  }
}

# Latest Amazon Linux 2 AMI in the current region.
data "aws_ssm_parameter" "amzn2_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

locals {
  common_tags        = { env = var.env_name }
  vpc_id             = data.terraform_remote_state.network.outputs.vpc_id
  public_subnet_ids  = data.terraform_remote_state.network.outputs.public_subnet_ids
  private_subnet_ids = data.terraform_remote_state.network.outputs.private_subnet_ids
  effective_ami      = var.ami_id != "" ? var.ami_id : data.aws_ssm_parameter.amzn2_ami.value
  account_id         = data.aws_caller_identity.current.account_id
}

# ──────────────────────────────────────────────────────────────────────────
# Security groups
# ──────────────────────────────────────────────────────────────────────────

resource "aws_security_group" "alb_sg" {
  name        = "acme-${var.env_name}-alb-sg"
  description = "Allow HTTP/HTTPS from the internet"
  vpc_id      = local.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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

  tags = merge(local.common_tags, { Name = "acme-${var.env_name}-alb-sg" })
}

resource "aws_security_group" "ec2_sg" {
  name        = "acme-${var.env_name}-ec2-sg"
  description = "Allow HTTP from ALB"
  vpc_id      = local.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "acme-${var.env_name}-ec2-sg" })
}

# ──────────────────────────────────────────────────────────────────────────
# Web tier — 2 EC2 instances running nginx via user_data
# ──────────────────────────────────────────────────────────────────────────

locals {
  nginx_user_data = <<-EOT
    #!/bin/bash
    yum install -y nginx
    systemctl enable nginx
    systemctl start nginx
  EOT
}

resource "aws_instance" "web1" {
  ami                    = local.effective_ami
  instance_type          = var.instance_type
  subnet_id              = local.private_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  user_data              = local.nginx_user_data
  tags                   = merge(local.common_tags, { Name = "acme-${var.env_name}-web-1", app = "nginx" })
}

resource "aws_instance" "web2" {
  ami                    = local.effective_ami
  instance_type          = var.instance_type
  subnet_id              = local.private_subnet_ids[1]
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  user_data              = local.nginx_user_data
  tags                   = merge(local.common_tags, { Name = "acme-${var.env_name}-web-2", app = "nginx" })
}

# ──────────────────────────────────────────────────────────────────────────
# ALB
# ──────────────────────────────────────────────────────────────────────────

resource "aws_lb" "main" {
  name               = "acme-${var.env_name}-alb"
  load_balancer_type = "application"
  subnets            = local.public_subnet_ids
  security_groups    = [aws_security_group.alb_sg.id]
  tags               = merge(local.common_tags, { Name = "acme-${var.env_name}-alb" })
}

resource "aws_lb_target_group" "web" {
  name        = "acme-${var.env_name}-web"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = local.vpc_id
  target_type = "instance"

  health_check {
    path                = "/"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# ──────────────────────────────────────────────────────────────────────────
# S3 buckets — 3 of them. Account-id suffix keeps names globally unique.
# ──────────────────────────────────────────────────────────────────────────

resource "aws_s3_bucket" "uploads" {
  bucket = "acme-${var.env_name}-uploads-${local.account_id}"
  tags   = merge(local.common_tags, { Name = "acme-${var.env_name}-uploads", purpose = "user-uploads" })
}

resource "aws_s3_bucket" "logs" {
  bucket = "acme-${var.env_name}-logs-${local.account_id}"
  tags   = merge(local.common_tags, { Name = "acme-${var.env_name}-logs", purpose = "access-logs" })
}

resource "aws_s3_bucket" "archive" {
  bucket = "acme-${var.env_name}-archive-${local.account_id}"
  tags   = merge(local.common_tags, { Name = "acme-${var.env_name}-archive", purpose = "cold-storage" })
}

# ──────────────────────────────────────────────────────────────────────────
# RDS — PostgreSQL
# ──────────────────────────────────────────────────────────────────────────

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

# ──────────────────────────────────────────────────────────────────────────
# Lambda — 2 functions sharing one execution role
# ──────────────────────────────────────────────────────────────────────────

resource "aws_iam_role" "lambda_role" {
  name = "acme-${var.env_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/hello.py"
  output_path = "${path.module}/lambda/hello.zip"
}

resource "aws_lambda_function" "hello1" {
  function_name    = "acme-${var.env_name}-hello1"
  role             = aws_iam_role.lambda_role.arn
  handler          = "hello.handler"
  runtime          = "python3.11"
  memory_size      = var.lambda_memory_mb
  timeout          = 3
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  tags = merge(local.common_tags, { Name = "acme-${var.env_name}-hello1" })
}

resource "aws_lambda_function" "hello2" {
  function_name    = "acme-${var.env_name}-hello2"
  role             = aws_iam_role.lambda_role.arn
  handler          = "hello.handler"
  runtime          = "python3.11"
  memory_size      = var.lambda_memory_mb
  timeout          = 3
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  tags = merge(local.common_tags, { Name = "acme-${var.env_name}-hello2" })
}
