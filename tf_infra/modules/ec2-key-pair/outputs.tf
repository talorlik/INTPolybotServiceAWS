output "key_pair_name" {
  value = aws_key_pair.ec2_key_pair.key_name
}

output "pem_file_path" {
  value = local_file.private_key.filename
}

output "pub_file_path" {
  value = local_file.public_key.filename
}