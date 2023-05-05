# Create the Application Load Balancer
resource "aws_lb" "my_alb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = ["${aws_subnet.public1.id}","${aws_subnet.public2.id}"]
  security_groups    = [aws_security_group.alb_sg.id]

  tags = {
    Name = "my-alb"
    Project = var.Project
    Environment = var.Environment
  }
}
resource "aws_lb_listener" "alb_listner" {
  load_balancer_arn = aws_lb.my_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.jenkins_target_group.arn
    type             = "forward"
  }
  tags = {
    Name = "alb_listner"
    Project = var.Project
    Environment = var.Environment
  }
}

resource "aws_lb_listener_rule" "jenkins" {
  listener_arn = aws_lb_listener.alb_listner.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jenkins_target_group.arn
  }

  condition {
    path_pattern {
      values = ["/jenkins", "/jenkins/*"]
    }
  }
}

resource "aws_lb_listener_rule" "app" {
  listener_arn = aws_lb_listener.alb_listner.arn
  priority     = 200
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_target_group.arn
  }
  condition {
    path_pattern {
      values = ["/app", "/app/*"]
    }
  }
}


# Create the target groups
resource "aws_lb_target_group" "jenkins_target_group" {
  name_prefix      = "jenkin"
  port             = 8080
  protocol         = "HTTP"
  vpc_id = aws_vpc.vpc.id
  target_type        = "instance"
  deregistration_delay = 10
  health_check {
    path     = "/jenkin*"
    port     = "8080"
    interval = 10
  }

  tags = {
    Name = "jenkins-target-group"
    Project = var.Project
    Environment = var.Environment
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "app_target_group" {
  name_prefix      = "app-"
  port             = 8080
  protocol         = "HTTP"
  vpc_id = aws_vpc.vpc.id
  target_type = "instance"
  deregistration_delay = 10
  health_check {
    path     = "/app*"
    port     = "8080"
    interval = 10
  }

  tags = {
    Name = "app-target-group"
    Project = var.Project
    Environment = var.Environment
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group_attachment" "jenkins_attachment" {
  target_group_arn = aws_lb_target_group.jenkins_target_group.arn
  target_id        = aws_instance.jenkins.id
  port             = 8080
}

resource "aws_lb_target_group_attachment" "app_attachment" {
  target_group_arn = aws_lb_target_group.app_target_group.arn
  target_id        = aws_instance.app.id
  port             = 8080
}
