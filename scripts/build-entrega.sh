#!/usr/bin/env bash
# Arma la carpeta de entrega y el zip. Uso: bash scripts/build-entrega.sh <sha> [artefactos_dir]
# artefactos_dir: carpeta con los zips descargados de Actions (default: evidencias/sbom)
set -euo pipefail
SHA="${1:?uso: build-entrega.sh <sha> [artefactos_dir]}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ART="${2:-$ROOT/evidencias/sbom}"
NAME="Proyecto 1_JavierVelaz"
STAGE="$(mktemp -d)"   # se arma fuera del repo y solo el zip se copia a entrega/
OUT="$STAGE/$NAME"
TMP="$(mktemp -d)"
mkdir -p "$OUT"/{1-pipeline-cicd,2-infraestructura,3-contenedor,4-seguridad,5-observabilidad,6-documentacion,app,video}
for z in "$ART"/*.zip; do unzip -oq "$z" -d "$TMP"; done
ev() { cp "$ROOT/evidencias/$1" "$2"; }

# 1 · Pipeline
cp -r "$ROOT/.github" "$OUT/1-pipeline-cicd/.github"
ev "github actions pipeline.png" "$OUT/1-pipeline-cicd/captura-pipeline-verde.png"

# 2 · Infraestructura
mkdir -p "$OUT/2-infraestructura/evidencia"
tar -C "$ROOT" --exclude='.terraform' --exclude='*.tfstate*' -cf - infra Vagrantfile scripts | tar -C "$OUT/2-infraestructura" -xf -
ev "terraform output.txt" "$OUT/2-infraestructura/evidencia/terraform-apply-aws-ci.txt"
ev "aws desde pc.txt" "$OUT/2-infraestructura/evidencia/terraform-output-state-aws.txt"
ev "aws api.png" "$OUT/2-infraestructura/evidencia/aws-api.png"
ev "localhost api.png" "$OUT/2-infraestructura/evidencia/local-api.png"
ev "contenedores local.png" "$OUT/2-infraestructura/evidencia/local-contenedores.png"

# 3 · Contenedor
cp "$ROOT/Dockerfile" "$ROOT/.dockerignore" "$OUT/3-contenedor/" 2>/dev/null || cp "$ROOT/Dockerfile" "$OUT/3-contenedor/"
cp "$TMP"/mundose-courses-api_*.tar.gz "$OUT/3-contenedor/"
cp "$TMP/snyk-container.json" "$OUT/3-contenedor/"

# 4 · Seguridad
cp "$TMP"/sbom.cyclonedx.json "$TMP"/sbom.spdx.json "$OUT/4-seguridad/"
cp "$TMP"/snyk-deps.json "$TMP"/snyk-deps.sarif "$TMP"/snyk-iac.json "$TMP"/snyk-iac.sarif "$TMP"/snyk-container.json "$OUT/4-seguridad/"
cp "$TMP/reports/eslint.json" "$OUT/4-seguridad/eslint.json"
cp "$ROOT/sonar-project.properties" "$OUT/4-seguridad/"
for f in "$ROOT"/evidencias/sonar*.png "$ROOT"/evidencias/snyk*.png; do [ -e "$f" ] && cp "$f" "$OUT/4-seguridad/"; done || true

# 5 · Observabilidad
cp -r "$ROOT/monitoring" "$ROOT/load" "$OUT/5-observabilidad/"
mkdir -p "$OUT/5-observabilidad/capturas"
ev "aws grafana.png" "$OUT/5-observabilidad/capturas/aws-grafana.png"
ev "aws prometheus.png" "$OUT/5-observabilidad/capturas/aws-prometheus.png"
ev "local grafana 1.png" "$OUT/5-observabilidad/capturas/local-grafana-1.png"
ev "local grafana 2.png" "$OUT/5-observabilidad/capturas/local-grafana-2.png"
ev "local prometheus.png" "$OUT/5-observabilidad/capturas/local-prometheus.png"

# 6 · Documentación
cp "$ROOT/README.md" "$OUT/6-documentacion/README-repo.md"
cp "$ROOT/docs/SETUP.md" "$OUT/6-documentacion/SETUP.md"
cp "$ROOT/docs/ai/prompt-app.md" "$OUT/6-documentacion/prompt-app-ia.md"
cp "$ROOT/LICENSE" "$OUT/6-documentacion/"
sed "s/__SHA__/$SHA/g" "$ROOT/docs/entrega/README-entrega.md" > "$OUT/README.md"
for f in "$ROOT"/docs/entrega/*; do [ "$(basename "$f")" = README-entrega.md ] || cp -r "$f" "$OUT/6-documentacion/"; done

# app
git -C "$ROOT" archive --format=tar HEAD src test package.json package-lock.json tsconfig.json tsconfig.build.json vitest.config.ts eslint.config.js | tar -C "$OUT/app" -xf -

# video (el .mp4 lo agrega el alumno)
echo "Colocar aquí demo.mp4 (4-5 min) antes de zipear." > "$OUT/video/LEEME.txt"

echo "$SHA" > "$OUT/COMMIT.txt"
( cd "$STAGE" && zip -qr "$NAME.zip" "$NAME" )
mkdir -p "$ROOT/entrega"; cp -f "$STAGE/$NAME.zip" "$ROOT/entrega/"
echo "OK: $ROOT/entrega/$NAME.zip"; du -sh "$ROOT/entrega/$NAME.zip"
