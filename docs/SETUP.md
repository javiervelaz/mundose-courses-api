# Setup (etapa E0) — una sola vez

Tiempo estimado: 1,5 h. Al terminar, cada push a `main` despliega solo.

## 1. Herramientas en tu máquina (Windows)

| Herramienta | Para qué | Comprobar |
| --- | --- | --- |
| Git | repo | `git --version` |
| Node.js 22 LTS | correr tests localmente | `node -v` |
| Docker Desktop | probar la imagen | `docker version` |
| Terraform ≥ 1.10 | aplicar el bootstrap | `terraform version` |
| AWS CLI v2 | credenciales para el bootstrap | `aws sts get-caller-identity` |
| VirtualBox 7.1 + Vagrant | entorno local (E5) | `vagrant --version` |

> **Probalo ya:** `vagrant up` con Hyper-V/WSL2 activos puede fallar o ir muy lento. Si pasa, desactivá "Plataforma de máquina virtual" en *Características de Windows* hasta la entrega (Docker Desktop deja de andar mientras tanto).

## 2. Repositorio en GitHub

1. Crear el repo **público** `javiervelaz/mundose-courses-api` y subir este código a `main`.
2. *Settings → Branches*: proteger `main` (PR obligatorio + checks `quality`, `security`, `build` en verde).
3. *Settings → Environments*: crear `production`.

## 3. Bootstrap de AWS (estado remoto + OIDC)

Con tu usuario de AWS configurado (`aws configure`):

```bash
cd infra/bootstrap
terraform init
terraform apply      # si tu cuenta ya tiene el proveedor OIDC de GitHub: -var create_oidc_provider=false
terraform output
```

Crea un bucket S3 cifrado y versionado para el estado y un rol IAM que **solo** puede asumir el environment `production` de este repo. El pipeline no guarda access keys.

Opcional pero recomendado: *Billing → Budgets* → alerta de USD 5.

## 4. Variables y secrets del repo

*Settings → Secrets and variables → Actions*

| Tipo | Nombre | Valor |
| --- | --- | --- |
| Variable | `AWS_ROLE_ARN` | output `aws_role_arn` del bootstrap |
| Variable | `TF_STATE_BUCKET` | output `tf_state_bucket` del bootstrap |
| Variable | `AWS_REGION` | `us-east-1` |
| Variable | `ADMIN_CIDR` | tu IP pública + `/32` (ver https://checkip.amazonaws.com) |
| Secret | `SNYK_TOKEN` | app.snyk.io → Account settings → Auth token |
| Secret | `SONAR_TOKEN` | sonarcloud.io → My Account → Security |
| Secret | `GRAFANA_ADMIN_PASSWORD` | mínimo 12 caracteres |

## 5. SonarQube Cloud

1. Entrar a sonarcloud.io con GitHub, importar el repo (organización `javiervelaz`).
2. *Administration → Analysis Method*: **desactivar** "Automatic Analysis" (lo hace el pipeline).
3. Si la organización o la key del proyecto difieren, ajustar `sonar-project.properties`.

## 6. Imagen pública en GHCR

Después del primer pipeline en `main`: *Packages → mundose-courses-api → Package settings → Change visibility → Public*. La EC2 y la VM local hacen pull sin credenciales.

GHCR crea el paquete como privado, así que el **primer** deploy falla en el smoke test (la EC2 no puede bajar la imagen). Hacé público el paquete y usá *Re-run failed jobs*: desde ahí en adelante no vuelve a pasar.

## Listo cuando

- `terraform apply` del bootstrap terminó sin errores.
- Las 4 variables y los 3 secrets están cargados.
- Un PR de prueba muestra los checks corriendo.
