# main.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Create VPC
resource "aws_vpc" "strapi_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "strapi-vpc-${var.environment}"
    Environment = var.environment
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "strapi_igw" {
  vpc_id = aws_vpc.strapi_vpc.id

  tags = {
    Name        = "strapi-igw-${var.environment}"
    Environment = var.environment
  }
}

# Create Subnet
resource "aws_subnet" "strapi_subnet" {
  vpc_id                  = aws_vpc.strapi_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "strapi-subnet-${var.environment}"
    Environment = var.environment
  }
}

# Data source to get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Create Route Table
resource "aws_route_table" "strapi_rt" {
  vpc_id = aws_vpc.strapi_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.strapi_igw.id
  }

  tags = {
    Name        = "strapi-route-table-${var.environment}"
    Environment = var.environment
  }
}

# Associate Route Table
resource "aws_route_table_association" "strapi_rta" {
  subnet_id      = aws_subnet.strapi_subnet.id
  route_table_id = aws_route_table.strapi_rt.id
}

# Create Security Group
resource "aws_security_group" "strapi_sg" {
  name        = "strapi-security-group-${var.environment}"
  description = "Security group for Strapi application"
  vpc_id      = aws_vpc.strapi_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access for Strapi"
  }

  # Removed port 1337 - not needed since we're mapping 80:1337 in docker-compose

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "strapi-security-group-${var.environment}"
    Environment = var.environment
  }
}

# Get latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create EC2 Instance
resource "aws_instance" "strapi_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = aws_subnet.strapi_subnet.id
  
  vpc_security_group_ids = [aws_security_group.strapi_sg.id]

  user_data = templatefile("${path.module}/user_data.sh", {
    docker_image = var.docker_image
    db_password  = var.db_password
    environment  = var.environment
  })

  root_block_device {
    volume_size = 20  # Increased from 8 to 20 GB for better performance
    volume_type = "gp3"  # Changed to gp3 for better performance
  }

  tags = {
    Name        = "strapi-server-${var.environment}"
    Environment = var.environment
    Type        = "free-tier-eligible"
  }
}

# Elastic IP for consistent public IP
resource "aws_eip" "strapi_eip" {
  instance = aws_instance.strapi_server.id
  domain   = "vpc"

  tags = {
    Name        = "strapi-eip-${var.environment}"
    Environment = var.environment
  }
}