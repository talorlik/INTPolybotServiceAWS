variable "env" {
    description = "Deployment environment"
    type        = string
}

variable "region" {
    description = "Deployment region"
    type        = string
    default     = "us-east-1"
}

variable "prefix" {
    description = "Name added to all resources"
    type        = string
}

variable "resource_alias" {
    description = "My name"
    type        = string
}

###################### VPC #########################

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

###################### S3 ##########################

variable "s3_bucket_name" {
  description = "The name of the S3 bucket that holds the images"
  type        = string
}

variable "s3_bucket_prefix" {
  description = "The key (folder) to be used in the S3 bucket that holds the images"
  type        = string
}

variable "acl" {
  description = "Determine whether the S3 is private or public"
  type        = string
}

variable "control_object_ownership" {
  description = "Enable ownership over objects in the bucket or not"
  type        = bool
}

variable "object_ownership" {
  description = "Who owns that resources in the S3"
  type        = string
}

variable "versioning" {
  description = "Enable object versioning"
  type = object({
    enabled = bool
  })
}

############### Sub Domain and Cert ################

variable "country" {
  description = "The country name for the certificate"
  type        = string
}

variable "state" {
  description = "The state name for the certificate"
  type        = string
}

variable "locality" {
  description = "The locality name for the certificate"
  type        = string
}

variable "organization" {
  description = "The organization name for the certificate"
  type        = string
}

variable "common_name" {
  description = "The common name for the certificate"
  type        = string
}

################ Secrets ######################

variable "telegram_token_name" {
  description = "The name of the secret"
  type        = string
}

variable "telegram_token_value" {
  description = "The value of the secret"
  type        = string
  sensitive   = true
}

variable "domain_certificate_name" {
  description = "The name of the secret"
  type        = string
}

###################### SQS ##########################

variable "identify_queue_name" {
  description = "The name of the SQS Queue for identify"
  type        = string
}

variable "results_queue_name" {
  description = "The name of the SQS Queue for results"
  type        = string
}

################### DynamoDB ########################

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

##################### ECR ##########################

variable "ecr_name" {
  description = "The name of the ECR"
  type        = string
}

variable "image_tag_mutability" {
  description = "The value that determines if the image is overridable"
  type        = string
}

variable "ecr_lifecycle_policy" {}
# variable "ecr_lifecycle_policy" {
#   description = "The lifecycle policy for the ECR repository"
#   type = object({
#     rules = list(object({
#       rulePriority = number
#       description  = string
#       selection = object({
#         tagStatus       = string
#         tagPrefixList   = optional(list(string), [])
#         countType       = string
#         countNumber     = number
#       })
#       action = object({
#         type = string
#       })
#     }))
#   })
# }
################# IAM Role ######################

variable "iam_role_name" {
  description = "The name of the IAM Role"
  type        = string
}

variable "iam_role_policy_name" {
  description = "The name of the IAM Role Policy"
  type        = string
}

variable "iam_instance_profile_name" {
  description = "The name of the Instance Profile"
  type        = string
}

############### EC2 Key Pair ####################

variable "key_pair_name" {
  description = "The name of the EC2 Key Pair"
  type        = string
}

################# Polybot ######################

variable "polybot_instance_name" {
  description = "The name of EC2 machine to be used by the Polybot"
  type        = string
}

variable "polybot_instance_type" {
  description = "The Type of EC2 machine to be used by the Polybot"
  type        = string
}

variable "polybot_image_prefix" {
  description = "The Prefix of the polybot's docker image name"
  type        = string
}

variable "alb_security_group_ingress_rules" {
  description = "The Inbound rules for the ALB SG"
  type = map(object({
    description = string
    from_port   = number
    to_port     = number
    ip_protocol = string
    cidr_ipv4   = string
  }))
}

variable "alb_security_group_egress_rules" {
  description = "The Outbound rules for the ALB SG"
  type = map(object({
    description = string
    from_port   = number
    to_port     = number
    ip_protocol = string
  }))
}

variable "alb_listeners" {
  description = "The listeners for the ALB"
  type        = map(object({
    port            = number
    protocol        = string
    forward         = object({
      target_group_key = string
    })
  }))
}

variable "alb_target_groups" {
  description = "The target groups for the ALB"
  type        = map(object({
    protocol                          = string
    protocol_version                  = string
    port                              = number
    target_type                       = string
    deregistration_delay              = number
    load_balancing_algorithm_type     = string
    load_balancing_anomaly_mitigation = string
    load_balancing_cross_zone_enabled = bool
    health_check                      = object({
      enabled             = bool
      interval            = number
      path                = string
      port                = string
      healthy_threshold   = number
      unhealthy_threshold = number
      timeout             = number
      protocol            = string
      matcher             = string
    })
  }))
}

variable "alb_additional_target_group_attachments" {
  description = "Additional target group attachments"
  type = map(object({
    target_group_key = string
    target_type      = string
    port             = number
  }))
}

variable "polybot_ec2_sg_ingress_rules" {
  description = "List of ingress rules"
  type = list(object({
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = optional(list(string), null)
    security_groups = optional(list(string), null)
  }))
}

variable "polybot_ec2_sg_egress_rules" {
  description = "List of egress rules"
  type = list(object({
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = optional(list(string), null)
    security_groups = optional(list(string), null)
  }))
}

################## Yolo5 ######################

variable "yolo5_ec2_sg_ingress_rules" {
  description = "List of ingress rules"
  type = list(object({
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = optional(list(string), null)
    security_groups = optional(list(string), null)
  }))
}

variable "yolo5_ec2_sg_egress_rules" {
  description = "List of egress rules"
  type = list(object({
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = optional(list(string), null)
    security_groups = optional(list(string), null)
  }))
}

variable "yolo5_instance_name" {
  description = "The Name of EC2 machine to be used by the Yolo5"
  type        = string
}

variable "yolo5_instance_type" {
  description = "The Type of EC2 machine to be used by the Yolo5"
  type        = string
}

variable "yolo5_image_prefix" {
  description = "The Prefix of the yolo5's docker image name"
  type        = string
}

variable "sns_protocol" {
  description = "The SNS protocol by which the notification is going to be sent"
  type        = string
}

variable "sns_endpoint" {
  description = "The SNS endpoint to which the notification is going to be sent"
  type        = string
}