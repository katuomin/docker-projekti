terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Learner Lab only allows us-east-1 and us-west-2. Credentials come from the
# lab's "AWS Details" panel (access key, secret key and session token).
provider "aws" {
  region = var.aws_region
}
