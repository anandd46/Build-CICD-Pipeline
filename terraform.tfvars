# terraform.tfvars — fill in your real values and NEVER commit this file to Git.
# The .gitignore already excludes *.tfvars; verify before pushing.

aws_access_key   = "YOUR_AWS_ACCESS_KEY_ID"
aws_secret_key   = "YOUR_AWS_SECRET_ACCESS_KEY"
aws_region       = "us-east-1"

# Ubuntu 22.04 LTS AMI — verify the latest ID for your region:
# https://cloud-images.ubuntu.com/locator/ec2/
ami_id           = "ami-0c7217cdde317cfec"

instance_type    = "t2.micro"
key_pair_name    = "cicd-pipeline-key"
public_key_path  = "~/.ssh/id_rsa.pub"

# Restrict to your own IP in production: "203.0.113.10/32"
allowed_ssh_cidr = "0.0.0.0/0"

app_port         = 5000
project_name     = "cicd-pipeline"
environment      = "production"
