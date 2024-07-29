data "aws_availability_zones" "available" {
  state = "available"
}

module "ubuntu_24_04_latest" {
  source              = "github.com/andreswebs/terraform-aws-ami-ubuntu"
  arch                = "amd64"
  ubuntu_version      = "24.04"
  virtualization_type = "hvm"
  volume_type         = "ebs-gp3"
}

locals {
  vpc_name       = "${var.prefix}-${var.region}-${var.env}"
  s3_bucket_name = "${var.prefix}-${var.s3_bucket_name}-${var.env}"
  azs            = slice(data.aws_availability_zones.available.names, 0, 2)
  ami_id         = module.ubuntu_24_04_latest.ami_id
  tags           = {
    Env       = var.env
    Terraform = true
  }
}

# Output: public_subnets for use in ALB
module "vpc" {
  source         = "terraform-aws-modules/vpc/aws"
  name           = local.vpc_name
  cidr           = var.vpc_cidr
  azs            = local.azs
  public_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 1)]
  tags           = merge(
    {
      Name = local.vpc_name
    },
    local.tags
  )
}

module "s3_bucket" {
  source                   = "terraform-aws-modules/s3-bucket/aws"
  bucket                   = local.s3_bucket_name
  acl                      = var.acl
  control_object_ownership = var.control_object_ownership
  object_ownership         = var.object_ownership
  versioning               = var.versioning
  tags                     = merge(
    {
      Name = local.s3_bucket_name
    },
    local.tags
  )
}

################# Route 53 ######################
module "sub_domain_and_cert" {
  source       = "./modules/sub-domain-and-cert"
  country      = var.country
  state        = var.state
  locality     = var.locality
  organization = var.organization
  common_name  = var.common_name
  tags         = local.tags
}

################## Secrets ######################
module "secret_telegram_token" {
  source       = "./modules/secret-manager"
  env          = var.env
  prefix       = var.prefix
  secret_name  = var.telegram_token_name
  secret_value = jsonencode({
    TELEGRAM_TOKEN = var.telegram_token_value
  })
  tags         = local.tags
}

module "secret_sub_domain_cert" {
  source       = "./modules/secret-manager"
  env          = var.env
  prefix       = var.prefix
  secret_name  = var.domain_certificate_name
  secret_value = module.sub_domain_and_cert.certificate_body
  tags         = local.tags
}

################ SQS Queues ####################
module "identify_queue" {
  source     = "./modules/sqs-queue"
  env        = var.env
  prefix     = var.prefix
  queue_name = var.identify_queue_name
  tags       = local.tags
}

module "results_queue" {
  source     = "./modules/sqs-queue"
  env        = var.env
  prefix     = var.prefix
  queue_name = var.results_queue_name
  tags       = local.tags
}

################ DynamoDB ####################

module "dynamodb" {
  source = "./modules/dynamodb"

  env                      = var.env
  prefix                   = var.prefix
  table_name               = var.table_name
  billing_mode             = var.billing_mode
  hash_key                 = var.hash_key
  read_capacity            = var.read_capacity
  write_capacity           = var.write_capacity
  global_secondary_indexes = var.global_secondary_indexes
  attributes               = var.attributes
  tags                     = local.tags
}

################### ECR #######################

module "ecr_and_policy" {
  source               = "./modules/ecr-and-policy"

  env                  = var.env
  prefix               = var.prefix
  ecr_name             = var.ecr_name
  image_tag_mutability = var.image_tag_mutability
  policy               = jsonencode(var.ecr_lifecycle_policy)
  tags                 = local.tags
}

################## IAM Role ######################

module "iam_role" {
  source             = "./modules/iam-role-and-policy"

  env                = var.env
  prefix             = var.prefix
  iam_role_name      = var.iam_role_name
  assume_role_policy = jsonencode({
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
  })

  iam_role_policy_name = var.iam_role_policy_name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "GetAuthTokenECR",
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken"
        ],
        Resource = "*"
      },
      {
        Sid = "ReadOnlyFromECR",
        Effect = "Allow",
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:GetLifecyclePolicy",
          "ecr:GetLifecyclePolicyPreview",
          "ecr:ListTagsForResource",
          "ecr:DescribeImageScanFindings"
        ],
        Resource = module.ecr_and_policy.ecr_arn
      },
      {
        Sid = "ListBucketContents",
        Effect = "Allow",
        Action = [
          "s3:ListBucket"
        ],
        Resource = module.s3_bucket.s3_bucket_arn,
        Condition = {
          StringLike = {
            "s3:prefix" = [
              "images/*"
            ]
          }
        }
      },
      {
        Sid = "GetObjectAndPutObject",
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ],
        Resource = "${module.s3_bucket.s3_bucket_arn}/images/*"
      },
      {
        Sid = "ReadWriteToDynamoDB",
        Effect = "Allow",
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem"
        ],
        Resource = module.dynamodb.table_arn
      },
      {
        Sid = "SQSSendMessages",
        Effect = "Allow",
        Action = "sqs:SendMessage",
        Resource = [
          module.identify_queue.sqs_queue_arn,
          module.results_queue.sqs_queue_arn
        ]
      },
      {
        Sid = "SQSReceiveDeleteMessages",
        Effect = "Allow",
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:ChangeMessageVisibility"
        ],
        Resource = [
          module.identify_queue.sqs_queue_arn,
          module.results_queue.sqs_queue_arn
        ]
      },
      {
        Sid = "SQSViewAttributes",
        Effect = "Allow",
        Action = [
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl"
        ],
        Resource = [
          module.identify_queue.sqs_queue_arn,
          module.results_queue.sqs_queue_arn
        ]
      },
      {
        Sid = "ReadSpecificSecret",
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Resource = [
          module.secret_telegram_token.secret_arn,
          module.secret_sub_domain_cert.secret_arn
        ]
      },
      {
        Sid = "Allow SSM Management"
        Effect = "Allow",
        Action = [
            "ssm:UpdateInstanceInformation",
            "ssm:ListInstanceAssociations",
            "ssm:DescribeInstanceProperties",
            "ssm:DescribeDocumentParameters",
            "ssm:GetManifest",
            "ssm:GetDeployablePatchSnapshotForInstance",
            "ssm:GetDocument",
            "ssm:DescribeDocument",
            "ssm:GetCommandInvocation",
            "ssm:ListCommands",
            "ssm:ListCommandInvocations",
            "ssm:PutInventory",
            "ssm:PutComplianceItems",
            "ssm:PutConfigurePackageResult",
            "ssm:UpdateAssociationStatus",
            "ssm:UpdateInstanceAssociationStatus",
            "ssm:UpdateInstanceInformation"
        ],
        Resource = "*"
      }
    ]
  })

  iam_instance_profile_name = var.iam_instance_profile_name

  tags = local.tags
}

################ EC2 Key Pair ####################

module "ec2_key_pair" {
  source        = "./modules/ec2-key-pair"
  env           = var.env
  region        = var.region
  prefix        = var.prefix
  key_pair_name = var.key_pair_name
  tags          = local.tags
}

################## Polybot #######################

module "polybot" {
  source                    = "./modules/polybot"
  env                       = var.env
  region                    = var.region
  prefix                    = var.prefix
  instance_name             = var.polybot_instance_name
  azs                       = local.azs
  # ami                       = data.aws_ami.ubuntu.id
  ami                       = local.ami_id
  instance_type             = var.polybot_instance_type
  image_prefix              = var.polybot_image_prefix
  key_pair_name             = module.ec2_key_pair.key_pair_name
  public_subnets            = module.vpc.public_subnets
  iam_instance_profile_name = module.iam_role.iam_instance_profile_name
  vpc_id                    = module.vpc.vpc_id
  alb_security_group_ingress_rules = var.alb_security_group_ingress_rules
  alb_security_group_egress_rules  = var.alb_security_group_egress_rules
  referenced_security_group_id     = module.vpc.default_security_group_id
  alb_listeners                    = var.alb_listeners
  certificate_arn                  = module.sub_domain_and_cert.certificate_arn
  alb_target_groups                = var.alb_target_groups
  alb_additional_target_group_attachments = var.alb_additional_target_group_attachments
  ec2_sg_ingress_rules             = var.polybot_ec2_sg_ingress_rules
  ec2_sg_egress_rules              = var.polybot_ec2_sg_egress_rules
  tags                             = local.tags
}

################### Yolo5 ########################

module "yolo5" {
  source                    = "./modules/yolo5"
  env                       = var.env
  region                    = var.region
  prefix                    = var.prefix
  instance_name             = var.yolo5_instance_name
  azs                       = local.azs
  # ami                       = data.aws_ami.ubuntu.id
  ami                       = local.ami_id
  instance_type             = var.yolo5_instance_type
  image_prefix              = var.yolo5_image_prefix
  key_pair_name             = module.ec2_key_pair.key_pair_name
  public_subnets            = module.vpc.public_subnets
  iam_instance_profile_name = module.iam_role.iam_instance_profile_name
  vpc_id                    = module.vpc.vpc_id
  ec2_sg_ingress_rules      = var.yolo5_ec2_sg_ingress_rules
  ec2_sg_egress_rules       = var.yolo5_ec2_sg_egress_rules
  ecr_name                  = module.ecr_and_policy.ecr_name
  telegram_app_url          = "https://${module.sub_domain_and_cert.sub_domain_name}"
  telegram_secret_name      = module.secret_telegram_token.secret_name
  sub_domain_secret_name    = module.secret_sub_domain_cert.secret_name
  identify_queue_name       = module.identify_queue.sqs_queue_name
  results_queue_name        = module.results_queue.sqs_queue_name
  s3_bucket_name            = local.s3_bucket_name
  s3_bucket_prefix          = var.s3_bucket_prefix
  table_name                = module.dynamodb.table_name
  ecr_repository_url        = module.ecr_and_policy.ecr_url
  sns_protocol              = var.sns_protocol
  sns_endpoint              = var.sns_endpoint
  tags                      = local.tags
}