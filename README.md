# CI/CD Pipeline with GitHub Actions, Docker & AWS EC2

[![CI/CD Pipeline](https://github.com/anandd46/Build-CICD-Pipeline/actions/workflows/cicd.yml/badge.svg)](https://github.com/anandd46/Build-CICD-Pipeline/actions)
[![Python 3.12](https://img.shields.io/badge/Python-3.12-blue?logo=python)](https://www.python.org/)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?logo=docker)](https://www.docker.com/)
[![Terraform](https://img.shields.io/badge/Terraform-1.7+-7B42BC?logo=terraform)](https://www.terraform.io/)
[![AWS EC2](https://img.shields.io/badge/AWS-EC2-FF9900?logo=amazon-aws)](https://aws.amazon.com/ec2/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A production-style CI/CD pipeline that automatically tests, packages, and deploys a Flask web application to AWS EC2 using GitHub Actions and Docker — zero manual steps after the first push.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Features](#features)
3. [Architecture](#architecture)
4. [Real-World Use Case](#real-world-use-case)
5. [Technologies Used](#technologies-used)
6. [Repository Structure](#repository-structure)
7. [Application Workflow](#application-workflow)
8. [CI/CD Workflow](#cicd-workflow)
9. [GitHub Actions Workflow Explanation](#github-actions-workflow-explanation)
10. [Docker Workflow](#docker-workflow)
11. [Infrastructure Provisioning](#infrastructure-provisioning)
12. [Terraform Explanation](#terraform-explanation)
13. [EC2 Configuration](#ec2-configuration)
14. [Deployment Process](#deployment-process)
15. [Step-by-Step Setup Guide](#step-by-step-setup-guide)
16. [GitHub Secrets](#github-secrets)
17. [Deployment Commands](#deployment-commands)
18. [Troubleshooting Guide](#troubleshooting-guide)
19. [Security Best Practices](#security-best-practices)
20. [Best Practices Followed](#best-practices-followed)
21. [Future Improvements](#future-improvements)
22. [Resume Description](#resume-description)
23. [Skills Demonstrated](#skills-demonstrated)

---

## Project Overview

This project wires together the four tools that appear most often in DevOps job descriptions — GitHub Actions, Docker, AWS EC2, and Terraform — into a single end-to-end automated delivery pipeline.

Every time a developer pushes code to `main`, GitHub Actions takes over: it installs dependencies, runs the test suite, builds a Docker image, validates it with a live health check, SSHs into the EC2 instance, swaps the running container for the new image, and confirms the application is serving traffic — all without anyone logging into a server.

The Flask app itself is intentionally simple. The complexity lives in the pipeline and the infrastructure, which is where the engineering work is.

---

## Features

- **Fully automated deployments** — push to `main`, watch it go live
- **Multi-stage GitHub Actions pipeline** with 12 discrete steps across 3 jobs
- **Multi-stage Docker build** to keep the final image small and dependency-free
- **Non-root container** for improved runtime security
- **Terraform-managed infrastructure** — EC2, Security Group, Elastic IP, Key Pair
- **Health checks** at both the Docker layer and the pipeline layer
- **Concurrency control** — only one pipeline runs per branch at a time
- **PR-gated deploys** — deployments only trigger on direct pushes to `main`
- **Clean teardown and restart** on every deploy, preventing stale container state
- **Detailed logging** throughout deploy.sh with timestamps

---

## Architecture

### Overall Architecture

```mermaid
graph TD
    DEV[👨‍💻 Developer<br/>Local Machine]
    GH[📁 GitHub Repository<br/>Source of Truth]
    GA[⚙️ GitHub Actions<br/>CI/CD Runner]
    TEST[🧪 Unit Tests<br/>pytest]
    BUILD[🐳 Docker Build<br/>Image Validation]
    EC2[🖥️ AWS EC2<br/>Ubuntu 22.04]
    DOCKER[📦 Docker Container<br/>Flask + Gunicorn]
    EIP[🌐 Elastic IP<br/>Public Endpoint]
    USER[👥 End Users<br/>Browser / API]

    DEV -->|git push origin main| GH
    GH -->|webhook trigger| GA
    GA --> TEST
    TEST -->|pass| BUILD
    BUILD -->|SSH deploy| EC2
    EC2 --> DOCKER
    DOCKER --- EIP
    EIP -->|HTTP :5000| USER

    style DEV fill:#2d333b,color:#e6edf3
    style GH fill:#161b22,color:#58a6ff
    style GA fill:#0d1117,color:#3fb950
    style TEST fill:#161b22,color:#d2a8ff
    style BUILD fill:#161b22,color:#79c0ff
    style EC2 fill:#FF9900,color:#000000
    style DOCKER fill:#2496ED,color:#ffffff
    style EIP fill:#161b22,color:#f78166
    style USER fill:#2d333b,color:#e6edf3
```

### CI/CD Pipeline Flow

```mermaid
flowchart LR
    A([Push to main]) --> B[Checkout Code]
    B --> C[Setup Python 3.12]
    C --> D[Install Dependencies]
    D --> E{Run Tests}
    E -->|fail| FAIL([❌ Pipeline Stops])
    E -->|pass| F[Build Docker Image]
    F --> G[Validate Docker Build]
    G -->|health check fails| FAIL
    G -->|200 OK| H[SSH to EC2]
    H --> I[git pull on EC2]
    I --> J[Stop Old Container]
    J --> K[Build New Image]
    K --> L[Start New Container]
    L --> M{Health Check}
    M -->|fail| FAIL
    M -->|200 OK| SUCCESS([✅ Deployed])

    style A fill:#238636,color:#fff
    style FAIL fill:#da3633,color:#fff
    style SUCCESS fill:#238636,color:#fff
```

### GitHub Actions Workflow

```mermaid
flowchart TD
    subgraph JOB1["Job 1 — Test (ubuntu-latest)"]
        T1[Checkout Repository]
        T2[Setup Python 3.12]
        T3[Install pip dependencies]
        T4[pytest with coverage]
        T1 --> T2 --> T3 --> T4
    end

    subgraph JOB2["Job 2 — Build (needs: test)"]
        B1[Checkout Repository]
        B2[docker build ...]
        B3[docker run -d ...]
        B4[curl /health → 200]
        B5[docker stop + rm]
        B1 --> B2 --> B3 --> B4 --> B5
    end

    subgraph JOB3["Job 3 — Deploy (needs: build, main only)"]
        D1[Checkout Repository]
        D2[Write SSH key]
        D3[ssh-keyscan EC2]
        D4[git pull on EC2]
        D5[docker stop / rm]
        D6[docker build on EC2]
        D7[docker run on EC2]
        D8[curl remote /health]
        D9[rm SSH key]
        D1 --> D2 --> D3 --> D4 --> D5 --> D6 --> D7 --> D8 --> D9
    end

    JOB1 -->|all tests pass| JOB2
    JOB2 -->|image healthy| JOB3
```

---

## Real-World Use Case

This pattern is exactly how small-to-medium engineering teams ship software. A startup with a single EC2 instance can use this pipeline to get automated deployments without the complexity of ECS, Kubernetes, or a managed CI platform. Every concept here — SSH deploys, Docker image rebuilds, pipeline gates — transfers directly to more complex infrastructure. Engineers who understand this pipeline can read and extend a Jenkins or CircleCI config with minimal ramp-up.

---

## Technologies Used

| Tool | Version | Role |
|---|---|---|
| Python | 3.12 | Application runtime |
| Flask | 3.0.x | Web framework |
| Gunicorn | 22.x | Production WSGI server |
| pytest | 8.x | Unit testing |
| Docker | 25+ | Container runtime |
| Docker Compose | v2 | Local orchestration |
| GitHub Actions | N/A | CI/CD automation |
| Terraform | ≥ 1.7 | Infrastructure as Code |
| AWS EC2 | t2.micro | Compute host |
| AWS Elastic IP | N/A | Static public IP |
| Ubuntu | 22.04 LTS | EC2 operating system |
| Bash | 5.x | deploy.sh scripting |

---

## Repository Structure

```
cicd-pipeline/
├── app.py                  # Flask application — three routes: /, /health, /info
├── test_app.py             # pytest unit tests (25 test cases across 4 classes)
├── requirements.txt        # Python dependencies pinned to minor versions
├── Dockerfile              # Multi-stage build: builder + slim runtime
├── docker-compose.yml      # Local development and EC2 orchestration
├── .github-workflow.yml    # GitHub Actions pipeline (rename to cicd.yml in .github/workflows/)
├── deploy.sh               # Deployment script executed on EC2
├── provider.tf             # AWS Terraform provider config
├── versions.tf             # Terraform and provider version constraints
├── variables.tf            # All variable declarations with types and descriptions
├── terraform.tfvars        # Variable values (NOT committed — in .gitignore)
├── main.tf                 # EC2, Security Group, Elastic IP, Key Pair resources
├── outputs.tf              # Elastic IP, SSH command, application URL
├── .gitignore              # Excludes .tfvars, .terraform/, *.pem, __pycache__
├── LICENSE                 # MIT
└── README.md               # This file
```

> **GitHub Actions note:** GitHub reads workflows from `.github/workflows/`. After cloning, create that directory and copy `.github-workflow.yml` into it as `cicd.yml`:
> ```bash
> mkdir -p .github/workflows
> cp .github-workflow.yml .github/workflows/cicd.yml
> ```

---

## Application Workflow

The Flask app exposes three endpoints:

**`GET /`** — HTML dashboard showing deployment metadata:
- Deployment success banner
- Technology stack tags (GitHub Actions, Docker, AWS EC2)
- Runtime info: hostname, timestamp, Python version, container name, environment

**`GET /health`** — JSON health check used by Docker, GitHub Actions, and deploy.sh:
```json
{ "status": "healthy", "timestamp": "2025-01-15T10:30:00", "hostname": "abc123", "environment": "production" }
```

**`GET /info`** — JSON endpoint returning platform details:
```json
{ "python_version": "3.12.4", "platform": "Linux", "container": "flask-app", "environment": "production" }
```

### Application Request Flow

```mermaid
sequenceDiagram
    participant U as User (Browser)
    participant EC2 as AWS EC2
    participant G as Gunicorn
    participant F as Flask App

    U->>EC2: HTTP GET :5000/
    EC2->>G: Forward request
    G->>F: WSGI call
    F->>F: Build HTML with os/socket/datetime
    F-->>G: HTTP 200 + HTML
    G-->>EC2: Response
    EC2-->>U: HTML Dashboard

    U->>EC2: HTTP GET :5000/health
    EC2->>G: Forward request
    G->>F: WSGI call
    F-->>G: JSON { status: healthy }
    G-->>EC2: HTTP 200 + JSON
    EC2-->>U: Health response
```

---

## CI/CD Workflow

```mermaid
stateDiagram-v2
    [*] --> Push: Developer pushes to main
    Push --> Checkout: actions/checkout@v4
    Checkout --> SetupPython: actions/setup-python@v5
    SetupPython --> InstallDeps: pip install -r requirements.txt
    InstallDeps --> RunTests: pytest test_app.py -v
    RunTests --> TestFail: Tests fail
    RunTests --> DockerBuild: Tests pass
    TestFail --> [*]: Pipeline exits 1
    DockerBuild --> DockerVerify: Container health check
    DockerVerify --> VerifyFail: HTTP != 200
    DockerVerify --> SSHSetup: HTTP 200
    VerifyFail --> [*]: Pipeline exits 1
    SSHSetup --> GitPull: ssh → git pull
    GitPull --> StopContainer: docker stop + rm
    StopContainer --> BuildOnEC2: docker build
    BuildOnEC2 --> StartContainer: docker run -d
    StartContainer --> RemoteHealth: curl /health
    RemoteHealth --> HealthFail: HTTP != 200
    RemoteHealth --> Done: HTTP 200
    HealthFail --> [*]: Pipeline exits 1
    Done --> [*]: ✅ Deployed
```

---

## GitHub Actions Workflow Explanation

The pipeline lives in `.github/workflows/cicd.yml` and consists of three jobs that run in sequence.

### Triggers

```yaml
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
```

Pushes to `main` run all three jobs including deploy. PRs run only `test` and `build` — the deploy job is gated with `if: github.ref == 'refs/heads/main' && github.event_name == 'push'`.

### Concurrency

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

If two commits land in quick succession, the first pipeline is cancelled as soon as the second one starts. This prevents race conditions on the EC2 instance.

### Job 1 — test

Runs on every trigger. Sets up Python 3.12 with pip caching, installs pinned dependencies, then runs pytest with coverage. If any test fails, the pipeline stops here and jobs 2 and 3 never run.

**Stage 1 — Checkout:** `actions/checkout@v4` fetches the full commit history so `git log` works on EC2 after a pull.

**Stage 2 — Setup Python:** `actions/setup-python@v5` with `cache: pip` means subsequent runs skip the install if `requirements.txt` hasn't changed.

**Stage 3 — Install Dependencies:** Installs Flask, Gunicorn, pytest, and pytest-cov from the pinned requirements file.

**Stage 4 — Run Tests:** `pytest test_app.py -v --tb=short --cov=app` runs all 25 test cases and prints a coverage report. The `APP_ENV=testing` environment variable activates the test configuration.

### Job 2 — build

Runs only after `test` passes (`needs: test`). Builds the Docker image and runs it locally on the Actions runner to confirm it starts and responds correctly.

**Stage 5 — Build Docker Image:** `docker build` creates two tags — the commit SHA for traceability and `latest` for the deployment script.

**Stage 6 — Verify Docker Build:** Starts the container, waits 8 seconds for Gunicorn to bind, then hits `/health` with curl. A non-200 response triggers a `docker logs` dump and exits 1.

### Job 3 — deploy

Runs only on `push` to `main`, after `build` passes. All communication with EC2 happens over SSH.

**Stage 7 — Configure SSH:** Writes the private key from `secrets.SSH_PRIVATE_KEY` to `~/.ssh/deploy_key` with `chmod 600`. `ssh-keyscan` adds the EC2 host to `known_hosts` to avoid interactive prompts.

**Stage 8 — Pull Latest Code:** SSHs to the EC2 instance and runs `git pull origin main` inside the cloned repository directory.

**Stage 9 — Stop Existing Container:** `docker stop` and `docker rm` with `|| true` so the step doesn't fail if no container was running.

**Stage 10 — Build New Docker Image:** Rebuilds the image on EC2 from the freshly pulled code. Building on EC2 avoids the need to push to a registry.

**Stage 11 — Start New Container:** `docker run -d` with `--restart unless-stopped` so the container survives instance reboots.

**Stage 12 — Health Check:** Waits 10 seconds then hits the remote `/health` endpoint. This confirms the new container is actually serving traffic on the public IP before the pipeline reports success.

---

## Docker Workflow

```mermaid
flowchart TD
    subgraph BUILDER["Stage 1 — builder (python:3.12-slim)"]
        B1[apt-get install gcc]
        B2[pip wheel — build .whl files]
        B1 --> B2
    end

    subgraph RUNTIME["Stage 2 — runtime (python:3.12-slim)"]
        R1[Copy /wheels from builder]
        R2[pip install from local wheels]
        R3[COPY app.py]
        R4[adduser appuser]
        R5[USER appuser]
        R6[EXPOSE 5000]
        R7[CMD gunicorn ...]
        R1 --> R2 --> R3 --> R4 --> R5 --> R6 --> R7
    end

    BUILDER -->|--from=builder /wheels| RUNTIME

    style BUILDER fill:#21262d,color:#79c0ff
    style RUNTIME fill:#21262d,color:#3fb950
```

The multi-stage build ensures the final image contains no compiler toolchain (`gcc`). Only Python, the pre-built wheels, and `app.py` are in the image that runs on EC2. This cuts the image size and eliminates an entire class of supply-chain vulnerabilities.

The `HEALTHCHECK` instruction tells Docker to periodically verify the application is responding. If the container becomes unhealthy, Docker can restart it automatically (when `--restart unless-stopped` is set).

**Running locally:**

```bash
# With Docker Compose (recommended for local dev)
docker compose up --build

# With plain Docker
docker build -t cicd-flask-app:latest .
docker run -d --name flask-app -p 5000:5000 cicd-flask-app:latest

# Open in browser
open http://localhost:5000
```

---

## Infrastructure Provisioning

```mermaid
graph LR
    subgraph TERRAFORM["terraform apply"]
        KP[aws_key_pair<br/>deploy]
        SG[aws_security_group<br/>app_sg]
        EC2[aws_instance<br/>app_server]
        EIP[aws_eip<br/>app_eip]
    end

    KP --> EC2
    SG --> EC2
    EC2 --> EIP

    EIP -->|public_ip| OUT1[Output: elastic_ip]
    EIP -->|port 5000| OUT2[Output: application_url]
    EC2 -->|id| OUT3[Output: ssh_command]

    style TERRAFORM fill:#1a1f29,color:#e6edf3
    style KP fill:#7B42BC,color:#fff
    style SG fill:#7B42BC,color:#fff
    style EC2 fill:#FF9900,color:#000
    style EIP fill:#7B42BC,color:#fff
```

---

## Terraform Explanation

Five `.tf` files split responsibilities cleanly:

**`provider.tf`** — Configures the AWS provider with region and credentials from variables. The `default_tags` block applies `Project`, `Environment`, and `ManagedBy` tags to every resource without repeating them.

**`versions.tf`** — Pins the Terraform CLI to `>= 1.7.0` and the AWS provider to `~> 5.50` (minor updates OK, major updates blocked). This prevents silent breakage when provider releases change resource schemas.

**`variables.tf`** — Declares all inputs with `type`, `description`, and `sensitive = true` where appropriate. Sensitive variables are redacted in Terraform's output and plan files.

**`main.tf`** — Four resources:
- `aws_key_pair` — uploads your local public key to EC2 as a named key pair
- `aws_security_group` — allows inbound SSH (22), Flask (5000), and HTTP (80); allows all outbound
- `aws_instance` — t2.micro Ubuntu 22.04 with an encrypted gp3 root volume; the `user_data` bootstrap script installs Docker and clones the repository
- `aws_eip` — allocates a static public IP and associates it with the instance

**`outputs.tf`** — After `terraform apply`, prints the Elastic IP, application URL, and the exact SSH command to use.

**`terraform.tfvars`** — Values for all variables. This file is in `.gitignore` because it contains AWS credentials. Never commit it.

---

## EC2 Configuration

The `user_data` script in `main.tf` runs once on first boot and prepares the instance:

1. `apt-get update` and install `git`, `curl`
2. Install Docker Engine via the official `get.docker.com` script
3. Add `ubuntu` user to the `docker` group (so `sudo` isn't needed in deploy.sh)
4. Enable and start Docker
5. Clone the GitHub repository to `~/cicd-pipeline`

After bootstrap, the instance is ready to receive deployments from the pipeline. The EC2 `deploy.sh` script handles all subsequent deploys.

### Security Group Rules

```mermaid
graph LR
    INTERNET([Internet])
    SG{Security Group}
    EC2[EC2 Instance]

    INTERNET -->|TCP 22 — SSH| SG
    INTERNET -->|TCP 5000 — Flask| SG
    INTERNET -->|TCP 80 — HTTP| SG
    SG --> EC2
    EC2 -->|All outbound| INTERNET

    style INTERNET fill:#161b22,color:#58a6ff
    style SG fill:#FF9900,color:#000
    style EC2 fill:#21262d,color:#e6edf3
```

> In production, restrict the SSH ingress CIDR to your office IP or VPN range. `0.0.0.0/0` for SSH is acceptable during initial setup but should be tightened before going live.

---

## Deployment Process

```mermaid
sequenceDiagram
    participant GH as GitHub Actions
    participant EC2 as AWS EC2
    participant D as Docker Daemon
    participant APP as Flask Container

    GH->>EC2: SSH: git pull origin main
    GH->>EC2: SSH: docker stop flask-app
    EC2->>D: Stop container
    D-->>EC2: Container stopped
    GH->>EC2: SSH: docker rm flask-app
    EC2->>D: Remove container
    GH->>EC2: SSH: docker build -t cicd-flask-app:latest .
    EC2->>D: Build image from Dockerfile
    D-->>EC2: Image built
    GH->>EC2: SSH: docker run -d flask-app ...
    EC2->>D: Start new container
    D->>APP: Launch Gunicorn
    APP-->>D: Listening on :5000
    GH->>APP: curl http://EC2_HOST:5000/health
    APP-->>GH: HTTP 200 { status: healthy }
    GH->>GH: ✅ Pipeline succeeds
```

---

## Step-by-Step Setup Guide

### 1. Install Prerequisites (local machine)

**Git:**
```bash
# Ubuntu/Debian
sudo apt-get install git

# macOS
brew install git

# Verify
git --version
```

**Docker:**
```bash
# Ubuntu
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker

# macOS — install Docker Desktop from https://www.docker.com/products/docker-desktop
# Verify
docker --version
docker compose version
```

**Terraform:**
```bash
# Ubuntu
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install terraform

# macOS
brew tap hashicorp/tap && brew install hashicorp/tap/terraform

# Verify
terraform version
```

**AWS CLI:**
```bash
# Ubuntu/macOS
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# macOS alternative
brew install awscli

# Verify
aws --version
```

### 2. Configure AWS Credentials

```bash
aws configure
# AWS Access Key ID: <your key>
# AWS Secret Access Key: <your secret>
# Default region name: us-east-1
# Default output format: json
```

Create an IAM user with these permissions (principle of least privilege):
- `AmazonEC2FullAccess` (or a custom policy scoped to EC2, EIP, and Security Groups)

### 3. Generate SSH Key Pair

```bash
ssh-keygen -t rsa -b 4096 -C "cicd-deploy" -f ~/.ssh/id_rsa
# Press Enter twice to skip a passphrase (passphrase-protected keys require ssh-agent in the pipeline)
```

Copy the public key path — you'll use it in `terraform.tfvars` (`public_key_path`).

### 4. Clone and Configure the Repository

```bash
git clone https://github.com/YOUR_GITHUB_USERNAME/cicd-pipeline.git
cd cicd-pipeline

# Set up GitHub Actions workflow directory
mkdir -p .github/workflows
cp .github-workflow.yml .github/workflows/cicd.yml
```

### 5. Configure Terraform Variables

```bash
cp terraform.tfvars terraform.tfvars.backup   # optional — tfvars is already gitignored
```

Edit `terraform.tfvars` and fill in:
- `aws_access_key` and `aws_secret_key`
- `key_pair_name` — any name you choose
- `public_key_path` — path to the `.pub` file generated in step 3
- `ami_id` — verify the latest Ubuntu 22.04 AMI for your region at [Ubuntu EC2 AMI Locator](https://cloud-images.ubuntu.com/locator/ec2/)

### 6. Provision Infrastructure with Terraform

```bash
terraform init
terraform plan
terraform apply
```

After apply completes, note the outputs:
```
elastic_ip      = "54.x.x.x"
application_url = "http://54.x.x.x:5000"
ssh_command     = "ssh -i ~/.ssh/id_rsa ubuntu@54.x.x.x"
```

### 7. Wait for EC2 Bootstrap

The `user_data` script takes 3–5 minutes to complete. You can monitor it:

```bash
ssh -i ~/.ssh/id_rsa ubuntu@<ELASTIC_IP>
# Once connected:
tail -f /var/log/cloud-init-output.log
```

Wait until you see "Bootstrap complete" in the log, then exit.

### 8. Set GitHub Secrets

Go to your repository on GitHub → **Settings → Secrets and variables → Actions → New repository secret**.

Add all six secrets listed in the [GitHub Secrets](#github-secrets) section below.

### 9. Push Code to Trigger the Pipeline

```bash
git add .
git commit -m "Initial commit — CI/CD pipeline"
git push origin main
```

Watch the pipeline run at: `https://github.com/YOUR_USERNAME/cicd-pipeline/actions`

### 10. Verify Deployment

```bash
# Health check from your local machine
curl http://<ELASTIC_IP>:5000/health

# Open in browser
open http://<ELASTIC_IP>:5000
```

---

## GitHub Secrets

Navigate to **Settings → Secrets and variables → Actions** and add these secrets:

| Secret | Description | Example |
|---|---|---|
| `AWS_ACCESS_KEY_ID` | IAM user access key. Used by Terraform if you run it in the pipeline. | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | IAM user secret key. Never log or print this value. | `wJalrXUtnFEMI/...` |
| `EC2_HOST` | The Elastic IP address output by `terraform apply`. | `54.198.12.34` |
| `EC2_USERNAME` | The SSH user on the EC2 instance. Ubuntu AMIs use `ubuntu`. | `ubuntu` |
| `SSH_PRIVATE_KEY` | Full contents of `~/.ssh/id_rsa` (private key, not .pub). Copy with `cat ~/.ssh/id_rsa`. | `-----BEGIN OPENSSH PRIVATE KEY-----...` |
| `AWS_REGION` | AWS region. Used for any AWS SDK calls in the pipeline. | `us-east-1` |

### Security Flow

```mermaid
graph TD
    GHS[GitHub Secrets Store<br/>Encrypted at rest]
    RUN[Actions Runner<br/>ubuntu-latest]
    SSH[SSH Session<br/>EC2 Port 22]
    KEY[~/.ssh/deploy_key<br/>chmod 600]
    EC2[EC2 Instance]
    APP[Docker Container]
    CLEAN[rm -f ~/.ssh/deploy_key<br/>always: true]

    GHS -->|injected at runtime| RUN
    RUN --> KEY
    KEY --> SSH
    SSH --> EC2
    EC2 --> APP
    RUN --> CLEAN

    style GHS fill:#21262d,color:#3fb950
    style RUN fill:#161b22,color:#e6edf3
    style KEY fill:#da3633,color:#fff
    style CLEAN fill:#238636,color:#fff
```

The SSH private key exists in the runner's filesystem only for the duration of the deploy job. The `always: true` condition on the cleanup step ensures it is deleted even if a previous step fails.

---

## Deployment Commands

### Local Testing (no Docker)

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run tests
pytest test_app.py -v

# Start Flask development server
python app.py
# Application available at http://localhost:5000
```

### Local Testing with Docker

```bash
# Build image
docker build -t cicd-flask-app:latest .

# Run container
docker run -d \
  --name flask-app \
  -p 5000:5000 \
  -e APP_ENV=development \
  cicd-flask-app:latest

# Check logs
docker logs flask-app

# Health check
curl http://localhost:5000/health

# Stop and remove
docker stop flask-app && docker rm flask-app
```

### With Docker Compose

```bash
# Start
docker compose up --build -d

# Stop
docker compose down

# View logs
docker compose logs -f
```

### On EC2 — Manual Deploy

```bash
ssh -i ~/.ssh/id_rsa ubuntu@<ELASTIC_IP>
cd ~/cicd-pipeline
bash deploy.sh
```

### Terraform Commands

```bash
# Initialize providers
terraform init

# Preview changes
terraform plan

# Apply
terraform apply

# Show current state
terraform show

# Destroy all resources
terraform destroy
```

---

## Troubleshooting Guide

### 1. Tests fail locally but pass in CI
**Cause:** Different Python versions or dependency versions.
**Fix:** Run `python --version` and compare with the `python-version` in the workflow. Use a virtual environment locally.

### 2. `docker: command not found` on EC2
**Cause:** Docker installation hasn't completed. The `user_data` bootstrap is still running.
**Fix:** Wait 3–5 minutes and check `/var/log/cloud-init-output.log`. Re-run after "Bootstrap complete" appears.

### 3. `permission denied` when running Docker on EC2
**Cause:** The `ubuntu` user is in the `docker` group but the session started before the group was added.
**Fix:** `newgrp docker` or log out and back in.

### 4. SSH `Connection refused` from GitHub Actions
**Cause:** EC2 security group doesn't allow port 22 from the Actions runner IP, or the instance is still starting.
**Fix:** Verify the security group has `0.0.0.0/0` on port 22 (or the specific Actions IP range). Check instance state with `aws ec2 describe-instances`.

### 5. SSH `Host key verification failed`
**Cause:** `ssh-keyscan` didn't run or failed.
**Fix:** The workflow uses `ssh-keyscan -H ${{ secrets.EC2_HOST }}` — verify `EC2_HOST` is correct and the instance is reachable.

### 6. `git pull` fails on EC2 — `not a git repository`
**Cause:** The `user_data` clone didn't complete or failed.
**Fix:** SSH to EC2, check `ls ~/cicd-pipeline`. If missing, run `git clone https://github.com/YOUR_USERNAME/cicd-pipeline.git ~/cicd-pipeline`.

### 7. Health check returns 000 (connection refused)
**Cause:** Gunicorn hasn't finished starting, or the container exited immediately.
**Fix:** Run `docker logs flask-app` on EC2. Common causes: port already in use, or a Python import error.

### 8. Docker build fails: `COPY app.py .` — no such file
**Cause:** The Dockerfile is being run from the wrong directory.
**Fix:** `docker build` must be run from the root of the repository where `app.py` is located.

### 9. Elastic IP not associated with instance after `terraform apply`
**Cause:** The EIP association may have failed due to a timing issue.
**Fix:** `terraform apply` again. Terraform is idempotent — it will only create what's missing.

### 10. `terraform apply` fails: `InvalidKeyPair.Duplicate`
**Cause:** A key pair with that name already exists in the AWS account.
**Fix:** Change `key_pair_name` in `terraform.tfvars` or delete the existing key pair in the AWS console.

### 11. AMI not found error in Terraform
**Cause:** The `ami_id` in `terraform.tfvars` is for a different region.
**Fix:** Look up the Ubuntu 22.04 LTS AMI ID for your specific region at [Ubuntu EC2 AMI Locator](https://cloud-images.ubuntu.com/locator/ec2/).

### 12. Pipeline cancels mid-run
**Cause:** The concurrency block cancelled an in-progress run when a new push arrived.
**Fix:** This is by design. The latest commit always wins. If it cancelled prematurely, the next push will run fresh.

### 13. `curl` returns 403 on the health endpoint
**Cause:** There is no 403 in the application. A 403 typically means a reverse proxy (nginx/Apache) is blocking the request.
**Fix:** Confirm you are hitting port 5000 directly, not 80.

### 14. Container starts but immediately enters `unhealthy` state
**Cause:** The `HEALTHCHECK` in the Dockerfile is failing inside the container.
**Fix:** `docker inspect flask-app | grep -A 5 Health` to see the failure reason. Usually a startup timing issue — increase `--start-period`.

### 15. `pytest` finds no tests
**Cause:** Test file not named `test_*.py` or not in the same directory as `app.py`.
**Fix:** Run `pytest --collect-only` to see what pytest discovers.

### 16. GitHub Actions can't find the workflow
**Cause:** The workflow file is not in `.github/workflows/`.
**Fix:** `mkdir -p .github/workflows && cp .github-workflow.yml .github/workflows/cicd.yml && git add . && git push`.

### 17. `docker run` fails: `port already in use`
**Cause:** A previous container is still running on port 5000, or something else is bound to that port.
**Fix:** `docker ps -a` to find the container and `docker stop + rm` it, or `lsof -i :5000` to identify the process.

### 18. Terraform state gets corrupted
**Cause:** Manual deletion of resources in the AWS console while Terraform state still tracks them.
**Fix:** `terraform refresh` to sync state with actual AWS resources, then `terraform apply` to reconcile.

### 19. EC2 instance keeps restarting
**Cause:** The Docker container is crashing and Docker's `--restart unless-stopped` is restarting it in a crash loop.
**Fix:** `docker logs flask-app` to read the Python traceback. Usually a missing environment variable or bad import.

### 20. `terraform destroy` leaves the Elastic IP allocated
**Cause:** The EIP association must be destroyed before the EIP itself. Terraform handles this, but if interrupted, the EIP may be left orphaned.
**Fix:** Go to EC2 console → Elastic IPs → release the address, then run `terraform destroy` again.

---

## Security Best Practices

### SSH Keys
- Generate a 4096-bit RSA key specifically for this deployment. Don't reuse personal keys.
- Store the private key only in GitHub Secrets and `~/.ssh/` on your local machine.
- The pipeline deletes the key from the runner immediately after the deploy job completes.

### GitHub Secrets
- All credentials live in GitHub Secrets, never in code or environment files committed to the repository.
- Secrets are masked in logs — GitHub replaces them with `***` automatically.
- Rotate AWS credentials after the project if used in a shared account.

### Docker Security
- The container runs as `appuser` (non-root). If the process is compromised, it cannot write to most of the filesystem or bind to privileged ports.
- The multi-stage build means no compiler or build tools are present in the runtime image.
- The root filesystem is read-only by default for `/` directories.

### IAM Least Privilege
- Create a dedicated IAM user for this project with only EC2 and EIP permissions.
- Don't use root account credentials anywhere.

### Environment Variables
- The `APP_ENV` variable controls runtime behaviour. It is set to `production` in docker run and Compose.
- Sensitive values (database passwords, API keys) should be injected as environment variables, not baked into the image.

### Security Groups
- Port 22 defaults to `0.0.0.0/0` for development convenience. Lock it to your IP before any real workload: `allowed_ssh_cidr = "YOUR.IP.HERE/32"`.
- The application port (5000) is open to the internet — appropriate for a demo, but production traffic should go through an ALB or nginx on port 443 with TLS.

### Container Security
- Images use `python:3.12-slim` rather than `python:3.12`. Slim images have fewer installed packages, reducing attack surface.
- The `HEALTHCHECK` ensures Docker knows when the application is unhealthy and can restart it.

### Secrets Management
- `terraform.tfvars` is in `.gitignore`. Verify with `git status` before every push that it doesn't appear in the staging area.
- For production, move Terraform state to an S3 backend with server-side encryption and DynamoDB state locking.

---

## Best Practices Followed

**CI (Continuous Integration):**
Every push triggers automated testing. No code reaches EC2 without passing the full test suite. The `test` job is independent of `deploy` and runs on PRs too, catching regressions before they merge.

**CD (Continuous Deployment):**
Every successful push to `main` deploys automatically. There is no manual promotion step. Rollbacks are a `git revert` + push.

**Docker:**
Multi-stage build minimizes image size. Non-root user reduces blast radius if the container is compromised. Pinned base image (`python:3.12-slim`) prevents silent breakage from upstream changes.

**Terraform:**
All infrastructure is code. Destroying and recreating the environment is a `terraform destroy && terraform apply`. State is source-controlled (with `.tfstate` gitignored — use remote state in production).

**GitHub Actions:**
Jobs are split by concern (test / build / deploy). `needs:` enforces ordering. `concurrency:` prevents race conditions. `if:` gates deploys to `main` only.

**Version Control:**
Every deployment is tied to a commit SHA. The Docker image is tagged with the SHA. This makes it possible to identify exactly what is running in production.

**Logging:**
`deploy.sh` timestamps every log line. Docker's `json-file` driver with size limits prevents log files from filling the disk.

**Testing:**
25 test cases across 4 classes cover all three endpoints, status codes, content types, and response body fields. Coverage reporting is part of the CI step.

**Automation:**
No manual steps after initial setup. Developer workflow: write code → commit → push → done.

---

## Future Improvements

1. **Push Docker image to Amazon ECR** so EC2 only pulls, doesn't build — faster deploys
2. **Blue/green deployment** — spin up a new container before stopping the old one for zero-downtime deploys
3. **nginx reverse proxy** in front of Gunicorn on port 80/443 with automatic Let's Encrypt TLS
4. **Auto Scaling Group** instead of a single EC2 instance — horizontal scale and AZ redundancy
5. **Application Load Balancer** to distribute traffic across multiple EC2 instances
6. **Remote Terraform state** in S3 + DynamoDB for team use and state locking
7. **Separate staging environment** — deploy to staging on push to `develop`, production on merge to `main`
8. **Docker layer caching** in GitHub Actions using `cache-from` and `cache-to` to speed up builds
9. **Slack or email notifications** on pipeline success and failure via GitHub Actions `notify` step
10. **Secrets Manager** — pull runtime secrets from AWS Secrets Manager rather than environment variables
11. **CloudWatch logging** — ship container logs to CloudWatch for centralized log storage and alerting
12. **VPC with private subnets** — move EC2 behind a NAT gateway and only expose the ALB publicly
13. **IAM instance role** on EC2 so the instance can access AWS services without storing credentials
14. **Dependabot** for automated dependency updates with PR-based review
15. **Pre-commit hooks** with `black` and `flake8` to enforce code style before commit
16. **Database integration** — add PostgreSQL with RDS and connection pooling via SQLAlchemy
17. **Multi-environment Terraform workspaces** to manage dev/staging/prod with the same codebase
18. **GitHub Environments** with required reviewers for production deploys
19. **Kubernetes migration** — convert the Docker Compose file to Kubernetes manifests for EKS deployment
20. **API versioning** and OpenAPI spec generation with Flask-RESTX



## Skills Demonstrated

| Category | Skills |
|---|---|
| **DevOps** | CI/CD pipeline design, automated deployments, zero-downtime swap, health-gated releases |
| **GitHub Actions** | Multi-job workflows, job dependencies, concurrency control, secret injection, SSH deploy |
| **Docker** | Multi-stage builds, non-root users, health checks, Compose, image tagging |
| **Terraform** | Provider configuration, EC2/SG/EIP/KeyPair resources, variables, outputs, user-data |
| **AWS EC2** | Instance provisioning, Elastic IP, Security Groups, SSH, user-data bootstrapping |
| **Linux** | Bash scripting, systemd, Docker CLI, user management, log inspection |
| **Python** | Flask, Gunicorn, pytest, coverage, environment-aware configuration |
| **Git** | Feature branch workflow, push-triggered automation, commit SHA tagging |
| **Security** | Least-privilege IAM, non-root containers, SSH key hygiene, secrets management |
| **Testing** | Unit tests, test fixtures, HTTP status assertions, JSON response validation |
| **Automation** | Infrastructure as Code, self-healing containers, idempotent deploy scripts |
| **Cloud** | Static IP management, security group rules, compute bootstrapping, cloud-init |

---

*Built with Python 3.12 · Docker · GitHub Actions · Terraform · AWS EC2*
