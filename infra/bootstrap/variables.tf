variable "aws_region" {
  description = "Región AWS del proyecto"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Prefijo de nombres"
  type        = string
  default     = "mundose"
}

variable "github_repository" {
  description = "Repositorio en formato owner/repo autorizado a desplegar"
  type        = string
  default     = "javiervelaz/mundose-courses-api"
}

variable "create_oidc_provider" {
  description = "false si la cuenta ya tiene el proveedor OIDC de GitHub creado"
  type        = bool
  default     = true
}
