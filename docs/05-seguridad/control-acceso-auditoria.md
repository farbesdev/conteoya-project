# 05 — Seguridad: Control de Acceso por Roles (RBAC) y Auditoría

> **Módulo:** Seguridad y Trazabilidad  
> **Tema:** Roles, Idempotencia y Bitácora de Auditoría

---

## 1. Matriz de Roles y Permisos

| Operación / Recurso | Rol `PERSONERO` | Rol `DIRECTOR` | Rol `ADMIN` |
|---|:---:|:---:|:---:|
| **Crear / Editar Actas Asignadas** | ✅ | ✅ | ✅ |
| **Crear / Editar Actas No Asignadas** | ❌ (403 Forbidden) | ✅ | ✅ |
| **Subir / Confirmar Evidencias Fotográficas** | ✅ | ✅ | ✅ |
| **Gestión de Mesas (`polling_stations`)** | ❌ | ✅ | ✅ |
| **Gestión de Usuarios y Roles** | ❌ | ❌ | ✅ |
| **Resetear Contraseñas de Usuarios** | ❌ | ❌ | ✅ |
| **Sincronizar Operaciones de Actas** | ✅ | ✅ | ✅ |
| **Sincronizar Operaciones de Personeros/Mesas** | ❌ (403 Forbidden) | ✅ | ✅ |

---

## 2. Idempotencia y Prevención de Duplicados

- **Idempotency-Key HTTP Header:** Interceptado por `IdempotencyMiddleware`. Almacena la respuesta en caché durante 24 horas indexada por el token del usuario y el key.
- **`client_operation_id` (UUIDv4):** Clave de unicidad en la base de datos `sync_operations`. Si llega una operación con el mismo UUID, la API responde con `X-Idempotent-Replayed: true` sin re-ejecutar lógica de negocio.

---

## 3. Trazabilidad Inmutable (`audit_logs`)

Cada mutación crítica en el sistema genera un registro en `audit_logs` con:
- `user_id`: Identificador del usuario emisor.
- `action`: Código de acción (`INGEST_ACT`, `CONFIRM_ACT`, `UPLOAD_EVIDENCE`, etc.).
- `entity_type` / `entity_id`: Tabla y registro afectado.
- `ip_address`: Dirección IP de origen.
- `user_agent`: Navegador o versión de app móvil.
- `payload`: Snapshot JSON con los datos recibidos.
- `created_at`: Marca temporal `TIMESTAMPTZ`.
