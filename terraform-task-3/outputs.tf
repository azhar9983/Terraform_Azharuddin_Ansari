

output "image_tag" {
  value = {
    frontend_tag = random_id.frontend_rand_tag.hex
  }
}

output "backend_image_tag" {
  value = random_id.backend_rand_tag.hex
}
