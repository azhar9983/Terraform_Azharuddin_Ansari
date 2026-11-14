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