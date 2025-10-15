variable "region"        { default = "ap-southeast-1" }
variable "vpc_id"        { default = "vpc-0b04f8c87a79cbc3e" }   # 你的已有 VPC
variable "subnet_id"     { default = "subnet-0be6cc94f8c0b1fb8" }   # 该 VPC 里的任意 public subnet
variable "key_name"      { default = "github-ec2" }       # 提前在 EC2 控制台创建好的 KeyPair
variable "my_ip"         { default = "0.0.0.0/0" }    # 实验完就删，可全开
variable "igw_id"    { default = "igw-06513106b987fb409" }
