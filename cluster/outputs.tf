output "worker_public_ip" {
  value = aws_instance.k3s_worker.public_ip
}

output "ssh_command" {
  value = "ssh -i ../k3s/github-ec2.pem ubuntu@${aws_instance.k3s_worker.public_ip}"
}