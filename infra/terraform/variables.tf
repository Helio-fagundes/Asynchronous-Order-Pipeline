variable "aws_access_key" {
  type        = string
  description = "Access key da AWS"
  sensitive   = true
}

variable "aws_secret_key" {
  type        = string
  description = "Secret key da AWS"
  sensitive   = true
}

variable "region" {
  type        = string
  description = "Região da AWS"
}

variable "email" {
  type        = string
  description = "Email da equipe de DevOps para notificações"
  sensitive   = true
}