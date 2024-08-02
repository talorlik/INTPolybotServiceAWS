locals {
  queue_name = "${var.prefix}-${var.region}-${var.queue_name}-${var.env}"
}

resource "aws_sqs_queue" "queue" {
  name                       = local.queue_name
  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.message_retention_seconds
  delay_seconds              = var.delay_seconds
  max_message_size           = var.max_message_size
  receive_wait_time_seconds  = var.receive_wait_time_seconds

  tags = merge(
    {
      Name = local.queue_name
    },
    var.tags
  )
}