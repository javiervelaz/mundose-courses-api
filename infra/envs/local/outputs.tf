output "app_url" {
  description = "Desde Windows (port-forward de Vagrant)"
  value       = "http://localhost:${var.app_port}"
}

output "grafana_url" {
  value = "http://localhost:${var.grafana_port}"
}

output "prometheus_url" {
  value = "http://localhost:${var.prometheus_port}"
}

output "deployed_image" {
  value = docker_image.app.name
}
