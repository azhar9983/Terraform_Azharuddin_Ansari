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