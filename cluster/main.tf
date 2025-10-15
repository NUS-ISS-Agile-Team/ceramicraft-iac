provider "aws" {
  region = "ap-southeast-1"
}

# 取默认 VPC
data "aws_vpc" "default" {
  default = true
}

# 密钥对（如已有可改成 data source）
data "aws_key_pair" "demo" {
  key_name           = "github-ec2"   # 填写控制台里看到的 Key pair name
  include_public_key = true               # 可选，如需拿到公钥内容
}

# 1. 在 ap-southeast-1c 新建公有子网，CIDR 与 172.31.x.x 错开
resource "aws_subnet" "public_1c" {
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = "172.31.20.0/24"   # 完全新段
  availability_zone       = "ap-southeast-1c"
  map_public_ip_on_launch = true

  tags = {
    Name       = "k3s-public-1c"
    Type       = "public"
    K3sCluster = "demo"
  }
}

# 2. 安全组：K3s worker 所需端口
resource "aws_security_group" "k3s_worker" {
  name_prefix = "k3s-worker-"
  vpc_id      = data.aws_vpc.default.id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # K3s 控制面
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  # Flannel vxlan
  ingress {
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  # Kubelet metrics
  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  # NodePort 范围
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k3s-worker-sg"
  }
}

# 4. 启动 EC2
resource "aws_instance" "k3s_worker" {
  ami                    = "ami-07651f0c4c315a529" # Amazon Linux 2023 ap-southeast-1
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_1c.id
  vpc_security_group_ids = [aws_security_group.k3s_worker.id]
  key_name               = data.aws_key_pair.demo.key_name

  user_data_base64 = base64encode(templatefile("${path.module}/user_data.sh", {
    server_url = "https://${var.k3s_master_ip}:6443"
    node_token = var.k3s_node_token
  }))

  tags = {
    Name       = "${var.prefix}-k3s-worker"
    K3sCluster = "demo"
    K3sRole    = "worker"
  }
}