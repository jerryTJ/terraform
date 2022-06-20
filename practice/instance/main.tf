provider "aws" {
  region = "ap-southeast-2"
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
resource "aws_instance" "first-ec2" {
  ami = "ami-0c6120f461d6b39e9"
  instance_type = "t2.micro"
  vpc_security_group_ids = [ aws_security_group.sgp-example.id ]
  user_data = <<-EOF
              #!/bin/bash
              echo "hello world" > index.html
              EOF
  tags = {
    Name = "terraform-example"
  }
}
resource "aws_security_group" "sgp-example" {
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
output "public_ip" {
  value = "aws_instance.first-ec2.public_ip"
  description = "the public ip address of the web server"
}
