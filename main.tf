terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 4.16"
    }
}
required_version = ">= 1.2.0"
}

provider "aws" {
    region = "us-east-1"
}

resource "aws_instance" "my_ec2_test" {
    ami = "ami-020cba7c55df1f615"
    instance_type = "t2.micro"
    tags = {
        Name = "TerraformInstance"
    }
  
}

output "ec2_public_ips" {
    value = aws_instance.my_ec2_test.public_ip
}