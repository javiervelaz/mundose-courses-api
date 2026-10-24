import type { FastifyInstance } from 'fastify';
import type { Counter } from 'prom-client';
import type { Store } from '../store.js';

interface EnrollBody {
  courseId: string;
  name: string;
  email: string;
}

const statusByReason = {
  course_not_found: 404,
  already_enrolled: 409,
  course_full: 422,
} as const;

export function enrollmentsRoutes(app: FastifyInstance, store: Store, counter: Counter<'course_id'>): void {
  app.post<{ Body: EnrollBody }>(
    '/enrollments',
    {
      schema: {
        body: {
          type: 'object',
          required: ['courseId', 'name', 'email'],
          additionalProperties: false,
          properties: {
            courseId: { type: 'string', minLength: 1, maxLength: 64 },
            name: { type: 'string', minLength: 2, maxLength: 120 },
            email: { type: 'string', format: 'email', maxLength: 254 },
          },
        },
      },
    },
    async (request, reply) => {
      const result = store.enroll(request.body);
      if (!result.ok) return reply.code(statusByReason[result.reason]).send({ error: result.reason });
      counter.inc({ course_id: result.enrollment.courseId });
      return reply.code(201).send(result.enrollment);
    },
  );

  app.get<{ Querystring: { courseId?: string } }>('/enrollments', async (request) => {
    const items = store.listEnrollments(request.query.courseId);
    // No se exponen emails en el listado público.
    return { total: items.length, items: items.map(({ email: _email, ...rest }) => rest) };
  });
}
