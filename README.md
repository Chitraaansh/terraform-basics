# ☁️ AWS EC2 + S3 Automation with Terraform

This Terraform project provisions:
- An **EC2 instance** (Ubuntu-based)
- An **S3 bucket** (with a file uploaded from local disk)
- A **secure IAM role** allowing the EC2 instance to download that file from the S3 bucket
- Boot-time **user_data** script to install AWS CLI on the EC2 and download the file

---

## 🏗️ Infrastructure Components

| Resource Type        | Description                                  |
|----------------------|----------------------------------------------|
| `aws_instance`       | Launches a t2.micro Ubuntu EC2 instance      |
| `aws_s3_bucket`      | Creates an S3 bucket                         |
| `aws_s3_object`      | Uploads a file (`myfile.txt`) to the bucket |
| `aws_iam_role`       | Grants EC2 access to the S3 bucket           |
| `aws_security_group` | Allows SSH access (port 22) from anywhere    |

---
