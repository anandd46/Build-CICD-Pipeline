# ── AWS credentials ───────────────────────────────────────────────────────────
variable "aws_access_key" {
  description = "AWS access key ID. Store in terraform.tfvars or pass via TF_VAR_aws_access_key."
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS secret access key."
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-east-1"
}

# ── Instance ──────────────────────────────────────────────────────────────────
variable "instance_type" {
  description = "EC2 instance type."
  type        =  string
  default     = "t2.micro"
}

variable "ami_id" {
  description = " Ubuntu 22.04 LTS AMI ID. Update for your region."
  type        = string
  # Ubuntu 22.04 LTS (us-east-1) — verify latest at https://cloud-images.ubuntu.com/locator/ec2/
  default = "ami-0c7217cdde317cfec"
}

variable "key_pair_name" {
  description = "Name of the AWS key pair to associate with the EC2 instance."
  type        = string
}

variable "public_key_path" {
  description = "Path to the public key file to upload as an AWS key pair."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

# ── Networking ────────────────────────────────────────────────────────────────
variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to connect on port 22. Restrict to your IP in production."
  type        = string
  default     = "0.0.0.0/0"
}

variable "app_port" {
  description = "Port the Flask application listens on."
  type        = number
  default     = 5000
}

# ── Project metadata ─────────────────────────────────────────────────────────
variable "project_name" {
  description = "Project tag applied to all resources."
  type        = string
  default     = "cicd-pipeline"
}

variable "environment" {
  description = "Deployment environment tag."
  type        = string
  default     = "production"
}
