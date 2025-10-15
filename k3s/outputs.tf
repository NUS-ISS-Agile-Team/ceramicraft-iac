output "public_ip" {
  value = aws_eip.k3s.public_ip
}
output "ssh_command" {
  value = "ssh -i ${var.key_name}.pem ubuntu@${aws_eip.k3s.public_ip}"
}
output "argocd_url" {
  value = "https://${aws_eip.k3s.public_ip}:30080"
}
output "dashboard_url" {
  value = "https://${aws_eip.k3s.public_ip}:30443"
}