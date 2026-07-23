

resource "aws_s3_bucket" "stockwatch_data" {
  bucket = "stockwatch-data-mehdisalhi-a1b2"
}

resource "aws_secretsmanager_secret" "stockwatch_secrets" {
  name = "stockwatch/api-keys"
}


# Bundled as one JSON secret, not one per key — Secrets Manager bills per secret ($0.40/mo), not per value.
resource "aws_secretsmanager_secret_version" "stockwatch_secrets_version" {
  secret_id     = aws_secretsmanager_secret.stockwatch_secrets.id
  secret_string = jsonencode({
    ANTHROPIC_API_KEY = var.anthropic_api_key
  })
}

# Lambda's container-image deployment only supports ECR — Docker Hub isn't supported for this.
resource "aws_ecr_repository" "stockwatch" {
  name = "stockwatch"
}

# Execution role Lambda assumes at runtime — trust policy grants only the Lambda service, nothing else.
resource "aws_iam_role" "lambda_execution_role" {
  name = "stockwatch-lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}
