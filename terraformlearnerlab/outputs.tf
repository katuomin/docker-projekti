output "web_url" {
  description = "Web app via the Compose nginx proxy (allow a few minutes after apply)."
  value       = "http://${aws_instance.example.public_ip}"
}

output "ssh_command" {
  description = "SSH command if a key pair was set (download the lab's labsuser.pem first)."
  value       = var.key_name == "" ? "no key pair configured" : "ssh -i labsuser.pem ubuntu@${aws_instance.example.public_ip}"
}
