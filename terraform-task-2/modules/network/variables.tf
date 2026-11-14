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