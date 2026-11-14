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

