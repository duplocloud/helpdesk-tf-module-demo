output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

output "private_subnet_ids" {
  value = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

output "alb_public_sg_id" {
  value = aws_security_group.alb_public.id
}

output "random_password" {
  value     = random_password.main.result
  sensitive = true
}
