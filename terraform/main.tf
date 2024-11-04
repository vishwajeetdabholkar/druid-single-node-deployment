# Provider configuration
provider "aws" {
  region = var.aws_region
}

# Variables
variable "aws_region" {
  description = "AWS region for deploying resources"
  type        = string
}

variable "key_name" {
  description = "Name of the AWS key pair to use for SSH access"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "security_group_id" {
  description = "ID of the security group"
  type        = string
}

variable "storage_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 50
}

variable "host_ip" {
  description = "IP address of the host running the deployment"
  type        = string
}

variable "tags" {
  description = "Tags for the EC2 instance"
  type        = map(string)
}

# Data source for AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "image-id"
    values = ["ami-005fc0f236362e99f"]
  }
}

# Data source for subnets
data "aws_subnets" "available" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

# Update security group rule
resource "aws_security_group_rule" "allow_host_access" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["${var.host_ip}/32"]
  security_group_id = var.security_group_id
  description       = "Allow SSH access from deployment host"
}

# EC2 instance
resource "aws_instance" "ec2_instance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = data.aws_subnets.available.ids[0]

  vpc_security_group_ids = [var.security_group_id]

  root_block_device {
    volume_size = var.storage_size
    volume_type = "gp3"
    encrypted   = true
    tags        = var.tags
  }

  tags = merge(var.tags, {
    created_by = "terraform"
    created_at = timestamp()
  })

  user_data = <<-EOF
              #!/bin/bash
              sudo -s
              ${file("install_dependencies.sh")}
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

# Outputs
output "instance_id" {
  value       = aws_instance.ec2_instance.id
  description = "ID of the created EC2 instance"
}

output "public_ip" {
  value       = aws_instance.ec2_instance.public_ip
  description = "Public IP of the EC2 instance"
}

output "private_ip" {
  value       = aws_instance.ec2_instance.private_ip
  description = "Private IP of the EC2 instance"
}