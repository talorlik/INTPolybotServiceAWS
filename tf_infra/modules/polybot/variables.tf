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

variable "instance_name" {
  description = "The Name of the EC2"
  type = string
}

variable "azs" {
  description = "The AZs into which to deploy the EC2 machines"
  type        = list(string)
}

variable "ami" {
  description = "The AMI id to be used in the instance creation"
  type        = string
}

variable "instance_type" {
    description = "Instance Type"
    type        = string
}

variable "image_prefix" {
  description = "The prefix of the ECR Image to pull"
  type        = string
  default     = "polybot-v2"
}

variable "key_pair_name" {
  description = "The name of the EC2 Key Pair"
  type        = string
}

variable "public_subnets" {
  description = "A list of subnets into which the EC2 machines will be deployed"
  type = list(string)
}

variable "iam_instance_profile_name" {
  description = "The Name of the IAM Role Profile to be used"
  type        = string
}

variable "associate_public_ip_address" {
  description = "Whether to generate a public IP address or not"
  type = bool
  default = true
}

variable "alb_name" {
  description = "The Name of the ALB"
  type        = string
  default     = "alb"
}

variable "alb_listener_name" {
  description = "The Name of the ALB Listener"
  type        = string
  default     = "alb-listener"
}

variable "vpc_id" {
  description = "The VPC ID into which to deploy the resources"
  type        = string
}

variable "root_block_device" {
  description = "EC2 root block device settings"
  type = object({
    delete_on_termination = optional(bool, true)
    encrypted             = optional(bool, false)
    iops                  = optional(number, 3000)
    kms_key_id            = optional(string)
    tags                  = optional(map(string))
    throughput            = optional(number)
    volume_size           = optional(number, 20)
    volume_type           = optional(string, "gp3")
  })
  default = {
    iops        = 3000
    volume_size = 20
    volume_type = "gp3"
  }
}

variable "enable_deletion_protection" {
  description = "Whether to allow the deletion of the ALB or not"
  type        = bool
  default     = false
}

variable "alb_sg_name" {
  description = "The Name of the Security Group for ALB"
  type        = string
  default     = "alb-sg"
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

variable "referenced_security_group_id" {
  description = "The default security group ID for egress rules"
  type        = string
}

variable "client_keep_alive" {
  description = "Keep the connection open"
  type        = number
  default     = 7200
}

variable "alb_listeners" {
  description = "The listeners for the ALB"
  type = map(object({
    port            = number
    protocol        = string
    forward         = object({
      target_group_key = string
    })
  }))
}

variable "certificate_arn" {
  description = "The Sub-Domain Certificate"
  type        = string
}

variable "tg_name" {
  description = "Target Group Name"
  type        = string
  default     = "ec2-tg"
}

variable "polybot_sg_name" {
  description = "The Name of the Security Group for the Polybot EC2"
  type        = string
  default     = "polybot-ec2-sg"
}

variable "alb_target_groups" {
  description = "The target groups for the ALB"
  type        = map(object({
    protocol                          = string
    protocol_version                  = string
    port                              = number
    target_type                       = string
    deregistration_delay              = number
    load_balancing_algorithm_type     = optional(string)
    load_balancing_anomaly_mitigation = optional(string)
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

variable "ec2_sg_ingress_rules" {
  description = "List of ingress rules"
  type = list(object({
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = list(string)
    security_groups = list(string)
  }))
}

variable "ec2_sg_egress_rules" {
  description = "List of egress rules"
  type = list(object({
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = list(string)
    security_groups = list(string)
  }))
}

variable "tags" {
  type = map(string)
}