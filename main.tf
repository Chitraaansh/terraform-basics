terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}

# Replace with your existing key pair name in AWS
variable "key_name" {
  default = "testkeypair"  # Make sure this key exists in AWS Key Pairs
}

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Create security group allowing SSH
resource "aws_security_group" "ssh_access" {
  name        = "allow_ssh"
  description = "Allow SSH access"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Open to all — restrict in production
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# S3 Bucket (name must be globally unique)
resource "aws_s3_bucket" "my_bucket" {
  bucket = "my-terraform-bucket-chitransh-001"
  force_destroy = true
}

# Upload file to S3
resource "aws_s3_object" "file_upload" {
  bucket = aws_s3_bucket.my_bucket.bucket
  key    = "myfile.txt"
  source = "${path.module}/myfile.txt"
  etag   = filemd5("${path.module}/myfile.txt")
}

# IAM Role for EC2 to access S3
resource "aws_iam_role" "ec2_s3_role" {
  name = "ec2_s3_access_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# IAM Policy for S3 access
resource "aws_iam_role_policy" "s3_access" {
  name = "s3_access_policy"
  role = aws_iam_role.ec2_s3_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["s3:GetObject"],
        Resource = "arn:aws:s3:::${aws_s3_bucket.my_bucket.bucket}/*"
      }
    ]
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_s3_profile"
  role = aws_iam_role.ec2_s3_role.name
}

# EC2 Instance
resource "aws_instance" "my_ec2_test" {
  ami                    = "ami-020cba7c55df1f615" 
  instance_type          = "t2.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.ssh_access.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash

              # Log everything
              exec > /home/ubuntu/init.log 2>&1

              echo "Updating packages..."
              apt-get update -y

              echo "Installing unzip and curl..."
              apt-get install -y unzip curl

              echo "Installing AWS CLI from official installer..."
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip
              ./aws/install

              echo "Downloading file from S3..."
              /usr/local/bin/aws s3 cp s3://${aws_s3_bucket.my_bucket.bucket}/${aws_s3_object.file_upload.key} /home/ubuntu/myfile.txt

              echo "Setting permissions..."
              chown ubuntu:ubuntu /home/ubuntu/myfile.txt

              echo "Done!"
        EOF

  tags = {
    Name = "TerraformInstance"
  }
}

# Output Public IP
output "ec2_public_ip" {
  value = aws_instance.my_ec2_test.public_ip
}
