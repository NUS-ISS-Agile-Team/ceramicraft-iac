variable "prefix" {
  default = "demo"
}

variable "k3s_master_ip" {
  description = "K3s master 公网 IP 或内网 IP（agent 要能连通）"
  type        = string
}

variable "k3s_node_token" {
  description = "K3s node token，从 master 上 cat /var/lib/rancher/k3s/server/node-token 获取"
  type        = string
  sensitive   = true
}