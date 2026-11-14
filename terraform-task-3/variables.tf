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

