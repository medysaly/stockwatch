terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" 
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
