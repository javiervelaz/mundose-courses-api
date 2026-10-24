# ---------------------------------------------------------------------------
# Entorno AWS: una EC2 con Docker que corre app + Prometheus + Grafana + node-exporter.
#
# Despliegue inmutable: image_tag (SHA) forma parte del user_data y
# user_data_replace_on_change = true, así que cada versión nueva reemplaza la
# instancia completa. La Elastic IP se reasocia y la URL no cambia.
# ---------------------------------------------------------------------------
locals {
  monitoring = "${path.module}/../../../monitoring"

  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    image                  = var.image
    image_tag              = var.image_tag
    grafana_admin_password = var.grafana_admin_password
    compose_version        = "v5.6.1"
    compose_yml            = file("${path.module}/docker-compose.yml")
    prometheus_yml         = file("${local.monitoring}/prometheus/prometheus.yml")
    alerts_yml             = file("${local.monitoring}/prometheus/alerts.yml")
    datasource_yml         = file("${local.monitoring}/grafana/provisioning/datasources/prometheus.yml")
    dashboards_yml         = file("${local.monitoring}/grafana/provisioning/dashboards/dashboards.yml")
    dashboard_json         = file("${local.monitoring}/grafana/dashboards/mundose-api.json")
  })
}

data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

data "aws_vpc" "default" {
  default = true
}

# -------------------------------------------------------------- red / firewall
resource "aws_security_group" "app" {
  name        = "${var.project}-app"
  description = "mundose-courses-api: HTTP publico, observabilidad solo admin_cidr, sin SSH"
  vpc_id      = data.aws_vpc.default.id
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.app.id
  description       = "API publica"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "grafana" {
  security_group_id = aws_security_group.app.id
  description       = "Grafana solo desde admin_cidr"
  cidr_ipv4         = var.admin_cidr
  ip_protocol       = "tcp"
  from_port         = 3000
  to_port           = 3000
}

resource "aws_vpc_security_group_ingress_rule" "prometheus" {
  security_group_id = aws_security_group.app.id
  description       = "Prometheus solo desde admin_cidr"
  cidr_ipv4         = var.admin_cidr
  ip_protocol       = "tcp"
  from_port         = 9090
  to_port           = 9090
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.app.id
  description       = "Salida para pull de imagenes y actualizaciones"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ------------------------------------------------- rol de la instancia (SSM)
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "instance" {
  name               = "${var.project}-instance"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

# Acceso de administración por Session Manager: no hay puerto 22 ni llaves SSH.
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "instance" {
  name = "${var.project}-instance"
  role = aws_iam_role.instance.name
}

# ------------------------------------------------------------------ instancia
resource "aws_instance" "app" {
  ami                         = data.aws_ssm_parameter.al2023.insecure_value
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.app.id]
  iam_instance_profile        = aws_iam_instance_profile.instance.name
  user_data_base64            = base64gzip(local.user_data)
  user_data_replace_on_change = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 obligatorio
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  tags = {
    Name = "${var.project}-app"
  }

  lifecycle {
    # Un AMI nuevo de Amazon no debe reemplazar la instancia por sí solo.
    ignore_changes = [ami]
  }
}

resource "aws_eip" "app" {
  domain   = "vpc"
  instance = aws_instance.app.id

  tags = {
    Name = "${var.project}-app"
  }
}
