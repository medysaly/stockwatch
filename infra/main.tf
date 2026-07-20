terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" # Keeps you safely within the v6.x release cycle
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "stockwatch_data" {
  bucket = "stockwatch-data-mehdisalhi-a1b2"
}
