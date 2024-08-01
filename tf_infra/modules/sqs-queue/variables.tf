variable "env" {
    description = "Deployment environment"
    type        = string
}

variable "prefix" {
    description = "Name added to all resources"
    type        = string
}

variable "queue_name" {
  description = "The name of the SQS Queue"
  type        = string
}

variable "visibility_timeout_seconds" {
    type    = number
    default = 30
}

variable "message_retention_seconds" {
    type    = number
    default = 86400
}

variable "delay_seconds" {
    type    = number
    default = 0
}

variable "max_message_size" {
    type    = number
    default = 262144
}

variable "receive_wait_time_seconds" {
    type    = number
    default = 0
}

variable "tags" {
    type = map(string)
}