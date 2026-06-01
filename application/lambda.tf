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
