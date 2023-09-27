terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 5.0.0"
    }
  }
}

# define aws provider that we're using

provider "aws" {
    region = var.aws_region
    skip_credentials_validation = true
}