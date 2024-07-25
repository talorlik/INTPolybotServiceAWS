output "region" {
  description = "The AWS region"
  value = var.region
}

output "env" {
  description = "The Environment e.g. prod"
  value = var.env
}

###################### VPC ######################
output "vpc_id" {
  description = "The VPC's ID"
  value = module.vpc.vpc_id
}

output "default_security_group_id" {
  description = "The default security group for the VPC"
  value = module.vpc.default_security_group_id
}

output "public_subnets" {
  description = "The VPC's associated public subnets."
  value = module.vpc.public_subnets
}

################### S3 ##########################

output "s3_bucket_name" {
  description = "The name of the S3 bucket"
  value       = local.s3_bucket_name
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = module.s3_bucket.s3_bucket_arn
}

output "s3_bucket_prefix" {
  description = "The folder name that where the images are"
  value = var.s3_bucket_prefix
}

############# Sub-Domian / Cert ##################

output "certificate_body" {
  value = module.sub_domain_and_cert.certificate_body
}

output "sub_domain_id" {
  value = module.sub_domain_and_cert.sub_domain_id
}

output "sub_domain_name" {
  value = module.sub_domain_and_cert.sub_domain_name
}

output "country" {
  value = module.sub_domain_and_cert.country
}

output "state" {
  value = module.sub_domain_and_cert.state
}

output "locality" {
  value = module.sub_domain_and_cert.locality
}

output "organization" {
  value = module.sub_domain_and_cert.organization
}

output "common_name" {
  value = module.sub_domain_and_cert.common_name
}

################### Secrets #####################

output "telegram_secret_name" {
  value = module.secret_telegram_token.secret_name
}

output "telegram_secret_arn" {
  value = module.secret_telegram_token.secret_arn
}

output "sub_domain_secret_name" {
  value = module.secret_sub_domain_cert.secret_name
}

output "sub_domain_secret_arn" {
  value = module.secret_sub_domain_cert.secret_arn
}

################## SQS #######################

output "identify_queue_name" {
  value = module.identify_queue.sqs_queue_name
}

output "identify_queue_arn" {
  value = module.identify_queue.sqs_queue_arn
}

output "results_queue_name" {
  value = module.results_queue.sqs_queue_name
}

output "results_queue_arn" {
  value = module.results_queue.sqs_queue_arn
}

############### DynamoDB ####################

output "table_name" {
  value = module.dynamodb.table_name
}

output "table_arn" {
  value = module.dynamodb.table_arn
}

################## ECR #######################

output "ecr_repository_name" {
  value = module.ecr_and_policy.ecr_name
}

output "ecr_repository_arn" {
  value = module.ecr_and_policy.ecr_arn
}

output "ecr_repository_url" {
  value = module.ecr_and_policy.ecr_url
}

############### IAM Role ####################

output "iam_role_name" {
  value = module.iam_role.iam_role_name
}

output "iam_role_arn" {
  value = module.iam_role.iam_role_arn
}

output "iam_instance_profile_name" {
  value = module.iam_role.iam_instance_profile_name
}

############# EC2 Key Pair ##################

output "key_pair_name" {
  value = module.ec2_key_pair.key_pair_name
}

output "pem_file_path" {
  value = module.ec2_key_pair.pem_file_path
}

output "pub_file_path" {
  value = module.ec2_key_pair.pub_file_path
}

############## Polybot ######################

output "polybot_ec2_ids" {
  description = "List of Polybot EC2 instance IDs"
  value       = module.polybot.polybot_ec2_ids
}

output "polybot_ec2_public_ips" {
  description = "List of Polybot EC2 instance Public IPs"
  value       = module.polybot.polybot_ec2_public_ips
}

output "polybot_image_prefix" {
  description = "The ECR Image prefix"
  value       = module.polybot.image_prefix
}

############### Yolo5 #######################

output "yolo5_image_prefix" {
  description = "The ECR Image prefix"
  value       = module.yolo5.image_prefix
}
