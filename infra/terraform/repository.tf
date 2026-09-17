#==========================================
#Criação do bucket S3 para armazenar os logs do ALB
#==========================================
resource "aws_s3_bucket" "lb_logs" {
  bucket        = format("alb-logs-helio-terraform%s", var.region)
  force_destroy = true
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "allow_lb_logs" {
  bucket = aws_s3_bucket.lb_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowELBAccessLogs"
        Effect = "Allow"
        Principal = {
          Service = "logdelivery.elasticloadbalancing.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.lb_logs.arn}/alb-logs/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      }
    ]
  })
}

#==========================================
#Criação do repositório ecr para imagens do producer
#==========================================
resource "aws_ecr_repository" "ecr_repo_producer" {
  name                 = "ecr-repo-helio-terraform-producer"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

#==========================================
#Criação do repositório ecr para imagens do worker
#==========================================
resource "aws_ecr_repository" "ecr_repo_worker" {
  name                 = "ecr-repo-helio-terraform-worker"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

