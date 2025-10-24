variable "prefix" {
  default = "demo"
}

variable "k3s_master_ip" {
  description = "K3s master public IP or private IP（agent need to connect）"
  type        = string
}

variable "k3s_node_token" {
  description = "K3s node token，obtain on master by cat /var/lib/rancher/k3s/server/node-token"
  type        = string
  sensitive   = true
}

variable "availability_zone" {
  description = "The availability zone to deploy resources in"
  type        = string
  default     = "ap-southeast-1c" 
}

variable "worker_count" {
  description = "Number of K3s worker nodes to create"
  type        = number
  default     = 3
}