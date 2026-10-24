import { buildApp } from './app.js';

const port = Number(process.env.PORT ?? 8080);
const host = process.env.HOST ?? '0.0.0.0';

const app = buildApp({ logger: { level: process.env.LOG_LEVEL ?? 'info' } });

const shutdown = async (signal: string): Promise<void> => {
  app.log.info({ signal }, 'cerrando servidor');
  await app.close();
  process.exit(0);
};
process.on('SIGTERM', () => void shutdown('SIGTERM'));
process.on('SIGINT', () => void shutdown('SIGINT'));

try {
  await app.listen({ port, host });
} catch (err) {
  app.log.error(err);
  process.exit(1);
}
