output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "s3_bucket_ids" {
  value = [aws_s3_bucket.uploads.id, aws_s3_bucket.logs.id, aws_s3_bucket.archive.id]
}

output "rds_endpoint" {
  value     = aws_db_instance.orders_db.endpoint
  sensitive = true
}
