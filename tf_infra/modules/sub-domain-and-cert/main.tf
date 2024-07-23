data "aws_route53_zone" "int_devops_click" {
  name         = "int-devops.click."
  private_zone = false
}

data "external" "generate_certificate" {
  program = ["/bin/bash", "${path.module}/generate_certificate.sh", var.country, var.state, var.locality, var.organization, var.common_name]
}

locals {
  domain_id = data.aws_route53_zone.int_devops_click.zone_id
  cert      = data.external.generate_certificate.result["cert_file"]
  key       = data.external.generate_certificate.result["key_file"]
}

resource "aws_acm_certificate" "acm_cert" {
  # domain_name       = var.common_name
  # validation_method = "DNS"

  certificate_body = local.cert
  private_key      = local.key

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
    name                   = aws_acm_certificate.acm_cert.domain_name
    zone_id                = local.domain_id
    evaluate_target_health = false
  }
}
