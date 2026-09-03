# AGENTS.md — Guía de conexión Flutter ↔ Backend SSE

Este archivo le da a una sesión de Opencode **todo el contexto necesario** para conectar esta app Flutter al backend SSE (Sistema de Seguimiento por Etapas). Si abres una sesión nueva en esta carpeta, esta guía se carga automáticamente.

---

## Qué es SSE

Sistema de trazabilidad de procesos por etapas. Cada vez que un operario registra una etapa, se calcula un hash SHA-256 de los datos y se envía a una transacción en **blockchain (Polygon Amoy)**. Los registros confirmados quedan **inmutables** (triggers de PostgreSQL bloquean UPDATE/DELETE). El proceso se "sella" con un hash global cuando todas sus etapas están confirmadas.

**Jerarquía de datos:**
```
Industria
  └─ Empresa / Cliente
       └─ Proceso  (ej. "TMB-2026-001")
            └─ Etapa 1, Etapa 2, Etapa 3...
                 └─ Registro de datos (JSON dinámico según plantilla)
                      └─ Evidencia adjunta (fotos, documentos → S3)
```

**Roles:** `admin` (total) · `coordinador` (su industria) · `operario` (solo sus etapas asignadas) · `auditor` (solo lectura) · portal público sin login.

---

## Arquitectura (MUY importante)

```
Flutter app ──HTTPS + Bearer JWT──▶ API REST (Express, Node.js, puerto 3500) ──▶ PostgreSQL + S3 + Polygon Amoy
```

- **AWS se usa SOLO en el backend.** La app Flutter **NO necesita SDK de AWS, ni credenciales AWS, ni Amplify**. Solo necesita un cliente HTTP y manejar un JWT.
- **La autenticación usa AWS Cognito**: el backend valida las credenciales contra el User Pool (`oraculosandbox88a626ac`, email como username) y emite un JWT interno de sesión. Los usuarios viven en la nube (Cognito), no en la BD del backend. La app solo hace `POST /auth/login` con username o email + password.
- Las evidencias (fotos) se suben **por el backend** (`POST /uploads/...`) que las reenvía a S3 y responde con una **URL firmada de lectura (1h de validez)**. Flutter nunca toca S3 directamente.

---

## Repositorios

- **Este proyecto**: app Flutter (`sse_frontend_mobil`).
- **Monorepo del backend**: carpeta hermana `../sse-sistema-seguimiento/`.
  - Backend (Express + TypeScript): `backend/src/` — `index.ts` monta los routers; `routes/` cada grupo; `db/queries.ts` SQL; `middleware/auth.ts` JWT/roles.
  - **Cliente React Native existente (mejor referencia de tipos/endpoints)**: `../sse-sistema-seguimiento/mobile/src/api/client.ts`.
  - Cliente web: `../sse-sistema-seguimiento/frontend/src/api/client.ts`.
  - Esquema de BD (fuente de verdad): `../sse-sistema-seguimiento/db/00_full_schema.sql`.
  - Nota: `amplify/` en el monorepo pertenece a OTRO proyecto del equipo (oraculosandbox); ignorarlo.

---

## Backend desplegado

- **Base URL:** `https://api.sse-sistema.com`
- **Web publico de verificacion:** `https://sse-sistema.com` — el QR de trazabilidad de la app apunta a `https://sse-sistema.com/verificar?codigo=<PROCESO>`.
- Health check: `GET /health` → `{ status: 'ok' }`
- CORS habilitado globalmente.
- Token JWT expira a las **8 horas**. Se envía en header `Authorization: Bearer <token>`.
- **Error 401**: si ocurre en cualquier ruta distinta de `/auth/login`, la sesión expiró → borrar token y volver al login. Un 401 en `/auth/login` significa credenciales incorrectas (no es sesión expirada).
- Errores del backend: JSON `{ error: string }` con el código HTTP correspondiente (400/401/403/404/409/500).

---

## Endpoints principales (app de operario)

| Método | Ruta | Auth | Descripción |
|---|---|---|---|
| POST | `/auth/login` | no | Body `{username, password}` (username o email) → `{token, user}`. Si la contraseña es temporal responde `{requires_password_change, username, session}` |
| POST | `/auth/complete-password-change` | no | Body `{username, new_password, session}` → completa el primer cambio de contraseña → `{token, user}` |
| GET | `/auth/me` | sí | → `{ user }` |
| GET | `/process` | sí | Procesos visibles por rol (operario: donde tiene etapas) → `Process[]` (lista con `total_steps`, `confirmed_steps`) |
| GET | `/process/:id` | sí | → `{ process, steps }` (detalle con `steps[].field_schema`) |
| POST | `/process/:id/step/:stepId` | sí | Body `{data: {...}}` → registra la etapa → `StepRecord` (estado `pending`) |
| GET | `/process/:id/step/:stepId/comments` | sí | → `Comment[]` |
| POST | `/process/:id/step/:stepId/comments` | sí | Body `{content}` → `Comment` |
| GET | `/uploads/:processId/:stepId` | sí | → `Attachment[]` (incluye `url` firmada 1h) |
| POST | `/uploads/:processId/:stepId` | sí | multipart/form-data, campo **`file`**, máx **10 MB**, solo `image/jpeg | image/png | image/webp | application/pdf` → `Attachment` |
| DELETE | `/uploads/:processId/:stepId/:attachmentId` | sí | Solo dueño o admin → `{ok}` |
| GET | `/notifications` | sí | → `{ notifications, unread }` |
| PUT | `/notifications/read-all` | sí | → `{ok}` |
| GET | `/public/process/:code` | **no** | Verificación pública por código del proceso (ej. `TMB-2026-001`) → `{process, steps}` |

### Endpoints de admin/coordinador (web)

| Método | Ruta | Descripción |
|---|---|---|
| POST | `/process` | Crear proceso (`client_name` obligatorio; coord solo su industria) |
| PUT | `/process/:id` | Editar proceso (solo admin, si no está cerrado) |
| POST | `/process/:id/close` | Sellar proceso manualmente |
| GET | `/process/:id/verify` | Verificar integridad de cada registro (recalcula hash vs BD vs cadena) |
| GET | `/process/:id/verify-seal` | Verificar el sellado global del proceso |
| PUT | `/process/:id/step/:stepId/assign` | Asignar operario a una etapa `{user_id}` |
| PUT | `/process/:id/step/:stepId/deadline` | Poner fecha límite `{deadline | null}` |
| GET | `/process/:id/audit-log` | Auditoría del proceso |
| GET | `/process/next-code/:code` | Siguiente consecutivo de plantilla |
| GET | `/templates`, `/templates/:id` | Plantillas |
| POST/PUT/DELETE | `/templates[/:id]` | CRUD plantillas |
| GET/POST | `/industries`, `/clients` | Catálogos |
| DELETE | `/industries/:id`, `/clients/:id` | Eliminar catálogo |
| GET/POST | `/auth/users`, `/auth/operarios` | Usuarios/operarios |
| PUT/DELETE | `/auth/users/:id` | Editar/eliminar usuario |
| GET | `/auth/users/:id/assignments` | Etapas asignadas a un operario |
| GET | `/auth/users/:id/activity` | Todo lo que registró un usuario |
| POST | `/auth/users/:id/unassign-all` | Desasignar todas las etapas |
| GET | `/auth/audit-log` | Auditoría de usuarios |
| GET | `/metrics` | Métricas globales |
| GET | `/export/processes`, `/export/process/:id` | Exportar Excel |

---

## Modelos de datos (JSON del backend → mapéalos a Dart)

```dart
// User (roles: admin | coordinador | operario | auditor)
{ id, username, name, email?, role, industry? }

// Process (lista: trae además total_steps, confirmed_steps)
{ id, name, description?, status, industry?, client_name?,
  process_hash?, close_tx_hash?, close_block?, closed_at?,
  closed_by_username?, assigned_name?, created_at, updated_at }

// Step
{ id, process_id, name, description?, order_index,
  assigned_to?, assigned_username?,
  field_schema: FieldDef[], deadline?, record?: StepRecord }

// FieldDef — schema dinámico del formulario de una etapa
{ name, label,
  type: 'texto'|'numero'|'fecha'|'hora'|'seleccion'|'booleano'|'parrafo',
  required, options?: string[] }   // options solo si type === 'seleccion'

// StepRecord
{ id, step_id, process_id, data: {...}, data_hash,
  tx_hash?, block_number?, status: 'pending'|'confirmed'|'failed',
  completed_at?, created_at, recorded_by_username? }

// Attachment
{ id, process_id, step_id, storage_key, url, original_name,
  mimetype, size_bytes, created_at, uploaded_by_username? }

// Notification
{ id, type, title, body?, link?, read, created_at }

// PublicProcess / PublicStep (GET /public/process/:code)
// process: { id, name, description?, industry?, status, created_at,
//            closed_at?, process_hash?, close_tx_hash?, close_block?, closed_by_username? }
// steps: [{ order_index, name, description?, recorded_by_name?,
//           status, data_hash?, tx_hash?, block_number?, recorded_at?, completed_at? }]

// Comment
{ id, process_id, step_id, user_id, author_name, content, created_at }
```

**Flujo para registrar una etapa:**
1. `GET /process/:id` → toma `steps`, encuentra la etapa asignada.
2. Renderiza un formulario dinámico a partir de `field_schema` (usa `label` como título, valida `required`, para `seleccion` muestra `options`).
3. `POST /process/:id/step/:stepId` con `{ data: { <campo>: <valor> } }` → responde `StepRecord` con `status: 'pending'`.
4. La confirmación en blockchain es **asíncrona** (cola interna del backend): `pending → confirmed` (o `failed`). Se ve el cambio al refrescar el detalle.
5. Adjuntar fotos con `POST /uploads/...` (multipart, campo `file`). Para mostrar, usar la `url` firmada del GET (caduca a 1h).

---

## Reglas de negocio críticas

- **Usuarios centralizados en AWS Cognito** (no hay auto-registro): los crea un admin/coordinador con `POST /auth/users` (email obligatorio; es el identificador en Cognito). No existe endpoint público de registro.
- **Flujo de login**: `POST /auth/login`. Si la respuesta trae `requires_password_change: true` (contraseña temporal), la app debe mostrar una pantalla de "nueva contraseña" y llamar `POST /auth/complete-password-change` con `username`, `new_password` y `session`. Ahí se obtiene el `{token, user}` definitivo.
- Un registro de etapa **confirmado es inmutable**: no se puede editar ni borrar. Un registro en `pending` o `failed` sí puede re-registrarse (el POST sobrescribe).
- Un proceso **requiere** empresa/cliente (`client_name`) al crearse.
- Un operario solo ve/registra las etapas que tiene asignadas.
- Solo el **dueño del adjunto o un admin** puede eliminarlo.
- El sellado del proceso es automático (checker cada 10 min cuando todas las etapas están confirmadas) o manual (admin/coordinador, `POST /process/:id/close`).
- El `data` de un registro es `Record<String, dynamic>` — el backend calcula el hash ordenando las claves, así que la app debe enviar los nombres de campo EXACTOS del `field_schema`.

---

## Infraestructura de producción (MUY importante)

- **EC2** (donde corre todo): `ubuntu@ip-172-31-14-46` en `~/sse`.
- **Base de datos PostgreSQL → RDS** (NO es un contenedor Docker):
  - Host: `sse-db.cytyo4006n0s.us-east-1.rds.amazonaws.com`
  - Usuario: `sse_user` · Base: `sse_db` · Puerto: `5432`
  - Credenciales env: `DB_USER=sse_user`, `DB_PASSWORD=sse_pass`, `DB_HOST=<rds-host>`, `DB_PORT=5432`
  - ⚠️ **No hay contenedor `postgres`** en Docker Compose — la DB es RDS externa.
- **Contenedores Docker en EC2:**
  - `sse_backend` → API (Express/Node, puerto 3500).
  - `sse_frontend` → web de verificación pública (`https://sse-sistema.com`).

**Ejecutar una migración en producción (RDS):**
1. SSH a la EC2:
   ```bash
   ssh -i <tu-key.pem> ubuntu@ip-172-31-14-46
   ```
2. Usar `psql` con el cliente de Postgres (instalar si falta: `sudo apt install -y postgresql-client-16`):
   ```bash
   PGPASSWORD=sse_pass psql -h sse-db.cytyo4006n0s.us-east-1.rds.amazonaws.com -U sse_user -d sse_db << 'EOF'
   -- ...SQL...
   EOF
   ```

**Reiniciar el backend tras cambios:** desde la EC2, `docker restart sse_backend`.

---

## Desarrollo local

- Backend local: en el monorepo, `cd backend && npm run dev` (puerto 3500). Nota: la BD de desarrollo también puede apuntar a RDS vía las vars `DB_*`; no dependas de un contenedor `postgres` local.
- Base URL según entorno:
  - Emulador Android: `http://10.0.2.2:3500`
  - Dispositivo físico: IP local del PC (ej. `http://192.168.0.28:3500`)
  - Producción: `https://api.sse-sistema.com`
- La API de producción ya está desplegada y accesible desde cualquier red (no requiere estar en el mismo WiFi).

---

## Recomendaciones de implementación Flutter

- Cliente HTTP: `http` o `dio`. Un solo `ApiClient` con base URL configurable (`String.fromEnvironment` o `--dart-define`) para alternar prod/local.
- Guardar token con `flutter_secure_storage`; modelo `AuthUser` persistido para arrancar directo al home.
- En login: si la respuesta trae `requires_password_change: true`, navegar a una pantalla de "cambiar contraseña" y usar `POST /auth/complete-password-change`.
- Interceptor global: si cualquier respuesta ≠ `/auth/login` devuelve 401, limpiar token y navegar al login.
- Validar `field_schema.required` y tipos (`numero` → `num.tryParse`, `fecha`/`hora` → pickers, `booleano` → switch, `seleccion` → dropdown de `options`).
- Para subir foto: `image_picker` → `http.MultipartRequest` con campo `file` (`http.MultipartFile.fromBytes` o `fromPath`).
- Imágenes de S3: la URL firmada caduca (1h) — no cachear la URL indefinidamente; si falla, re-solicitar el GET de adjuntos.

---

## Features de blockchain implementadas en la app

- **Verificar integridad** → `GET /process/:id/verify` (admin/coord/auditor): pantalla por etapas comparando dbHash vs recomputado vs chain (`lib/providers/verify_provider.dart`, `lib/screens/verify_process_screen.dart`).
- **Verificar sello** → `GET /process/:id/verify-seal` (admin/coord/auditor, proceso cerrado): checks BD/recalculado/chain + intact + TX de cierre + link Polygonscan (`lib/providers/seal_verify_provider.dart`, `lib/screens/verify_seal_screen.dart`).
- **Trazabilidad en el detalle** → cada etapa confirmada muestra block con SHA-256 + TX hash + bloque al que se puede tocar para abrir `amoy.polygonscan.com/tx/<hash>` (`url_launcher`).
- **Código QR** → tarjeta naranja en el detalle para admin/coord/auditor. El QR codifica `https://sse-sistema.com/verificar?codigo=<PROCESO>` (web público). Botón "Ver trazabilidad en la app" → `GET /public/process/:code` (sin login) (`lib/screens/traceability_qr_screen.dart`, `lib/screens/public_traceability_screen.dart`).
- **Sellar proceso (manual)** → `POST /process/:id/close` (admin/coord, proceso activo y todas las etapas confirmadas). Confirmación + feedback + recarga (`lib/providers/seal_process_provider.dart`).
- Dependencias añadidas: `fl_chart`, `url_launcher`, `qr_flutter`.
- **Skeletons / estados vacíos** reutilizables: `lib/widgets/skeleton.dart` (`SkeletonBox`, `CardSkeleton`, `ListSkeleton`) y `lib/widgets/empty_state.dart` (`EmptyState`).
