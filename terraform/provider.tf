terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.61.0"
    }
  }
  backend "s3" {
  bucket = "devops-nija-keshav" # create this s3 bucet in aws
  key    = ".terraform/terraform.tfstate"
  region = "us-east-1"
  }
}

provider "aws" {
  # Configuration options
  region = "us-east-1"
}