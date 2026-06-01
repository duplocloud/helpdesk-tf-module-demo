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
