output "key_pair_name" {
  value = aws_key_pair.ec2_key_pair.key_name
}

output "pem_file_path" {
  value = "${path.module}/${var.region}/${var.env}/${var.prefix}-${var.key_pair_name}.pem"
}

output "pub_file_path" {
  value = "${path.module}/${var.region}/${var.env}/${var.prefix}-${var.key_pair_name}.pub"
}