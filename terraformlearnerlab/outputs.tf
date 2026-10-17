output "web_url" {
  description = "Web app via the Compose nginx proxy (allow a few minutes after apply)."
  value       = "http://${aws_instance.example.public_ip}:8080"
}

output "api_url" {
  description = "Notes API, exposed directly as in docker-compose.yaml."
  value       = "http://${aws_instance.example.public_ip}:3000"
}

output "ssh_command" {
  description = "SSH command if a key pair was set (download the lab's labsuser.pem first)."
  value       = var.key_name == "" ? "no key pair configured" : "ssh -i labsuser.pem ubuntu@${aws_instance.example.public_ip}"
}
