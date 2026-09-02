resource "aws_s3_bucket" "bucket" {
  bucket = "bucket-teste-helio-terraform"

  tags = {
    Name        = "bucket-teste-helio-terraform"
    Environment = "Dev"
  }
}