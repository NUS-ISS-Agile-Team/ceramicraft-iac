variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-southeast-1"
}

variable "name" {
  description = "Name tag for resources"
  type        = string
  default     = "ocd-ec2"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "key_name" {
  description = "Name of the keypair to use (if you want Terraform to create it, pass same name and set public_key_path)"
  type        = string
  default     = "ocd-deployer"
}

variable "public_key_path" {
  description = "Local path to public key to upload as an AWS key pair (optional). If empty, Terraform won't create key pair."
  type        = string
  default     = ""
}

variable "repo_url" {
  description = "Git repository URL to clone on instance"
  type        = string
}

variable "repo_branch" {
  description = "Branch to checkout"
  type        = string
  default     = "main"
}

variable "repo_dir" {
  description = "Directory name under /home/ec2-user where repo will be cloned"
  type        = string
  default     = "app"
}

variable "compose_path" {
  description = "Path inside the repo where docker-compose.yml is located (relative to repo root)"
  type        = string
  default     = "."
}

variable "tags" {
  description = "Additional tags to apply"
  type        = map(string)
  default     = {}
}