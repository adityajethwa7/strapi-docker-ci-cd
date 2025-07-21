# outputs.tf
output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.strapi_server.public_ip
}

output "instance_public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = aws_instance.strapi_server.public_dns
}

output "strapi_url" {
  description = "URL to access Strapi"
  value       = "http://${aws_instance.strapi_server.public_ip}"
}

output "strapi_admin_url" {
  description = "URL to access Strapi Admin"
  value       = "http://${aws_instance.strapi_server.public_ip}/admin"
}