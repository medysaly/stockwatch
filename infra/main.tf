terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" # Keeps you safely within the v6.x release cycle
    }
  }
}

variable "anthropic_api_key" {
  type      = string
  sensitive = true
}

provider "aws" {
  region = "us-east-1"
}

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

