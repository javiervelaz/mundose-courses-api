import type { FastifyInstance } from 'fastify';
import type { Store } from '../store.js';

export function coursesRoutes(app: FastifyInstance, store: Store): void {
  app.get<{ Querystring: { category?: string } }>(
    '/courses',
    {
      schema: {
        querystring: {
          type: 'object',
          properties: { category: { type: 'string', enum: ['devops', 'cloud', 'data', 'desarrollo', 'seguridad'] } },
          additionalProperties: false,
        },
      },
    },
    async (request) => {
      const courses = store.listCourses(request.query.category);
      return {
        total: courses.length,
        items: courses.map((c) => ({ ...c, seatsLeft: store.seatsLeft(c.id) })),
      };
    },
  );

  app.get<{ Params: { id: string } }>('/courses/:id', async (request, reply) => {
    const course = store.getCourse(request.params.id);
    if (!course) return reply.code(404).send({ error: 'course_not_found' });
    return { ...course, seatsLeft: store.seatsLeft(course.id) };
  });
}
