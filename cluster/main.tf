provider "aws" {
  region = "ap-southeast-1"
}

# default VPC
data "aws_vpc" "default" {
  default = true
}

# key pair
data "aws_key_pair" "demo" {
  key_name           = "github-ec2"   
  include_public_key = true               
}

# 1. new public subnet，CIDR should diff 172.31.x.x 
resource "aws_subnet" "public_1c" {
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = "172.31.20.0/24"   
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name       = "k3s-public-1c"
    Type       = "public"
    K3sCluster = "demo"
  }
}


# 4. startup EC2
resource "aws_instance" "k3s_worker" {
  count                  = var.worker_count
  ami                    = "ami-07651f0c4c315a529" 
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_1c.id
  vpc_security_group_ids = [var.security_group]
  key_name               = data.aws_key_pair.demo.key_name

  user_data_base64 = base64encode(templatefile("${path.module}/user_data.sh", {
    server_url = "https://${var.k3s_master_ip}:6443"
    node_token = var.k3s_node_token
  }))

  tags = {
    Name       = "${var.prefix}-k3s-worker-${count.index + 1}"
    K3sCluster = "demo"
    K3sRole    = "worker"
  }
}