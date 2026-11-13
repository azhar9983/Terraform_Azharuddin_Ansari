
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
