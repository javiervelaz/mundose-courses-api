terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Configuración parcial: bucket, key y región se pasan con -backend-config
  # (ver pipeline.yml). Bloqueo nativo de S3 con use_lockfile, sin DynamoDB.
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project   = var.project
      ManagedBy = "terraform"
      Stack     = "aws"
      Commit    = var.image_tag
    }
  }
}
