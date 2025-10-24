output "worker_public_ip" {
  value       = [for instance in aws_instance.k3s_worker : instance.public_ip]
}

output "ssh_command" {
  value       = [for instance in aws_instance.k3s_worker : "ssh -i ../k3s/github-ec2.pem ubuntu@${instance.public_ip}"]
}