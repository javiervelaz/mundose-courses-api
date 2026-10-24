variable "docker_host" {
  description = "Daemon Docker de la VM VirtualBox"
  type        = string
  default     = "unix:///var/run/docker.sock"
}

variable "image" {
  description = "Repositorio de la imagen, sin tag"
  type        = string
  default     = "ghcr.io/javiervelaz/mundose-courses-api"
}

variable "image_tag" {
  description = "SHA del commit a correr (el mismo que está en AWS)"
  type        = string
  validation {
    condition     = can(regex("^[0-9a-f]{7,40}$", var.image_tag))
    error_message = "image_tag debe ser un SHA de git."
  }
}

variable "grafana_admin_password" {
  description = "Password del admin de Grafana local"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.grafana_admin_password) >= 12
    error_message = "La password de Grafana debe tener al menos 12 caracteres."
  }
}

variable "app_port" {
  type    = number
  default = 8080
}

variable "grafana_port" {
  type    = number
  default = 3000
}

variable "prometheus_port" {
  type    = number
  default = 9090
}
