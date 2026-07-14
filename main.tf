# ── Key pair ─────────────────────────────────────────────────────────────────
resource "aws_key_pair" "deploy" {
  key_name   = var.key_pair_name
  public_key = file(var.public_key_path)

  tags = {
    Name = "${var.project_name}-key-pair"
  }
}

# ── Security group ────────────────────────────────────────────────────────────
resource "aws_security_group" "app_sg" {
  name        = "${var.project_name}-sg"
  description = "Allow SSH and application traffic for the CI/CD demo"

  # SSH — restrict to your IP in production
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  # Flask application port
  ingress {
    description = "Flask App"
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP (optional — for future reverse-proxy setup)
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg"
  }
}

# ── EC2 instance ──────────────────────────────────────────────────────────────
resource "aws_instance" "app_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.deploy.key_name
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  # Bootstrap script: install Git, Docker, clone the repo, and mark it ready.
  # Docker Compose v2 is available as a Docker CLI plugin on Ubuntu 22.04.
  user_data = <<-EOF
    #!/bin/bash
    set -e
    apt-get update -y
    apt-get install -y git curl

    # Install Docker Engine
    curl -fsSL https://get.docker.com | sh
    usermod -aG docker ubuntu
    systemctl enable docker
    systemctl start docker

    # Clone the repository so deploy.sh has somewhere to pull into
    su - ubuntu -c "git clone https://github.com/YOUR_GITHUB_USERNAME/cicd-pipeline.git ~/cicd-pipeline"

    echo "Bootstrap complete — instance is ready for CI/CD deployments."
  EOF

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
    encrypted             = true
  }

  tags = {
    Name = "${var.project_name}-server"
  }
}

# ── Elastic IP ────────────────────────────────────────────────────────────────
resource "aws_eip" "app_eip" {
  instance = aws_instance.app_server.id
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-eip"
  }
}
