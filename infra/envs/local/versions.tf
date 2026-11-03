terraform {
  required_version = ">= 1.10"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 4.6"
    }
  }
}

# Dentro de la VM de Vagrant el daemon escucha en el socket por defecto.
provider "docker" {
  host = var.docker_host
}
