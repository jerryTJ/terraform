provider "aws" {
  region = "ap-southeast-2" 
}

terraform {
  backend "s3" {
    bucket         = "s3backend-2tohpom6x1g8xa-state-bucket"
    key            = "terraform/state"
    region         = "ap-southeast-2"
    dynamodb_table = "s3backend-2tohpom6x1g8xa-state-lock"
    encrypt        = true
  }

  required_version = ">= 1.10.3"

  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

# resource group 
resource "aws_resourcegroups_group" "rg" {
  name = "${local.namespace}-group"
  resource_query {
    query = jsonencode({
      ResourceTypeFilters = ["AWS::AllSupported"],  # 支持所有资源类型
      TagFilters = [
        {
          Key    = "ResourceGroup",              # 标签键
          Values = [local.namespace]              # 标签值
        },{
          Key = "environment"
          Values = [var.environment]
        }
      ]
    })
    type = "TAG_FILTERS_1_0"
  }

  tags = {
    ManagedBy     = "Terraform"
    ResourceGroup = local.namespace
    environment = var.environment
  }
}


# 创建 VPC
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Type = "nginx-vpc"
    ManagedBy     = "Terraform"
    ResourceGroup = local.namespace
    environment = var.environment
  }
}

# 创建 Internet Gateway
resource "aws_internet_gateway" "main_igateway" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Type = "nginx-igw"
    ManagedBy     = "Terraform"
    ResourceGroup = local.namespace
    environment = var.environment
  }
}

# 创建公共子网
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-southeast-2a"
  tags = {
    Type = "public-subnet"
    ManagedBy     = "Terraform"
    ResourceGroup = local.namespace
    environment = var.environment
  }
}

# 创建私有子网
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-southeast-2b"
  tags = {
    Type = "private-subnet"
    ManagedBy     = "Terraform"
    ResourceGroup = local.namespace
    environment = var.environment
  }
}

# 创建 NAT Gateway
resource "aws_eip" "nat_eip" {
  vpc = true
  tags = {
    Type = "nat-eip"
    ManagedBy     = "Terraform"
    ResourceGroup = local.namespace
    environment = var.environment
  }
}

resource "aws_nat_gateway" "main_nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id
  tags = {
    Type = "nat-gateway"
    ManagedBy     = "Terraform"
    ResourceGroup = local.namespace
    environment = var.environment
  }
}

# 创建公共子网的路由表
resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Type = "public-route-table"
    ManagedBy     = "Terraform"
    ResourceGroup = local.namespace
    environment = var.environment
  }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public_route.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main_igateway.id
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route.id
}

# 创建私有子网的路由表
resource "aws_route_table" "private_route" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Type = "private-route-table"
    ManagedBy     = "Terraform"
    ResourceGroup = local.namespace
    environment = var.environment
  }
}

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private_route.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main_nat_gateway.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route.id
}

# 公共子网 Security Group (允许 8080)
resource "aws_security_group" "public_sg" {
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Type = "public-sg"
    ManagedBy     = "Terraform"
    ResourceGroup = local.namespace
    environment = var.environment
  }
}

# 私有子网 Security Group (允许 3306)
resource "aws_security_group" "private_sg" {
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.public_sg.id] # 公共子网的 EC2 可以访问
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Type = "private-sg"
    ManagedBy     = "Terraform"
    ResourceGroup = local.namespace
    environment = var.environment
  }
}
# 创建 RDS MySQL 实例（私有子网）
resource "aws_db_subnet_group" "group_mysql" {
  name       = "mysql-subnet-group"
  subnet_ids = [aws_subnet.private_subnet.id]

  tags = {
    Type = "mysql-subnet-group"
    ManagedBy     = "Terraform"
    ResourceGroup = local.namespace
    environment = var.environment
  }
}

resource "aws_db_instance" "instance_mysql" {
  identifier              = "mysql-instance"
  engine                  = "mysql"
  instance_class          = "db.t2.micro"
  allocated_storage       = 20
  username                = "admin"
  password                = "yourpassword" # 替换为安全密码
  vpc_security_group_ids  = [aws_security_group.private_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.group_mysql.name
  publicly_accessible     = false
  skip_final_snapshot     = true

  tags = {
    Type = "mysql-instance"
    ManagedBy     = "Terraform"
    ResourceGroup = local.namespace
    environment = var.environment
  }
}

# ALB 配置
resource "aws_lb" "app_load_balancer" {
  name               = "nginx-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.public_sg.id]
  subnets            = [aws_subnet.public_subnet.id]

  tags = {
    Type = "nginx-alb"
    ManagedBy     = "Terraform"
    ResourceGroup = local.namespace
    environment = var.environment
  }
}

resource "aws_lb_target_group" "target_group" {
  name        = "nginx-target-group"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main_vpc.id
  target_type = "instance"

  health_check {
    path                = "/"
    port                = "8080"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}

# Launch Template for Auto Scaling
resource "aws_launch_template" "main_launch_template" {
  name          = "autoscaling-lt"
  image_id      = "ami-0c02fb55956c7d316" # 替换为适合你的区域的 Ubuntu AMI
  instance_type = "t2.micro"

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx
    systemctl start nginx
  EOF

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.public_sg.name]
  }

  tags = {
    Type = "autoscaling-instance"
    ManagedBy     = "Terraform"
    ResourceGroup = local.namespace
    environment = var.environment
  }
}


# Auto Scaling Group
resource "aws_autoscaling_group" "main_ag" {
  desired_capacity     = 1
  max_size             = 1
  min_size             = 1
  launch_template {
    id      = aws_launch_template.main_launch_template.id
    version = "$Latest"
  }

  vpc_zone_identifier = [aws_subnet.public_subnet.id]
  target_group_arns   = [aws_lb_target_group.target_group.arn]

  tags = [
    {
      key                 = "Name"
      value               = "autoscaling-instance"
      propagate_at_launch = true
    }
  ]
}
