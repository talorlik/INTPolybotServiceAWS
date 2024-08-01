locals {
  iam_role_name             = "${var.prefix}-${var.iam_role_name}-${var.env}"
  iam_role_policy_name      = "${var.prefix}-${var.iam_role_policy_name}-${var.env}"
  iam_instance_profile_name = "${var.prefix}-${var.iam_instance_profile_name}-${var.env}"
  policy = templatefile("${path.module}/${var.policy_template}", {
    ecr_arn                    = var.ecr_arn,
    s3_bucket_arn              = var.s3_bucket_arn,
    dynamodb_table_arn         = var.dynamodb_table_arn,
    identify_queue_arn         = var.identify_queue_arn,
    results_queue_arn          = var.results_queue_arn,
    telegram_token_secret_arn  = var.telegram_token_secret_arn,
    sub_domain_cert_secret_arn = var.sub_domain_cert_secret_arn
  })
}

resource "aws_iam_role" "iam_role" {
  name               = local.iam_role_name
  assume_role_policy = jsonencode(var.assume_role_policy)

  tags = merge(
    {
      Name = local.iam_role_name
    },
    var.tags
  )
}

resource "aws_iam_role_policy" "iam_role_policy" {
  name   = local.iam_role_policy_name
  role   = aws_iam_role.iam_role.id
  policy = local.policy
}

resource "aws_iam_instance_profile" "iam_instance_profile" {
  name = local.iam_instance_profile_name
  role = aws_iam_role.iam_role.name
}
