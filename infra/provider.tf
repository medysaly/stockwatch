terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" # avoids breaking changes from v7+
    }
  }
}

variable "anthropic_api_key" {
  type      = string
  sensitive = true
}

provider "aws" {
  region = "us-east-1" # cheapest, most complete AWS service availability
}
