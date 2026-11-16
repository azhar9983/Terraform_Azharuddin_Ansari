variable "access_key" {

}

variable "secret_key" {

}

variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "frontend_dir" {
  default = "../flask-express-server/frontend"
}

variable "backend_dir" {
  default = "../flask-express-server/backend"
}

variable "frontend_repo_name" {
  default = "frontend"
}

variable "backend_repo_name" {
  default = "backend"
}

variable "project_name" {
  type    = string
  default = "flask-express"
}

variable "backend_port" {
  type    = number
  default = 5000
}

variable "frontend_port" {
  type    = number
  default = 3000
}

variable "image_tag" {
  description = "Docker image tag pushed to ECR"
  type        = string
  default     = "latest"
}

variable "desired_count" {
  type    = number
  default = 1
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "One public subnet per AZ"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "task_cpu" {
  type    = number
  default = 256
}

variable "task_memory" {
  type    = number
  default = 512
}