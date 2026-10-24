import Fastify, { type FastifyInstance, type FastifyServerOptions } from 'fastify';
import { registerMetrics } from './metrics.js';
import { coursesRoutes } from './routes/courses.js';
import { enrollmentsRoutes } from './routes/enrollments.js';
import { Store } from './store.js';

export interface BuildOptions {
  logger?: FastifyServerOptions['logger'];
  store?: Store;
  version?: string;
  commit?: string;
}

export function buildApp(opts: BuildOptions = {}): FastifyInstance {
  const app = Fastify({ logger: opts.logger ?? false, bodyLimit: 16 * 1024 });
  const store = opts.store ?? new Store();
  const version = opts.version ?? process.env.APP_VERSION ?? 'dev';
  const commit = opts.commit ?? process.env.GIT_SHA ?? 'local';
  const startedAt = Date.now();

  // Cabeceras de seguridad básicas (sin dependencia extra).
  app.addHook('onSend', async (_request, reply, payload) => {
    reply.header('x-content-type-options', 'nosniff');
    reply.header('x-frame-options', 'DENY');
    reply.header('referrer-policy', 'no-referrer');
    reply.header('content-security-policy', "default-src 'none'; frame-ancestors 'none'");
    reply.removeHeader('x-powered-by');
    return payload;
  });

  const metrics = registerMetrics(app, store);

  app.get('/', async () => ({
    service: 'mundose-courses-api',
    version,
    commit,
    docs: ['/courses', '/courses/:id', '/enrollments', '/health', '/ready', '/metrics'],
  }));

  app.get('/health', async () => ({ status: 'ok', uptimeSeconds: Math.round((Date.now() - startedAt) / 1000) }));

  // Readiness: la app está lista cuando el catálogo está cargado.
  app.get('/ready', async (_request, reply) => {
    const ready = store.listCourses().length > 0;
    return reply.code(ready ? 200 : 503).send({ ready });
  });

  coursesRoutes(app, store);
  enrollmentsRoutes(app, store, metrics.enrollments);

  return app;
}
