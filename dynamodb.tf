resource "aws_dynamodb_table" "portfolio_db" {
  name           = "portfolio_db"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
}
