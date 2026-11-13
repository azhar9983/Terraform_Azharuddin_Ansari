```markdown
# Project Setup Guide

This project uses Python for the Flask backend and Node.js for the frontend (or any JavaScript services included in the project).

## Prerequisites

- Git
- Python 3.10 or later, including `pip`
- Node.js 18 or later, including `npm`

Check your installations:

```bash
python --version
pip --version
node --version
npm --version
```

On some systems, use `python3` and `pip3` instead of `python` and `pip`.

## Backend (Flask)

1. Open a terminal in the project directory.
2. Create and activate a virtual environment:

	```bash
	python -m venv .venv
	# macOS/Linux
	source .venv/bin/activate
	# Windows PowerShell
	.venv\Scripts\Activate.ps1
	```

3. Install the backend dependencies. If the repository contains `requirements.txt`:

	```bash
	pip install -r requirements.txt
	```

	If it does not, install Flask and any other packages required by the backend:

	```bash
	pip install Flask
	```

4. Configure any required environment variables (for example, a secret key or database URL) in your local environment. Do not commit credentials.
5. Start the Flask app using the entry point provided by the project. For example:

	```bash
	flask --app app run --debug
	```

	Replace `app` with the module or file that defines the Flask application.

## Frontend / Node.js service

1. Open another terminal and change to the directory containing the frontend's `package.json` (often `frontend/` or the project root).
2. Install dependencies:

	```bash
	npm install
	```

	If the project provides a `package-lock.json`, use `npm ci` for a clean, reproducible install instead.
3. Start the frontend using a script defined in `package.json`:

	```bash
	npm run dev
	```

	If that script is unavailable, check the available scripts with `npm run` and use the project's documented start command (commonly `npm start`).

## Dependencies

- **Backend:** Python packages are listed in `requirements.txt` when provided. Add backend packages there so they can be installed with `pip install -r requirements.txt`.
- **Frontend:** JavaScript packages and scripts are defined in `package.json`; `package-lock.json` records the resolved versions.

Keep the backend and frontend running in separate terminals. Configure the frontend's API URL to point to the Flask server if required by the project.

# TERRAFORM AWS FROM BELOW THIS LINE

```markdown
# Prerequisites
awscli installed and configured 
aws access keys and secret key stored in terraform.tfvars
terraform installed
```


#####################################################
Objective: Deploy a Flask backend and an Express frontend on AWS using Terraform, across three configurations — single EC2, separate EC2 instances, and Docker containers via ECR/ECS/VPC.
#####################################################


#####################################################
## TASK 1: Deploy Both Flask and Express on a Single EC2 Instance
Objective: Deploy both the Flask backend and the Express frontend on a single EC2 instance using Terraform.
Provision the EC2 instance with Terraform.
Configure the instance with: a user-data script or a configuration management tool (e.g., Ansible or Cloud-Init) to install dependencies (Python, Node.js), plus scripts to start the Flask backend and the Express frontend.
Ensure both applications run on different ports (e.g., Flask on port 5000 and Express on port 3000).
Expected Deliverables
Terraform configuration files (main.tf, variables.tf, etc.).
A working EC2 instance with Flask and Express running and accessible via the instance's public IP.

#####################################################

put code in main.tf and then 
```
terraform init
terraform fmt
terraform validate 
terraform plan
terraform apply
and approve or pre configure auto approve
```
`````````````````````````````````````````code below this line`````````````````````````````````````

```
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region     = var.aws_region
  access_key = var.access_key
  secret_key = var.secret_key
}


data "aws_ami" "ubuntu_2604" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-resolute-26.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_security_group" "apps" {
  name        = "frontend-backend-apps"
  description = "HTTP, backend API, and optional SSH access"

  ingress {
    description = "Frontend HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Backend API"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  dynamic "ingress" {
    for_each = var.ssh_cidr == null ? [] : [var.ssh_cidr]
    content {
      description = "SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "apps" {
  ami                    = data.aws_ami.ubuntu_2604.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.apps.id]

  root_block_device {
    volume_size = 40
    volume_type = "gp3"
  }

  user_data                   = <<-USERDATA
    #!/bin/bash
    set -euxo pipefail
    export DEBIAN_FRONTEND=noninteractive
    apt update
    apt install -y ca-certificates curl git
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    . /etc/os-release
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $${VERSION_CODENAME} stable" > /etc/apt/sources.list.d/docker.list
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    systemctl enable --now docker

    mkdir -p /opt/apps
    git clone --depth 1 '${var.app_repo}' /opt/apps/repo
    ln -s /opt/apps/repo/frontend /opt/apps/frontend
    ln -s /opt/apps/repo/backend /opt/apps/backend

    cat > /opt/apps/compose.yaml <<'COMPOSE'
    services:
      backend:
        build: ./backend
        restart: unless-stopped
        ports:
          - "9000:${var.backend_container_port}"
      frontend:
        build: ./frontend
        restart: unless-stopped
        depends_on:
          - backend
        environment:
          BACKEND_URL: "http://backend:${var.backend_container_port}"
        ports:
          - "80:${var.frontend_container_port}"
    COMPOSE

    cat > /opt/apps/run-apps.sh <<'RUNSCRIPT'
    #!/bin/bash
    set -euo pipefail
    cd /opt/apps
    git -C /opt/apps/repo pull --ff-only
    docker compose -f /opt/apps/compose.yaml up -d --build --remove-orphans
    RUNSCRIPT
    chmod +x /opt/apps/run-apps.sh
    docker compose -f /opt/apps/compose.yaml up -d --build
  USERDATA
  user_data_replace_on_change = true

  tags = {
    Name = "flask-express-server"
  }
}


variable "access_key" {

}

variable "secret_key" {

}

variable "aws_region" {
  description = "AWS region containing an Ubuntu 26.04 AMI."
  type        = string
  default     = "us-east-1"
}

variable "app_repo" {
  description = "Git repository containing backend/ and frontend/ folders."
  type        = string
  default     = "https://github.com/azhar9983/flask-express-server.git"
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "key_name" {
  description = "Optional EC2 key pair name for SSH access."
  type        = string
  default     = "tf-key"
}

variable "ssh_cidr" {
  description = "CIDR allowed to SSH; set to your IP, or null to disable SSH ingress."
  type        = string
  default     = "0.0.0.0/0"
}

variable "frontend_container_port" {
  type    = number
  default = 3000
}

variable "backend_container_port" {
  type    = number
  default = 5000
}

output "public_ip" {
  value = aws_instance.apps.public_ip
}

output "frontend_url" {
  value = "http://${aws_instance.apps.public_ip}"
}

output "backend_url" {
  value = "http://${aws_instance.apps.public_ip}:9000"
}
```


`````````````````````````````````code ends``````````````````````````````````````````````


##################################################################
## TASK 2: Deploy Flask and Express on Separate EC2 Instances
Objective: Deploy the Flask backend and the Express frontend on two separate EC2 instances using Terraform.
Provision two EC2 instances using Terraform: one for the Flask backend and one for the Express frontend.
Configure security groups to: allow communication between the two instances and expose both applications to the internet on their respective ports.
Configuration: Use Terraform to define networking resources such as VPC, subnets, and security groups. Use user-data scripts to automate installation and startup of both applications.
#################################################################

repeat same like task 1 but with below code

````````````````````````````````````code below this line``````````````````````````````````








```````````````````````````````````code ends``````````````````````````````````````````````



















