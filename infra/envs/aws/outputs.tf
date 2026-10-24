output "app_url" {
  description = "URL pública de la API"
  value       = "http://${aws_eip.app.public_ip}"
}

output "grafana_url" {
  description = "Grafana (solo accesible desde admin_cidr)"
  value       = "http://${aws_eip.app.public_ip}:3000"
}

output "prometheus_url" {
  description = "Prometheus (solo accesible desde admin_cidr)"
  value       = "http://${aws_eip.app.public_ip}:9090"
}

output "instance_id" {
  description = "Para entrar sin SSH: aws ssm start-session --target <instance_id>"
  value       = aws_instance.app.id
}

output "deployed_image" {
  value = "${var.image}:${var.image_tag}"
}
