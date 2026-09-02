terraform {
  required_version = ">= 1.3.0"

  required_providers {

    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }

}

provider "aws" {
  region = "us-east-1"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"

  default_tags {
    tags = {
      owner      = "Helio Fagundes"
      managed_by = "Terraform"
    }
  }
}
