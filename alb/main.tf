terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-1"
}

data "aws_vpc" "existing" {
  id = "vpc-0b04f8c87a79cbc3e"  
}

data "aws_availability_zones" "azs" {
  state = "available"
}

# 已有 nginx 安全组 ID
data "aws_security_group" "nginx_sg" {
  id = "sg-0957e7002a61e2dd0"
}

locals {
  azs = ["ap-southeast-1a", "ap-southeast-1c"]
}

# 1. 新建 2 个子网（/28，0 元）
resource "aws_subnet" "alb" {
  count             = 2
  vpc_id            = data.aws_vpc.existing.id
  cidr_block        = "172.31.1${count.index + 8}.0/28"
  availability_zone = local.azs[count.index]
  tags = {
    Name = "alb-sn-${local.azs[count.index]}"
  }
}

# 2. 安全组：创建并修改nginx安全组 允许30090 来自 ALB
resource "aws_security_group" "alb" {
  name_prefix = "alb-sg"
  vpc_id      = data.aws_vpc.existing.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]   # 演示用，生产加 WAF
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "allow_alb_30090" {
  type                     = "ingress"
  from_port                = 30090
  to_port                  = 30090
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id   # ALB 安全组
  security_group_id        = data.aws_security_group.nginx_sg.id
  description              = "Allow ALB to nginx:30090"
}

# 3. 目标组（IP 类型，手动填已有实例私网地址）
resource "aws_lb_target_group" "nginx" {
  name        = "nginx-tg"
  port        = 30090
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.existing.id
  target_type = "ip"               # 关键：不再选 instance
  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 15
    matcher             = "200"
    path                = "/"
    timeout             = 5
    unhealthy_threshold = 2
  }
}

# 4. 把已有 IP 注册进去（双 AZ 各放一次，ALB 会自己选）
resource "aws_lb_target_group_attachment" "nginx" {
  count            = 2
  target_group_arn = aws_lb_target_group.nginx.arn
  target_id        = "172.31.17.97"  # ← 你的 nginx 私网地址
  port             = 30090
}

# 5. 公网 ALB（演示用）
resource "aws_lb" "public" {
  name               = "demo-pub-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.alb[*].id
}

resource "aws_lb_listener" "public" {
  load_balancer_arn = aws_lb.public.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx.arn
  }
}
