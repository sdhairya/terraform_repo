data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "app_server" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  subnet_id     = var.public_subnet_id
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  vpc_security_group_ids = [aws_security_group.app_sg.id]

user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo amazon-linux-extras install docker -y
              sudo service docker start
              sudo usermod -a -G docker ec2-user
              aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${aws_ecr_repository.webapp.registry_id}.dkr.ecr.${var.region}.amazonaws.com
              docker pull ${aws_ecr_repository.webapp.repository_url}:latest
              docker pull ${aws_ecr_repository.mysql.repository_url}:latest
              docker network create mynet
              docker run -d --name mysql --network mynet \
                -e MYSQL_ROOT_PASSWORD=root \
                ${aws_ecr_repository.mysql.repository_url}:latest
              docker run -d --name blue --network mynet -p 8081:8080 \
                -e BACKGROUND_COLOR=blue \
                ${aws_ecr_repository.webapp.repository_url}:latest
              docker run -d --name pink --network mynet -p 8082:8080 \
                -e BACKGROUND_COLOR=pink \
                ${aws_ecr_repository.webapp.repository_url}:latest
              docker run -d --name lime --network mynet -p 8083:8080 \
                -e BACKGROUND_COLOR=lime \
                ${aws_ecr_repository.webapp.repository_url}:latest
              EOF


  tags = {
    Name = "assignment1-ec2"
  }
}

resource "aws_security_group" "app_sg" {
  name_prefix = "app-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8081
    to_port     = 8083
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
