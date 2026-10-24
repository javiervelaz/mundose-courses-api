#!/usr/bin/env bash
# Destruye el entorno local (correr dentro de la VM).
set -euo pipefail
cd /vagrant/infra/envs/local
TF_VAR_image_tag="${1:-0000000}" TF_VAR_grafana_admin_password="placeholder-destroy" \
  terraform destroy -input=false -auto-approve
