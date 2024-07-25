data "aws_route53_zone" "int_devops_click" {
  name         = "int-devops.click."
  private_zone = false
}

# data "external" "generate_certificate" {
#   program = ["/bin/bash", "${path.module}/generate_certificate.sh", var.country, var.state, var.locality, var.organization, var.common_name]
# }

# locals {
#   cert      = data.external.generate_certificate.result["cert_file"]
#   key       = data.external.generate_certificate.result["key_file"]
# }

locals {
  domain_id   = data.aws_route53_zone.int_devops_click.zone_id
  domain_name = data.aws_route53_zone.int_devops_click.name
}

resource "tls_private_key" "pkey" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "ss_cert" {
  private_key_pem = tls_private_key.pkey.private_key_pem

  subject {
    country      = var.country
    province     = var.state
    locality     = var.locality
    organization = var.organization
    common_name  = var.common_name
  }

  validity_period_hours = 8760

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_acm_certificate" "acm_cert" {
  # private_key      = local.key
  # certificate_body = local.cert
  private_key      = tls_private_key.pkey.private_key_pem
  certificate_body = tls_self_signed_cert.ss_cert.cert_pem

  tags = merge(
    {
      Name = var.common_name
    },
    var.tags
  )
}

resource "aws_route53_record" "route53_record" {
  zone_id = local.domain_id
  name    = var.common_name
  type    = "A"

  alias {
    name                   = local.domain_name
    zone_id                = local.domain_id
    evaluate_target_health = false
  }
}
