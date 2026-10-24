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

variable "github_oidc_subjects" {
  description = "Valores de sub del token OIDC autorizados a asumir el rol (formato con IDs numericos de GitHub; el segundo es el formato clasico por nombre)"
  type        = list(string)
  default     = ["repo:javiervelaz@4335443/mundose-courses-api@1432469589:environment:production", "repo:javiervelaz/mundose-courses-api:environment:production"]
}

variable "create_oidc_provider" {
  description = "false si la cuenta ya tiene el proveedor OIDC de GitHub creado"
  type        = bool
  default     = true
}
