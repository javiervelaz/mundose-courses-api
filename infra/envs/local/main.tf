# ---------------------------------------------------------------------------
# Entorno local: misma imagen (por SHA) y misma configuración de monitoreo que
# AWS, corriendo como contenedores dentro de una VM VirtualBox creada con Vagrant.
# ---------------------------------------------------------------------------
locals {
  monitoring = abspath("${path.module}/../../../monitoring")
}

resource "docker_network" "mundose" {
  name = "mundose"
}

resource "docker_image" "app" {
  name         = "${var.image}:${var.image_tag}"
  keep_locally = true
}

resource "docker_image" "prometheus" {
  name         = "prom/prometheus:v3.15.1"
  keep_locally = true
}

resource "docker_image" "grafana" {
  name         = "grafana/grafana:13.2.4"
  keep_locally = true
}

resource "docker_image" "node_exporter" {
  name         = "prom/node-exporter:v1.12.1"
  keep_locally = true
}

resource "docker_volume" "prometheus" {
  name = "mundose-prometheus-data"
}

resource "docker_volume" "grafana" {
  name = "mundose-grafana-data"
}

resource "docker_container" "app" {
  name      = "app"
  image     = docker_image.app.image_id
  restart   = "unless-stopped"
  read_only = true
  tmpfs     = { "/tmp" = "rw,noexec,nosuid,size=16m" }
  memory    = 256

  capabilities {
    drop = ["ALL"]
  }
  security_opts = ["no-new-privileges:true"]

  ports {
    internal = 8080
    external = var.app_port
  }

  networks_advanced {
    name = docker_network.mundose.name
  }
}

resource "docker_container" "node_exporter" {
  name     = "node-exporter"
  image    = docker_image.node_exporter.image_id
  restart  = "unless-stopped"
  pid_mode = "host"
  command  = ["--path.rootfs=/host"]

  volumes {
    host_path      = "/"
    container_path = "/host"
    read_only      = true
  }

  networks_advanced {
    name = docker_network.mundose.name
  }
}

resource "docker_container" "prometheus" {
  name    = "prometheus"
  image   = docker_image.prometheus.image_id
  restart = "unless-stopped"
  command = [
    "--config.file=/etc/prometheus/prometheus.yml",
    "--storage.tsdb.retention.time=7d",
  ]

  ports {
    internal = 9090
    external = var.prometheus_port
  }

  volumes {
    host_path      = "${local.monitoring}/prometheus/prometheus.yml"
    container_path = "/etc/prometheus/prometheus.yml"
    read_only      = true
  }
  volumes {
    host_path      = "${local.monitoring}/prometheus/alerts.yml"
    container_path = "/etc/prometheus/alerts.yml"
    read_only      = true
  }
  volumes {
    volume_name    = docker_volume.prometheus.name
    container_path = "/prometheus"
  }

  networks_advanced {
    name = docker_network.mundose.name
  }

  depends_on = [docker_container.app, docker_container.node_exporter]
}

resource "docker_container" "grafana" {
  name    = "grafana"
  image   = docker_image.grafana.image_id
  restart = "unless-stopped"

  env = [
    "GF_SECURITY_ADMIN_USER=admin",
    "GF_SECURITY_ADMIN_PASSWORD=${var.grafana_admin_password}",
    "GF_USERS_ALLOW_SIGN_UP=false",
    "GF_AUTH_ANONYMOUS_ENABLED=false",
    "GF_DASHBOARDS_DEFAULT_HOME_DASHBOARD_PATH=/var/lib/grafana/dashboards/mundose-api.json",
  ]

  ports {
    internal = 3000
    external = var.grafana_port
  }

  volumes {
    host_path      = "${local.monitoring}/grafana/provisioning"
    container_path = "/etc/grafana/provisioning"
    read_only      = true
  }
  volumes {
    host_path      = "${local.monitoring}/grafana/dashboards"
    container_path = "/var/lib/grafana/dashboards"
    read_only      = true
  }
  volumes {
    volume_name    = docker_volume.grafana.name
    container_path = "/var/lib/grafana"
  }

  networks_advanced {
    name = docker_network.mundose.name
  }

  depends_on = [docker_container.prometheus]
}
