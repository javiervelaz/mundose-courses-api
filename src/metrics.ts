import { Counter, Gauge, Histogram, Registry, collectDefaultMetrics } from 'prom-client';
import type { FastifyInstance } from 'fastify';
import type { Store } from './store.js';

export interface Metrics {
  registry: Registry;
  enrollments: Counter<'course_id'>;
}

/**
 * Métricas RED (rate, errors, duration) + métricas de negocio.
 * Cada instancia de la app usa su propio Registry para que los tests no compartan estado.
 */
export function registerMetrics(app: FastifyInstance, store: Store): Metrics {
  const registry = new Registry();
  registry.setDefaultLabels({ service: 'mundose-courses-api' });
  collectDefaultMetrics({ register: registry });

  const duration = new Histogram({
    name: 'http_request_duration_seconds',
    help: 'Duración de las peticiones HTTP en segundos',
    labelNames: ['method', 'route', 'status_code'] as const,
    buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5],
    registers: [registry],
  });

  const enrollments = new Counter({
    name: 'mundose_enrollments_total',
    help: 'Inscripciones creadas por curso',
    labelNames: ['course_id'] as const,
    registers: [registry],
  });

  new Gauge({
    name: 'mundose_course_seats_available',
    help: 'Vacantes disponibles por curso',
    labelNames: ['course_id'] as const,
    registers: [registry],
    collect() {
      for (const c of store.listCourses()) this.set({ course_id: c.id }, store.seatsLeft(c.id));
    },
  });

  app.addHook('onResponse', async (request, reply) => {
    // Se usa la ruta declarada (/courses/:id), no la URL real, para no explotar la cardinalidad.
    const route = request.routeOptions.url ?? 'not_found';
    if (route === '/metrics') return;
    duration.observe(
      { method: request.method, route, status_code: String(reply.statusCode) },
      reply.elapsedTime / 1000,
    );
  });

  app.get('/metrics', async (_request, reply) => {
    reply.header('content-type', registry.contentType);
    return registry.metrics();
  });

  return { registry, enrollments };
}
