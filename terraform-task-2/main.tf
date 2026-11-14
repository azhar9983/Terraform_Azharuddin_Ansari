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