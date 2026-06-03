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

resource "aws_s3_bucket" "analytics" {
  bucket = "acme-${var.env_name}-analytics-${local.account_id}"
  tags   = merge(local.common_tags, { Name = "acme-${var.env_name}-analytics", purpose = "analytics" })
}
