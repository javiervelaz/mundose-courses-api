#!/usr/bin/env bash
# Levanta el entorno local con Terraform (correr dentro de la VM).
#   bash /vagrant/scripts/local-up.sh <sha-del-commit>
# La password de Grafana se toma de GRAFANA_ADMIN_PASSWORD o se pide por teclado.
set -euo pipefail
SHA="${1:?Uso: local-up.sh <sha-del-commit>}"
if [ -z "${GRAFANA_ADMIN_PASSWORD:-}" ]; then
  read -rsp "Password de Grafana (>= 12 caracteres): " GRAFANA_ADMIN_PASSWORD; echo
fi
export TF_VAR_image_tag="$SHA" TF_VAR_grafana_admin_password="$GRAFANA_ADMIN_PASSWORD"

cd /vagrant/infra/envs/local
terraform init -input=false
terraform apply -input=false -auto-approve
terraform output

for i in $(seq 1 20); do
  curl -fsS http://localhost:8080/ && echo && exit 0
  sleep 2
done
echo "La app no respondió en :8080" >&2; exit 1
