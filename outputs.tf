output "instance_id" {
  description = "EC2 instance ID."
  value       = aws_instance.app_server.id
}

output "elastic_ip" {
  description = "Elastic IP address assigned to the EC2 instance. Use this as EC2_HOST in GitHub Secrets."
  value       = aws_eip.app_eip.public_ip
}

output "application_url" {
  description = "Direct URL to the running Flask application."
  value       = "http://${aws_eip.app_eip.public_ip}:${var.app_port}"
}

output "ssh_command" {
  description = "SSH command to connect to the EC2 instance."
  value       = "ssh -i ~/.ssh/id_rsa ubuntu@${aws_eip.app_eip.public_ip}"
}

output "security_group_id" {
  description = "Security group ID."
  value       = aws_security_group.app_sg.id
}
