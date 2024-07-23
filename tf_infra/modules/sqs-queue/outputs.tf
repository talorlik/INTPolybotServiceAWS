output "sqs_queue_name" {
  value = aws_sqs_queue.queue.name
}

output "sqs_queue_arn" {
  description = "The ARN of the SQS Queue"
  value       = aws_sqs_queue.queue.arn
}