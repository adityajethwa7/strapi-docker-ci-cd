# variables.tf
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"  # Changed to us-east-2
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "AWS Key Pair name"
  type        = string
}

variable "docker_image" {
  description = "Docker image for Strapi"
  type        = string
  default     = "adityajethwa7/strapi-app:latest"
}

variable "db_password" {
  description = "Database password"
  type        = string
  default     = "strapi123"
  sensitive   = true
}