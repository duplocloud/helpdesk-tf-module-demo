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
