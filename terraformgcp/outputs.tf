output "web_url" {
  description = "Web app via the Compose nginx proxy (allow a few minutes after apply)."
  value       = "http://${google_compute_instance.example.network_interface[0].access_config[0].nat_ip}"
}

output "ssh_command" {
  description = "SSH command for the instance."
  value       = "ssh ubuntu@${google_compute_instance.example.network_interface[0].access_config[0].nat_ip}"
}
