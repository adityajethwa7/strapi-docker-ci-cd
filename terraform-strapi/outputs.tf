# outputs.tf
output "ec2_public_ip" {
  description = "Elastic IP address of the EC2 instance"
  value       = aws_eip.strapi_eip.public_ip
}

output "ec2_instance_id" {
  description = "Instance ID of the EC2 instance"
  value       = aws_instance.strapi_server.id
}

output "strapi_url" {
  description = "URL to access Strapi (port 80)"
  value       = "http://${aws_eip.strapi_eip.public_ip}"
}

output "strapi_admin_url" {
  description = "URL to access Strapi Admin"
  value       = "http://${aws_eip.strapi_eip.public_ip}/admin"
}

output "ssh_connection_string" {
  description = "SSH connection string"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${aws_eip.strapi_eip.public_ip}"
}

output "environment" {
  description = "Deployment environment"
  value       = var.environment
}

output "database_info" {
  description = "Database connection info"
  value = {
    type     = "PostgreSQL"
    host     = "postgres (internal)"
    port     = 5432
    database = "strapi"
    username = "strapi"
  }
  sensitive = true
}