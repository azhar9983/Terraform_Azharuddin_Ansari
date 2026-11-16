resource "aws_ecr_repository" "frontend" {
  name                 = var.frontend_repo_name
  image_tag_mutability = "MUTABLE" # Or "IMMUTABLE" based on your needs
  force_delete          = true # Set to true if you want to delete the repository even if it contains images

  image_scanning_configuration {
    scan_on_push = true # Set to true if you want to scan images as they are pushed
  }
}

resource "null_resource" "build_and_push_frontend" {
  triggers = {
    # Trigger a rebuild if the Dockerfile or source code changes
    dockerfile_hash = filebase64sha256("${path.module}/${var.frontend_dir}/Dockerfile")
  }

  provisioner "local-exec" {
    command = <<-EOT
      aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.frontend.repository_url}
      docker build -t ${aws_ecr_repository.frontend.repository_url}:${var.image_tag} ${path.module}/${var.frontend_dir}
      docker push ${aws_ecr_repository.frontend.repository_url}:${var.image_tag}
    EOT
  }
}


resource "aws_ecr_repository" "backend" {
  name                 = var.backend_repo_name
  image_tag_mutability = "MUTABLE" # Or "IMMUTABLE" based on your needs
  force_delete          = true # Set to true if you want to delete the repository even if it contains images

  image_scanning_configuration {
    scan_on_push = true # Set to true if you want to scan images as they are pushed
  }
}

resource "null_resource" "build_and_push_backend" {
  triggers = {
    # Trigger a rebuild if the Dockerfile or source code changes
    dockerfile_hash = filebase64sha256("${path.module}/${var.backend_dir}/Dockerfile")
  }

  provisioner "local-exec" {
    command = <<-EOT
      aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.backend.repository_url}
      docker build -t ${aws_ecr_repository.backend.repository_url}:${var.image_tag} ${path.module}/${var.backend_dir}
      docker push ${aws_ecr_repository.backend.repository_url}:${var.image_tag}
    EOT
  }
}