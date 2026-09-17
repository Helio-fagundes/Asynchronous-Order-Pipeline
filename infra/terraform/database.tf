resource "aws_dynamodb_table" "requisicoes" {
  name         = "tabela-requisicoes-validadas"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name = "DynamoDB Table - user-requisicoes"
  }
}