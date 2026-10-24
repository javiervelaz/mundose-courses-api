import { randomUUID } from 'node:crypto';
import { type Course, seedCourses } from './data/courses.js';

export interface Enrollment {
  id: string;
  courseId: string;
  name: string;
  email: string;
  createdAt: string;
}

export type EnrollResult =
  | { ok: true; enrollment: Enrollment }
  | { ok: false; reason: 'course_not_found' | 'already_enrolled' | 'course_full' };

/** Almacenamiento en memoria: el foco del proyecto es el flujo DevOps, no la persistencia. */
export class Store {
  private readonly courses = new Map<string, Course>();
  private readonly enrollments: Enrollment[] = [];

  constructor(courses: readonly Course[] = seedCourses) {
    for (const c of courses) this.courses.set(c.id, { ...c });
  }

  listCourses(category?: string): Course[] {
    const all = [...this.courses.values()];
    return category ? all.filter((c) => c.category === category) : all;
  }

  getCourse(id: string): Course | undefined {
    return this.courses.get(id);
  }

  seatsLeft(courseId: string): number {
    const course = this.courses.get(courseId);
    if (!course) return 0;
    return course.capacity - this.enrollments.filter((e) => e.courseId === courseId).length;
  }

  listEnrollments(courseId?: string): Enrollment[] {
    return courseId ? this.enrollments.filter((e) => e.courseId === courseId) : [...this.enrollments];
  }

  enroll(input: { courseId: string; name: string; email: string }): EnrollResult {
    if (!this.courses.has(input.courseId)) return { ok: false, reason: 'course_not_found' };
    const email = input.email.trim().toLowerCase();
    if (this.enrollments.some((e) => e.courseId === input.courseId && e.email === email)) {
      return { ok: false, reason: 'already_enrolled' };
    }
    if (this.seatsLeft(input.courseId) <= 0) return { ok: false, reason: 'course_full' };

    const enrollment: Enrollment = {
      id: randomUUID(),
      courseId: input.courseId,
      name: input.name.trim(),
      email,
      createdAt: new Date().toISOString(),
    };
    this.enrollments.push(enrollment);
    return { ok: true, enrollment };
  }
}
