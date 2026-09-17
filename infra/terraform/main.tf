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
  region     = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key

  default_tags {
    tags = {
      owner      = "Helio Fagundes"
      managed_by = "Terraform"
    }
  }
}

output "ecr_repo_producer_url" {
  value = aws_ecr_repository.ecr_repo_producer.repository_url
  description = "URL do repositório ECR para imagens do producer"
}

output "ecr_repo_worker_url" {
  value = aws_ecr_repository.ecr_repo_worker.repository_url
  description = "URL do repositório ECR para imagens do worker"
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.ecs_cluster.name
}

output "ecs_service_name_producer" {
  value = aws_ecs_service.producer_service.name
}

output "ecs_service_name_worker" {
  value = aws_ecs_service.worker_service.name
}
