resource "aws_ecr_repository" "webapp" {
  name = "webapp"
}

resource "aws_ecr_repository" "mysql" {
  name = "mysql"
}