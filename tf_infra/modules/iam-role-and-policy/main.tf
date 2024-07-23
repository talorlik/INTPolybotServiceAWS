locals {
  iam_role_name             = "${var.prefix}-${var.iam_role_name}-${var.env}"
  iam_role_policy_name      = "${var.prefix}-${var.iam_role_policy_name}-${var.env}"
  iam_instance_profile_name = "${var.prefix}-${var.iam_instance_profile_name}-${var.env}"
}

resource "aws_iam_role" "iam_role" {
  name = local.iam_role_name
  assume_role_policy = var.assume_role_policy

  tags = merge(
    {
      Name = local.iam_role_name
    },
    var.tags
  )
}

resource "aws_iam_role_policy" "iam_role_policy" {
  name = local.iam_role_policy_name
  role = aws_iam_role.iam_role.id
  policy = var.policy
}

resource "aws_iam_instance_profile" "iam_instance_profile" {
  name = local.iam_instance_profile_name
  role = aws_iam_role.iam_role.name
}
