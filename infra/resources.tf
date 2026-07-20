

resource "aws_s3_bucket" "stockwatch_data" {
  bucket = "stockwatch-data-mehdisalhi-a1b2"
}

resource "aws_secretsmanager_secret" "stockwatch_secrets" {
  name = "stockwatch/api-keys"
}

resource "aws_secretsmanager_secret_version" "stockwatch_secrets_version" {
  secret_id     = aws_secretsmanager_secret.stockwatch_secrets.id
  secret_string = jsonencode({
    ANTHROPIC_API_KEY = var.anthropic_api_key
  })
}

resource "aws_ecr_repository" "stockwatch" {
  name = "stockwatch"
}
