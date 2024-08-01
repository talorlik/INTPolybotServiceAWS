variable "env" {
  description = "Deployment environment"
  type        = string
}

variable "prefix" {
  description = "Name added to all resources"
  type        = string
}

variable "table_name" {
  description = "The name of the DynamoDB table"
  type        = string
}

variable "billing_mode" {
  description = "The billing mode of the DynamoDB table"
  type        = string
  default     = "PROVISIONED"
}

variable "hash_key" {
  description = "The hash key of the DynamoDB table"
  type        = string
}

variable "read_capacity" {
  description = "The read capacity units of the DynamoDB table"
  type        = number
  default     = 1
}

variable "write_capacity" {
  description = "The write capacity units of the DynamoDB table"
  type        = number
  default     = 1
}

variable "global_secondary_indexes" {
  description = "A list of global secondary indexes"
  type = list(object({
    name            = string
    hash_key        = string
    range_key       = string
    read_capacity   = number
    write_capacity  = number
    projection_type = string
  }))
}

variable "attributes" {
  description = "A list of attributes for the DynamoDB table"
  type = list(object({
    name = string
    type = string
  }))
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
}
