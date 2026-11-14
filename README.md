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
### Expected Deliverables
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
### Expected Deliverables
Terraform configuration files.
Two working EC2 instances: one running Flask and one running Express.
Security groups configured to allow proper communication and public access.

#################################################################

repeat same like task 1 but with below code
goto task2 folder
```
terraform init
terraform fmt
terraform validate 
terraform plan
terraform apply
and approve or pre configure auto approve
```

````````````````````````````````````code below this line``````````````````````````````````








```hcl
# terraform-task-2/main.tf
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

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-resolute-26.04-amd64-server-*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

module "network" {
  source        = "./modules/network"
  project_name  = var.project_name
  vpc_cidr      = var.vpc_cidr
  subnet_cidr   = var.subnet_cidr
  frontend_port = var.frontend_port
  backend_port  = var.backend_port
  ssh_cidr      = var.ssh_cidr
}

module "backend" {
  source            = "./modules/app_instance"
  name              = "${var.project_name}-backend"
  ami_id            = data.aws_ami.ubuntu.id
  instance_type     = var.instance_type
  subnet_id         = module.network.subnet_id
  security_group_id = module.network.backend_security_group_id
  key_name          = var.key_name
  user_data = templatefile("${path.module}/backend-user-data.sh.tftpl", {
    app_repo       = var.app_repo
    backend_port   = var.backend_port
    backend_module = var.backend_module
  })
}

module "frontend" {
  source            = "./modules/app_instance"
  name              = "${var.project_name}-frontend"
  ami_id            = data.aws_ami.ubuntu.id
  instance_type     = var.instance_type
  subnet_id         = module.network.subnet_id
  security_group_id = module.network.frontend_security_group_id
  key_name          = var.key_name
  user_data = templatefile("${path.module}/frontend-user-data.sh.tftpl", {
    app_repo      = var.app_repo
    frontend_port = var.frontend_port
    backend_url   = "http://${module.backend.private_ip}:${var.backend_port}"
  })
}
```

```hcl
# terraform-task-2/variables.tf
variable "access_key" {

}

variable "secret_key" {

}

variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "project_name" {
  type    = string
  default = "flask-express"
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "subnet_cidr" {
  type    = string
  default = "10.20.1.0/24"
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "key_name" {
  description = "Existing EC2 key pair name"
  type        = string
  default     = "new-key"
  nullable    = true
}

variable "ssh_cidr" {
  description = "Restrict SSH to your trusted IP in CIDR notation; null disables SSH."
  type        = string
  default     = null
  nullable    = true
}

variable "app_repo" {
  type    = string
  default = "https://github.com/azhar9983/flask-express-server.git"
}

variable "backend_port" {
  type    = number
  default = 5000
}

variable "frontend_port" {
  type    = number
  default = 3000
}

variable "backend_module" {
  description = "Flask import target, such as app:app."
  type        = string
  default     = "app:app"
}
```

```hcl
# terraform-task-2/outputs.tf
output "frontend_url" {
  value = "http://${module.frontend.public_ip}:${var.frontend_port}"
}
output "backend_url" {
  value = "http://${module.backend.public_ip}:${var.backend_port}"
}
output "frontend_public_ip" {
  value = module.frontend.public_ip
}
output "backend_public_ip" {
  value = module.backend.public_ip
}
```

```hcl
# terraform-task-2/modules/network/main.tf
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${var.project_name}-vpc" }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.project_name}-igw" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.project_name}-public" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = { Name = "${var.project_name}-public-routes" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "frontend" {
  name        = "${var.project_name}-frontend"
  description = "Public Express access and optional SSH"
  vpc_id      = aws_vpc.this.id
  ingress {
    description = "Express frontend"
    from_port   = var.frontend_port
    to_port     = var.frontend_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  dynamic "ingress" {
    for_each = var.ssh_cidr == null ? [] : [var.ssh_cidr]
    content {
      description = "SSH from trusted CIDR"
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
  tags = { Name = "${var.project_name}-frontend" }
}

resource "aws_security_group" "backend" {
  name        = "${var.project_name}-backend"
  description = "Public Flask access plus frontend-to-backend traffic"
  vpc_id      = aws_vpc.this.id
  ingress {
    description = "Flask API from the internet"
    from_port   = var.backend_port
    to_port     = var.backend_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description     = "Flask API from frontend instance"
    from_port       = var.backend_port
    to_port         = var.backend_port
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend.id]
  }
  dynamic "ingress" {
    for_each = var.ssh_cidr == null ? [] : [var.ssh_cidr]
    content {
      description = "SSH from trusted CIDR"
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
  tags = { Name = "${var.project_name}-backend" }
}
```

```hcl
# terraform-task-2/modules/network/variables.tf
variable "project_name" {
  type = string
}
variable "vpc_cidr" {
  type = string
}
variable "subnet_cidr" {
  type = string
}
variable "frontend_port" {
  type = number
}
variable "backend_port" {
  type = number
}
variable "ssh_cidr" {
  type     = string
  default  = null
  nullable = true
}
```

```hcl
# terraform-task-2/modules/network/outputs.tf
output "subnet_id" { value = aws_subnet.public.id }
output "frontend_security_group_id" { value = aws_security_group.frontend.id }
output "backend_security_group_id" { value = aws_security_group.backend.id }
```

```hcl
# terraform-task-2/modules/app_instance/main.tf
resource "aws_instance" "this" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  key_name                    = var.key_name
  user_data                   = var.user_data
  user_data_replace_on_change = true
  root_block_device {
    volume_size = 16
    volume_type = "gp3"
    encrypted   = true
  }
  tags = { Name = var.name }
}
```

```hcl
# terraform-task-2/modules/app_instance/variables.tf
variable "name" { type = string }
variable "ami_id" { type = string }
variable "instance_type" { type = string }
variable "subnet_id" { type = string }
variable "security_group_id" { type = string }
variable "key_name" {
  type     = string
  default  = null
  nullable = true
}
variable "user_data" { type = string }
```

```hcl
# terraform-task-2/modules/app_instance/outputs.tf
output "public_ip" { value = aws_instance.this.public_ip }
output "private_ip" { value = aws_instance.this.private_ip }
```

```hcl
# terraform-task-2/backend-user-data.sh.tftpl
#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y git python3 python3-pip python3-venv
# AWS security groups already control inbound traffic; UFW is optional and not required here.
git clone --depth 1 '${app_repo}' /opt/app-repo
cd /opt/app-repo/backend
python3 -m venv /opt/flask-venv
/opt/flask-venv/bin/pip install --upgrade pip
if [ -f requirements.txt ]; then /opt/flask-venv/bin/pip install -r requirements.txt; fi
/opt/flask-venv/bin/pip install gunicorn
cat >/etc/systemd/system/flask-app.service <<SERVICE
[Unit]
Description=Flask backend
After=network.target
[Service]
WorkingDirectory=/opt/app-repo/backend
Environment=PORT=${backend_port}
ExecStart=/opt/flask-venv/bin/gunicorn --bind 0.0.0.0:${backend_port} ${backend_module}
Restart=always
[Install]
WantedBy=multi-user.target
SERVICE
systemctl daemon-reload
systemctl enable --now flask-app
```

```hcl
# terraform-task-2/frontend-user-data.sh.tftpl
#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y ca-certificates curl git
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs
git clone --depth 1 '${app_repo}' /opt/app-repo
cd /opt/app-repo/frontend
npm ci || npm install
cat >/etc/systemd/system/express-app.service <<SERVICE
[Unit]
Description=Express frontend
After=network.target
[Service]
WorkingDirectory=/opt/app-repo/frontend
Environment=PORT=${frontend_port}
Environment=HOST=0.0.0.0
Environment=BACKEND_URL=${backend_url}
ExecStart=/usr/bin/npm start
Restart=always
[Install]
WantedBy=multi-user.target
SERVICE
systemctl daemon-reload
systemctl enable --now express-app
```

```````````````````````````````````code ends``````````````````````````````````````````````


#####################################################

# TASK3: Part 3: Deploy Flask and Express Using Docker and AWS Services
Objective: Deploy Flask and Express as Docker containers using AWS ECR, ECS, and VPC with Terraform.
ECR: Use Terraform to create two Elastic Container Registry (ECR) repositories — one for the Flask backend and one for the Express frontend. Build Docker images for both and push them to their respective ECR repositories.
VPC: Use Terraform to create a VPC with subnets, route tables, and security groups.
ECS: Use Terraform to set up an ECS cluster and create two ECS services — one for Flask and one for Express — using ECS Fargate or the EC2 launch type to deploy the containers.
Load Balancer: Use Terraform to provision an Application Load Balancer (ALB) and configure ALB listeners to route requests to the appropriate ECS service.
### Expected Deliverables
Terraform configuration files for ECR, ECS, VPC, and ALB setup.
Docker images pushed to ECR.
ECS services running and accessible via the ALB.

###########################################################

repeat same like task 1 but with below code
goto task3 folder
```
terraform init
terraform fmt
terraform validate 
terraform plan
terraform apply
and approve or pre configure auto approve
```

````````````````````````````````````code below this line``````````````````````````````````






```````````````````````````````````code ends``````````````````````````````````````````````










