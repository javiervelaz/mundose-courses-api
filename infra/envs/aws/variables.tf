variable "aws_region" {
  description = "Región AWS"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Prefijo de nombres (debe coincidir con el bootstrap)"
  type        = string
  default     = "mundose"
}

variable "image" {
  description = "Repositorio de la imagen, sin tag (ej. ghcr.io/javiervelaz/mundose-courses-api)"
  type        = string
}

variable "image_tag" {
  description = "Tag inmutable a desplegar: el SHA del commit"
  type        = string
  validation {
    condition     = can(regex("^[0-9a-f]{7,40}$", var.image_tag))
    error_message = "image_tag debe ser un SHA de git (no se despliega 'latest')."
  }
}

variable "instance_type" {
  description = "Tipo de instancia (t3.small: 2 GB para app + Prometheus + Grafana)"
  type        = string
  default     = "t3.small"
}

variable "admin_cidr" {
  description = "CIDR con acceso a Grafana y Prometheus (tu IP pública /32)"
  type        = string
  validation {
    condition     = can(cidrnetmask(var.admin_cidr)) && var.admin_cidr != "0.0.0.0/0"
    error_message = "admin_cidr debe ser un CIDR válido y no puede ser 0.0.0.0/0."
  }
}

variable "grafana_admin_password" {
  description = "Password del usuario admin de Grafana"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.grafana_admin_password) >= 12
    error_message = "La password de Grafana debe tener al menos 12 caracteres."
  }
}
