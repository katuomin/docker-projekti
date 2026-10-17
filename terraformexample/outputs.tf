# Open this URL to reach the nginx proxy that publishes the web container.
output "web_url" {
  description = "Web application URL served through the Compose nginx proxy."
  value       = "http://${aws_instance.example.public_ip}:8080"
}

# This preserves the direct API port mapping from docker-compose.yaml.
output "api_url" {
  description = "Notes API URL, exposed directly on port 3000 as in Compose."
  value       = "http://${aws_instance.example.public_ip}:3000"
}

output "instance_id" {
  description = "EC2 instance ID; use it to connect with Systems Manager."
  value       = aws_instance.example.id
}
