// Prueba de carga para la evidencia del dashboard.
//   k6 run -e BASE_URL=http://<ip-aws> load/k6.js
import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE = (__ENV.BASE_URL || 'http://localhost:8080').replace(/\/+$/, '');

// 409 (ya inscripto) y 422 (curso lleno) son respuestas validas de la API: no son fallos.
// Sin esto k6 cuenta todo 4xx como error y falsea http_req_failed.
http.setResponseCallback(http.expectedStatuses({ min: 200, max: 399 }, 409, 422));
const COURSES = ['devops-101', 'k8s-201', 'aws-110', 'data-150', 'node-120'];

export const options = {
  stages: [
    { duration: '30s', target: 20 },
    { duration: '1m', target: 50 },
    { duration: '30s', target: 0 },
  ],
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<300'],
  },
};

export default function () {
  check(http.get(`${BASE}/courses`), { 'catalogo 200': (r) => r.status === 200 });
  const id = COURSES[Math.floor(Math.random() * COURSES.length)];
  check(http.get(`${BASE}/courses/${id}`), { 'curso 200': (r) => r.status === 200 });

  // ~10 % de las iteraciones inscribe a alguien (genera métrica de negocio)
  if (Math.random() < 0.1) {
    const email = `alumno-${__VU}-${__ITER}@example.com`;
    const res = http.post(
      `${BASE}/enrollments`,
      JSON.stringify({ courseId: id, name: `Alumno ${__VU}`, email }),
      { headers: { 'Content-Type': 'application/json' } },
    );
    check(res, { 'inscripcion 201/409/422': (r) => [201, 409, 422].includes(r.status) });
  }
  sleep(0.5);
}
