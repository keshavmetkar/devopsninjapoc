# resource to get public ip of instances accessing Bastion
data "http" "my_public_ip" {
  url = "https://api.ipify.org/"
}


resource "aws_security_group" "Bastion_host_SG" {
  name = "Bastion_host_SG"
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "Bastion_host_SG"
    Project = var.Project
    Environment = var.Environment
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${data.http.my_public_ip.body}/32"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "Private_Instances_SG" {
  name = "Private_Instances_SG"
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "Private_Instances_SG"
    Project = var.Project
    Environment = var.Environment
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
    }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "Public_Web_SG" {
  name = "Public_Web_SG"
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "Public_Web_SG"
    Project = var.Project
    Environment = var.Environment
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${data.http.my_public_ip.body}/32"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "alb_sg" {
  name_prefix = "alb_sg"
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "alb_sg"
    Environment = var.Project
  }
  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_security_group" "jenkins_sg" {
  name_prefix = "jenkins_sg"
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "jenkins_sg"
    Project = var.Project
    Environment = var.Environment
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
}

resource "aws_security_group" "app_sg" {
  name_prefix = "app_sg"
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "app_sg"
    Project = var.Project
    Environment = var.Environment
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
}