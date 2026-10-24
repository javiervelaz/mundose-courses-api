export type Category = 'devops' | 'cloud' | 'data' | 'desarrollo' | 'seguridad';

export interface Course {
  id: string;
  title: string;
  category: Category;
  modality: 'online' | 'híbrida';
  weeks: number;
  capacity: number;
}

// Catálogo semilla (datos ficticios con fines didácticos).
export const seedCourses: readonly Course[] = [
  { id: 'devops-101', title: 'Diplomatura en DevOps', category: 'devops', modality: 'online', weeks: 24, capacity: 40 },
  { id: 'k8s-201', title: 'Kubernetes de cero a producción', category: 'devops', modality: 'online', weeks: 8, capacity: 30 },
  { id: 'aws-110', title: 'Fundamentos de AWS', category: 'cloud', modality: 'online', weeks: 6, capacity: 50 },
  { id: 'data-150', title: 'Ciencia de datos con Python', category: 'data', modality: 'híbrida', weeks: 12, capacity: 35 },
  { id: 'node-120', title: 'Backend con Node.js y TypeScript', category: 'desarrollo', modality: 'online', weeks: 10, capacity: 45 },
  { id: 'sec-130', title: 'Ciberseguridad aplicada', category: 'seguridad', modality: 'online', weeks: 8, capacity: 2 },
];
