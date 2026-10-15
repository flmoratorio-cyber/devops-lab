output "container_ip" {
  description = "Container IP on the default Docker bridge"
  value       = docker_container.nginx.network_data[0].ip_address
}

output "url" {
  description = "URL on the Docker host"
  value       = "http://localhost:${var.external_port}"
}
