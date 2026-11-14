output "public_ip" {
  value = aws_instance.apps.public_ip
}

output "frontend_url" {
  value = "http://${aws_instance.apps.public_ip}"
}

output "backend_url" {
  value = "http://${aws_instance.apps.public_ip}:9000"
}

