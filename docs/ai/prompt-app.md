# App base generada con IA

La consigna del PIN pide una "aplicación base simple generada con IA". La app de este repo (`src/`, `test/`) fue generada con **Claude** (Anthropic) a partir del prompt de abajo y revisada por el alumno antes del primer commit.

- Fecha: 24/10/2026
- Herramienta: Claude (asistente de IA), en una sesión de trabajo con acceso al repositorio
- Intervención humana: definición del dominio (MundosE), revisión del código, ajustes de dependencias y validación con tests

## Prompt utilizado

> Generá una API REST simple en **Node.js 22 + TypeScript + Fastify** para la plataforma educativa MundosE: un catálogo de cursos con inscripciones.
>
> Requisitos funcionales:
> - `GET /courses` (filtro opcional `?category=`), `GET /courses/:id`
> - `POST /enrollments` con `courseId`, `name`, `email`; validar el body con JSON Schema; responder 404 si el curso no existe, 409 si el email ya está inscripto en ese curso, 422 si no hay vacantes
> - `GET /enrollments` sin exponer emails
> - Datos en memoria con un catálogo semilla de 6 cursos; sin base de datos
>
> Requisitos operativos (la app es el sujeto de un pipeline DevOps):
> - `GET /` con versión y SHA del commit leídos de `APP_VERSION` y `GIT_SHA`
> - `GET /health` (liveness) y `GET /ready` (readiness)
> - `GET /metrics` en formato Prometheus con `prom-client`: histograma `http_request_duration_seconds` etiquetado por ruta declarada (no la URL, para no explotar la cardinalidad), contador `mundose_enrollments_total` y gauge de vacantes por curso
> - Cabeceras de seguridad básicas sin dependencias extra
> - Apagado ordenado con SIGTERM
>
> Calidad:
> - `buildApp()` separado de `server.ts` para testear con `app.inject` sin abrir puertos
> - Tests con Vitest y cobertura ≥ 80 %
> - ESLint (flat config) con `typescript-eslint` en modo strict
> - Sin dependencias más allá de `fastify` y `prom-client` en runtime

## Qué se cambió a mano después de generar

- Versiones de dependencias fijadas exactas en `package.json` (reproducibilidad).
- Aserción de métricas en los tests ajustada al orden real de las etiquetas de `prom-client`.
- Actualización de ESLint 9 → 10 por fin de soporte.
