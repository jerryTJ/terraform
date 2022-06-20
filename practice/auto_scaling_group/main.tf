provider "aws" {
  region = "ap-southeast-2"
}

variable "instance_config" {
  description = "instance type and ami"
  type = map(string)
  default = {
    type = "t2.micro"
    ami = "ami-0c6120f461d6b39e9"
  }
}

variable "server_port" {
  description = "the port the server will use for http request"
  type = number
  default = 8080
}

variable "server_ssh_port" {
  description = "the port the server will use for ssh connection"
  type = number
  default = 22
}
variable "server_https_port" {
  description = "the egress port of server"
  type = number
  default = 443
}
variable "vpc_id" {
  description = "vpc id"
  type = string 
  default = "vpc-0b1de44b1af3e7988"
}

resource "aws_launch_configuration" "example" {
  image_id = var.instance_config.ami
  instance_type = var.instance_config.type
  security_groups = [ aws_security_group.sgp-example.id ]
  user_data = <<-EOF
              #!/bin/bash
              echo "hello world" > index.html
              EOF
}

resource "aws_security_group" "sgp-example" {
  vpc_id = data.aws_vpc.selected.id
  name = "terrafrom-first-ec2-sgp-example"
  ingress  {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "web request"
    from_port = var.server_port
    protocol = "tcp"
    to_port = var.server_port
  } 
  ingress  {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "web request"
    from_port = var.server_ssh_port
    protocol = "tcp"
    to_port = var.server_ssh_port
  } 
  egress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  lifecycle {
     create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier = data.aws_subnets.selected.ids
  ## lb config
  target_group_arns = [ aws_lb_target_group.asg.arn ]
  health_check_type = "ELB"
  ##
  min_size = 1
  max_size = 1
  tag {
    key = "env"
    value = "dev"
    propagate_at_launch = true
  }
  lifecycle {
    create_before_destroy = true
  }
}

data "aws_vpc" "selected" {
  id = var.vpc_id
}

data "aws_subnets" "selected" {
  filter {
    name = "vpc-id"
    values = [var.vpc_id]
  }
}

data "aws_subnet" "selected" {
  for_each = toset(data.aws_subnets.selected.ids)
  id       = each.value
}

resource "aws_lb" "lb_test" {
  name = "terraform-lb-example"
  security_groups = [ aws_security_group.alb-sg.id ]
  load_balancer_type = "application"
  subnets = data.aws_subnets.selected.ids
}

resource "aws_lb_listener" "lb_listener" {
  load_balancer_arn = aws_lb.lb_test.arn
  port = 80
  protocol = "http"
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code = 404
    }
  }
}

resource "aws_security_group" "alb-sg" {
  name = "terraform-alb-security-group"
  vpc_id = data.aws_vpc.selected.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port =  0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
}

resource "aws_lb_target_group" "asg" {
  name = "terraform-asg-example"
  port = var.server_port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.selected.id
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    path = "/"
    matcher = "200"
    interval = 15
    timeout = 2

  }
}

resource "aws_lb_listener_rule" "lb-rule" {
  listener_arn = aws_lb_listener.lb_listener.arn
  priority = 100
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
  condition {
    path_pattern {
      values = [ "/" ]
    }
  }
}

output "alb_dns_name" {
  value       = aws_lb.lb_test.dns_name
  description = "The domain name of the load balancer"
}