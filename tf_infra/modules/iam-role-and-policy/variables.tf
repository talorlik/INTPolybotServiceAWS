variable "env" {
    description = "Deployment environment"
    type        = string
}

variable "prefix" {
    description = "Name added to all resources"
    type        = string
}

variable "iam_role_name" {
  type = string
}

variable "assume_role_policy" {
  type = string
}

variable "iam_role_policy_name" {
  type = string
}

variable "policy" {
  type = string
}

variable "iam_instance_profile_name" {
  type = string
}

variable "tags" {
  type = map(string)
}