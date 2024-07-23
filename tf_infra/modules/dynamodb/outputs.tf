output "table_name" {
  description = "The name of the DynamoDB table"
  value       = aws_dynamodb_table.db.name
}

output "table_arn" {
  description = "The ARN of the DynamoDB table"
  value       = aws_dynamodb_table.db.arn
}

output "table_id" {
  description = "The ID of the DynamoDB table"
  value       = aws_dynamodb_table.db.id
}
