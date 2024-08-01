# Output EC2 instance IDs
output "polybot_ec2_ids" {
  description = "List of Polybot EC2 instance IDs"
  value       = { for key, instance in aws_instance.polybot_ec2 : key => instance.id }
}

# Output EC2 instance Public IPs
output "polybot_ec2_public_ips" {
  description = "List of Polybot EC2 instance Public IPs"
  value       = { for key, instance in aws_instance.polybot_ec2 : key => instance.public_ip }
}

output "image_prefix" {
  description = "The ECR Image prefix"
  value       = var.image_prefix
}

output "alb_dns_name" {
  description = "The ALB's DNS name"
  value       = module.alb.dns_name
}

output "alb_zone_id" {
  description = "The ALB's Zone ID"
  value       = module.alb.zone_id
}