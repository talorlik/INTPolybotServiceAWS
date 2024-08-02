### General ###
prefix         = "talo-tf"
resource_alias = "talo"
### VPC ###
vpc_cidr = "10.0.0.0/16"
### S3 ###
s3_bucket_name           = "s3"
s3_bucket_prefix         = "images"
acl                      = "private"
control_object_ownership = true
object_ownership         = "ObjectWriter"
versioning = {
  enabled = true
}
### Secrets ###
telegram_token_name     = "telegram/token/v2a"
domain_certificate_name = "sub-domain/certificate/v2a"
### SQS ###
identify_queue_name = "sqs-identify"
results_queue_name  = "sqs-results"
### DynamoDB ###
table_name     = "prediction-results"
billing_mode   = "PROVISIONED"
hash_key       = "predictionId"
read_capacity  = 1
write_capacity = 1
global_secondary_indexes = [
  {
    name            = "chatId-predictionId-index"
    hash_key        = "chatId"
    range_key       = "predictionId"
    read_capacity   = 1
    write_capacity  = 1
    projection_type = "ALL"
  },
  {
    name            = "another-index"
    hash_key        = "anotherKey"
    range_key       = "anotherRangeKey"
    read_capacity   = 1
    write_capacity  = 1
    projection_type = "ALL"
  }
]
attributes = [
  {
    name = "predictionId"
    type = "S"
  },
  {
    name = "chatId"
    type = "N"
  },
  {
    name = "anotherKey"
    type = "S"
  },
  {
    name = "anotherRangeKey"
    type = "N"
  }
]
### ECR ###
ecr_name             = "docker-images"
image_tag_mutability = "IMMUTABLE"
ecr_lifecycle_policy = {
  rules = [
    {
      rulePriority = 1
      description  = "Always keep at least the most recent image"
      selection = {
        tagStatus     = "tagged"
        tagPrefixList = ["yolo5-v2", "polybot-v2"]
        countType     = "imageCountMoreThan"
        countNumber   = 1
      }
      action = {
        type = "expire"
      }
    },
    {
      rulePriority = 2
      description  = "Keep only one untagged image, expire all others"
      selection = {
        tagStatus   = "untagged"
        countType   = "imageCountMoreThan"
        countNumber = 1
      }
      action = {
        type = "expire"
      }
    }
  ]
}
### IAM Role ###
iam_role_name             = "ec2-role"
iam_role_policy_name      = "ec2-policy"
iam_instance_profile_name = "instance-profile"
iam_assume_role_policy    = {
  Version = "2012-10-17",
  Statement = [
    {
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }
  ]
}
iam_policy_template       = "policy_template.tftpl"
### EC2 ###
key_pair_name = "ec2-key-pair"
### Polybot ###
polybot_instance_name = "polybot-ec2"
polybot_instance_type = "t3.micro"
polybot_image_prefix  = "polybot-v2"
alb_security_group_ingress_rules = {
  http_1 = {
    description = "HTTPS traffic from Telegram servers"
    from_port   = 8443
    to_port     = 8443
    ip_protocol = "tcp"
    cidr_ipv4   = "149.154.160.0/20"
  }
  http_2 = {
    description = "HTTPS traffic from Telegram servers"
    from_port   = 8443
    to_port     = 8443
    ip_protocol = "tcp"
    cidr_ipv4   = "91.108.4.0/22"
  }
}
alb_security_group_egress_rules = {
  all = {
    description = "Out to the polybot security group"
    from_port   = 8443
    to_port     = 8443
    ip_protocol = "tcp"
  }
}
alb_listeners = {
  https-listener = {
    port     = 8443
    protocol = "HTTPS"
    forward = {
      target_group_key = "target-instance"
    }
  }
}
alb_target_groups = {
  target-instance = {
    protocol                          = "HTTP"
    protocol_version                  = "HTTP1"
    port                              = 8443
    target_type                       = "instance"
    deregistration_delay              = 300
    load_balancing_algorithm_type     = "round_robin"
    load_balancing_anomaly_mitigation = "off"
    load_balancing_cross_zone_enabled = false

    health_check = {
      enabled             = true
      interval            = 30
      path                = "/health"
      port                = "traffic-port"
      healthy_threshold   = 5
      unhealthy_threshold = 2
      timeout             = 5
      protocol            = "HTTP"
      matcher             = "200-399"
    }
  }
}
alb_additional_target_group_attachments = {
  ex-instance-other = {
    target_group_key = "target-instance"
    target_type      = "instance"
    port             = 8443
  }
}
polybot_ec2_sg_ingress_rules = [
  {
    from_port       = 8443
    to_port         = 8443
    protocol        = "tcp"
    cidr_blocks     = []
    security_groups = []
  },
  {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = []
  }
]
polybot_ec2_sg_egress_rules = [
  {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = []
  }
]
### Yolo5 ###
yolo5_instance_name = "yolo5-ec2"
yolo5_instance_type = "t3.medium"
yolo_image_prefix   = "yolo5-v2"
yolo5_ec2_sg_ingress_rules = [
  {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = []
  }
]
yolo5_ec2_sg_egress_rules = [
  {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = []
  }
]
sns_protocol = "email"
sns_endpoint = "talorlik@gmail.com"