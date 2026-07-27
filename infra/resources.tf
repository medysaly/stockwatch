

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

# Grants permission to write logs to CloudWatch — required for the print()-based logging to be visible after deployment.
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Grants permission to read this specific secret, not every secret in the account.
resource "aws_iam_role_policy" "lambda_secrets_access" {
  name = "stockwatch-lambda-secrets-access"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "secretsmanager:GetSecretValue"
        Effect   = "Allow"
        Resource = aws_secretsmanager_secret.stockwatch_secrets.arn
      }
    ]
  })
}


resource "aws_lambda_function" "stockwatch" {
  function_name = "stockwatch"
  role          = aws_iam_role.lambda_execution_role.arn
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.stockwatch.repository_url}:latest"
  timeout       = 30
  memory_size   = 256
  architectures = ["arm64"]
}

resource "aws_cloudwatch_event_rule" "stockwatch_daily" {
  name                = "stockwatch-daily-trigger"
  schedule_expression = "rate(1 day)"
}

resource "aws_cloudwatch_event_target" "stockwatch_lambda_target" {
  rule = aws_cloudwatch_event_rule.stockwatch_daily.name
  arn  = aws_lambda_function.stockwatch.arn
  input = jsonencode({
    ticker = "AAPL"
  })
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stockwatch.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stockwatch_daily.arn
}
