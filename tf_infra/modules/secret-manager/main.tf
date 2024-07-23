locals {
  secret_name = "${var.prefix}/${var.secret_name}/${var.env}"
}

resource "aws_secretsmanager_secret" "sm_secret" {
  name = local.secret_name

  tags = merge(
    {
      Name = local.secret_name
    },
    var.tags
  )
}

resource "aws_secretsmanager_secret_version" "sm_secret_version" {
  secret_id     = aws_secretsmanager_secret.sm_secret.id
  secret_string = var.secret_value
}