output "certificate_id" {
  value = aws_acm_certificate.acm_cert.id
}

output "certificate_arn" {
  value = aws_acm_certificate.acm_cert.arn
}

# output "certificate_body" {
#   value = local.cert
# }
output "certificate_body" {
  value = aws_acm_certificate.acm_cert.certificate_body
}

output "sub_domain_id" {
  value = aws_route53_record.route53_record.id
}

output "sub_domain_name" {
  value = aws_route53_record.route53_record.name
}

output "country" {
  value = var.country
}

output "state" {
  value = var.state
}

output "locality" {
  value = var.locality
}

output "organization" {
  value = var.organization
}

output "common_name" {
  value = var.common_name
}