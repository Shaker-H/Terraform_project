terraform {
  resource "aws_ecr_repository" "smrrepository" {
  name = "smrrepository"

  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}
}