resource "aws_s3_bucket" "lb_logs" {
  bucket = format("alb-logs-helio-terraform%s", var.region)
  force_destroy = true
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "allow_lb_logs" {
  bucket = aws_s3_bucket.lb_logs.bucket
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowELBAccessLogs"
        Effect = "Allow"
        Principal = {
          Service = "://amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.lb_logs.arn}/alb-logs/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      }
    ]
  })
}