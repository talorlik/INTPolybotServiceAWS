variable "env" {
    description = "Deployment environment"
    type        = string
}

variable "prefix" {
    description = "Name added to all resources"
    type        = string
}

variable "secret_name" {
  description = "The name of the secret"
  type        = string
}

variable "secret_value" {
  description = "The value of the secret"
  type        = string
  sensitive   = true
}

variable "tags" {
  type = map(string)
}