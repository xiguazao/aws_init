output "instance_ids" {
  description = "List of EC2 instance IDs"
  value = concat(
    aws_instance.web[*].id,
    aws_instance.app[*].id
  )
}

output "public_ips" {
  description = "List of EC2 public IPs"
  value       = aws_instance.web[*].public_ip
}

output "private_ips" {
  description = "List of EC2 private IPs"
  value = concat(
    aws_instance.web[*].private_ip,
    aws_instance.app[*].private_ip
  )
}