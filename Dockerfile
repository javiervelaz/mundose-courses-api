# syntax=docker/dockerfile:1.7
# ---------------------------------------------------------------------------
# mundose-courses-api — imagen multi-stage, reproducible y sin root
#
# Reproducibilidad:
#   - Base fijada por digest (NODE_IMAGE). Dependabot la actualiza con PR.
#     Para obtener el digest:  docker buildx imagetools inspect node:22-alpine
#   - Dependencias instaladas con `npm ci` sobre package-lock.json (versiones exactas).
#   - Versión y commit inyectados como build-args y labels OCI.
# ---------------------------------------------------------------------------
ARG NODE_IMAGE=node:22-alpine

# 1) Dependencias de producción, sin scripts de instalación (reduce superficie de ataque)
FROM ${NODE_IMAGE} AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev --ignore-scripts && npm cache clean --force

# 2) Compilación TypeScript -> JavaScript
FROM ${NODE_IMAGE} AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --ignore-scripts
COPY tsconfig.json tsconfig.build.json ./
COPY src ./src
RUN npm run build

# 3) Runtime mínimo
FROM ${NODE_IMAGE} AS runtime
ARG APP_VERSION=dev
ARG GIT_SHA=local
ARG BUILD_DATE=1970-01-01T00:00:00Z
LABEL org.opencontainers.image.title="mundose-courses-api" \
      org.opencontainers.image.description="API de cursos e inscripciones de MundosE (PIN DevOps, Proyecto 1)" \
      org.opencontainers.image.source="https://github.com/javiervelaz/mundose-courses-api" \
      org.opencontainers.image.version="${APP_VERSION}" \
      org.opencontainers.image.revision="${GIT_SHA}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.licenses="MIT"

ENV NODE_ENV=production \
    PORT=8080 \
    APP_VERSION=${APP_VERSION} \
    GIT_SHA=${GIT_SHA}

# npm/yarn no se usan en runtime: se eliminan para achicar la imagen y quitar sus CVE.
RUN rm -rf /usr/local/lib/node_modules/npm /usr/local/bin/npm /usr/local/bin/npx \
           /opt/yarn-* /usr/local/bin/yarn /usr/local/bin/yarnpkg

WORKDIR /app
COPY --from=deps  --chown=node:node /app/node_modules ./node_modules
COPY --from=build --chown=node:node /app/dist ./dist
COPY --chown=node:node package.json ./

USER node
EXPOSE 8080

# Healthcheck sin curl/wget: usa el fetch nativo de Node 22.
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD ["node", "-e", "fetch('http://127.0.0.1:'+(process.env.PORT||8080)+'/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"]

CMD ["node", "dist/server.js"]
