import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import type { FastifyInstance } from 'fastify';
import { buildApp } from '../src/app.js';
import { Store } from '../src/store.js';

let app: FastifyInstance;

beforeEach(async () => {
  app = buildApp({ version: '1.2.3', commit: 'abc1234' });
  await app.ready();
});

afterEach(async () => {
  await app.close();
});

describe('endpoints operativos', () => {
  it('GET / devuelve versión y commit', async () => {
    const res = await app.inject({ method: 'GET', url: '/' });
    expect(res.statusCode).toBe(200);
    expect(res.json()).toMatchObject({ service: 'mundose-courses-api', version: '1.2.3', commit: 'abc1234' });
  });

  it('GET /health responde ok', async () => {
    const res = await app.inject({ method: 'GET', url: '/health' });
    expect(res.statusCode).toBe(200);
    expect(res.json().status).toBe('ok');
  });

  it('GET /ready responde 200 con catálogo cargado y 503 sin catálogo', async () => {
    expect((await app.inject({ method: 'GET', url: '/ready' })).statusCode).toBe(200);
    const empty = buildApp({ store: new Store([]) });
    const res = await empty.inject({ method: 'GET', url: '/ready' });
    expect(res.statusCode).toBe(503);
    await empty.close();
  });

  it('agrega cabeceras de seguridad', async () => {
    const res = await app.inject({ method: 'GET', url: '/health' });
    expect(res.headers['x-content-type-options']).toBe('nosniff');
    expect(res.headers['x-frame-options']).toBe('DENY');
    expect(res.headers['content-security-policy']).toContain("default-src 'none'");
  });
});

describe('cursos', () => {
  it('lista todo el catálogo con vacantes', async () => {
    const res = await app.inject({ method: 'GET', url: '/courses' });
    const body = res.json();
    expect(res.statusCode).toBe(200);
    expect(body.total).toBe(6);
    expect(body.items[0]).toHaveProperty('seatsLeft');
  });

  it('filtra por categoría', async () => {
    const res = await app.inject({ method: 'GET', url: '/courses?category=devops' });
    expect(res.json().items.every((c: { category: string }) => c.category === 'devops')).toBe(true);
  });

  it('rechaza una categoría inválida', async () => {
    const res = await app.inject({ method: 'GET', url: '/courses?category=cocina' });
    expect(res.statusCode).toBe(400);
  });

  it('devuelve un curso por id y 404 si no existe', async () => {
    expect((await app.inject({ method: 'GET', url: '/courses/devops-101' })).json().id).toBe('devops-101');
    expect((await app.inject({ method: 'GET', url: '/courses/nope' })).statusCode).toBe(404);
  });
});

describe('inscripciones', () => {
  const enroll = (body: object) => app.inject({ method: 'POST', url: '/enrollments', payload: body });

  it('crea una inscripción y descuenta una vacante', async () => {
    const res = await enroll({ courseId: 'devops-101', name: 'Ada Lovelace', email: 'Ada@Example.com' });
    expect(res.statusCode).toBe(201);
    expect(res.json().email).toBe('ada@example.com');
    const course = (await app.inject({ method: 'GET', url: '/courses/devops-101' })).json();
    expect(course.seatsLeft).toBe(39);
  });

  it('valida el cuerpo', async () => {
    expect((await enroll({ courseId: 'devops-101', name: 'A', email: 'no-es-email' })).statusCode).toBe(400);
    expect((await enroll({ courseId: 'devops-101' })).statusCode).toBe(400);
  });

  it('404 si el curso no existe', async () => {
    expect((await enroll({ courseId: 'nope', name: 'Ada', email: 'ada@example.com' })).statusCode).toBe(404);
  });

  it('409 si ya está inscripto', async () => {
    await enroll({ courseId: 'aws-110', name: 'Ada', email: 'ada@example.com' });
    const res = await enroll({ courseId: 'aws-110', name: 'Ada', email: 'ADA@example.com' });
    expect(res.statusCode).toBe(409);
  });

  it('422 si el curso está lleno', async () => {
    await enroll({ courseId: 'sec-130', name: 'Uno', email: 'uno@example.com' });
    await enroll({ courseId: 'sec-130', name: 'Dos', email: 'dos@example.com' });
    const res = await enroll({ courseId: 'sec-130', name: 'Tres', email: 'tres@example.com' });
    expect(res.statusCode).toBe(422);
  });

  it('lista inscripciones sin exponer emails', async () => {
    await enroll({ courseId: 'k8s-201', name: 'Grace', email: 'grace@example.com' });
    const all = (await app.inject({ method: 'GET', url: '/enrollments' })).json();
    const filtered = (await app.inject({ method: 'GET', url: '/enrollments?courseId=k8s-201' })).json();
    expect(all.total).toBe(1);
    expect(filtered.items[0]).not.toHaveProperty('email');
  });
});

describe('métricas', () => {
  it('expone métricas RED y de negocio en formato Prometheus', async () => {
    await app.inject({ method: 'GET', url: '/courses/devops-101' });
    await app.inject({
      method: 'POST',
      url: '/enrollments',
      payload: { courseId: 'data-150', name: 'Alan', email: 'alan@example.com' },
    });
    const res = await app.inject({ method: 'GET', url: '/metrics' });
    expect(res.statusCode).toBe(200);
    expect(res.headers['content-type']).toContain('text/plain');
    expect(res.body).toContain('http_request_duration_seconds_bucket');
    expect(res.body).toContain('route="/courses/:id"');
    expect(res.body).toMatch(/mundose_enrollments_total{[^}]*course_id="data-150"[^}]*} 1/);
    expect(res.body).toContain('mundose_course_seats_available');
    expect(res.body).toContain('process_cpu_seconds_total');
  });
});
