# Prompt — ConteoYA Fase 3: Hardening, seguridad, rendimiento y simulación electoral

Actúa como **Principal Software Architect + Security Engineer + SRE + Performance Engineer + QA Lead**.

El proyecto es **ConteoYA**, plataforma de captura y visualización de resultados electorales.

Fases anteriores:

- Fase 0: Foundation.
- Fase 1: Ingesta offline-first.
- Fase 2: Dashboard y realtime.

Ahora debemos preparar el sistema para una operación de alta criticidad.

# 1. Objetivo

Validar que ConteoYA soporte una jornada electoral con:

- alta concurrencia;
- miles de dispositivos;
- sincronizaciones simultáneas;
- reintentos;
- fotografías;
- picos de tráfico;
- pérdida de conectividad;
- errores parciales;
- recuperación de servicios.

---

# 2. Seguridad

Auditar:

- Sanctum;
- authorization;
- Policies;
- roles;
- permisos;
- device binding;
- rate limiting;
- CORS;
- CSRF cuando aplique;
- validación de uploads;
- storage privado;
- URLs temporales;
- secrets;
- logs;
- exposición de información.

Probar:

```text
IDOR
Replay
Duplicate request
Privilege escalation
Mass assignment
File upload attacks
Payload abuse
Rate limit bypass
```

---

# 3. Integridad

Garantizar:

```text
1 acta = 1 identidad lógica
```

Usar:

- UUID/ULID;
- unique constraints;
- idempotency keys;
- transactions;
- foreign keys;
- checks;
- hashes.

No depender únicamente de validaciones de aplicación.

---

# 4. Sincronización

Simular:

```text
100 dispositivos
1,000 dispositivos
10,000 dispositivos
```

con:

- mala conectividad;
- requests duplicados;
- timeouts;
- retry;
- interrupción de API;
- recuperación;
- sincronización simultánea.

Verificar que:

```text
NO SE DUPLIQUEN ACTAS
NO SE PIERDAN ACTAS
NO SE CORROMPAN RESULTADOS
```

---

# 5. Performance

Medir:

```text
p50
p95
p99
throughput
error rate
DB connections
Redis latency
queue latency
storage latency
```

Identificar cuellos de botella.

Optimizar:

- índices;
- queries;
- cache;
- queues;
- workers;
- PostgreSQL;
- PHP-FPM;
- Redis;
- Reverb.

---

# 6. Observabilidad

Implementar:

```text
structured logs
metrics
tracing
health checks
readiness
liveness
```

Crear dashboards de:

```text
API
Database
Redis
Queue
Realtime
Storage
Sync
```

Alertas para:

- errores;
- latencia;
- queue backlog;
- DB saturation;
- storage failures;
- sync failures;
- Reverb failures.

---

# 7. Backup

Definir:

```text
PostgreSQL backup
Point-in-time recovery
R2 lifecycle
Evidence retention
Disaster recovery
```

Documentar:

```text
RPO
RTO
```

---

# 8. Disaster Recovery

Simular:

```text
API caída
DB caída
Redis caída
Reverb caída
Storage temporalmente indisponible
Internet intermitente
```

ConteoYA debe degradarse de forma controlada.

Especialmente:

> La caída de Reverb no debe impedir registrar ni consultar datos mediante API.

---

# 9. Auditoría

Registrar:

```text
actor
device
action
entity
entity_id
timestamp
request_id
ip cuando corresponda
before
after
```

Evitar guardar secretos o información innecesaria.

---

# 10. QA

Crear:

### Unit tests
Dominio y reglas.

### Integration tests
API + DB.

### E2E
Flutter/Web + API.

### Load tests
Alta concurrencia.

### Security tests
Autorización y uploads.

### Offline tests
SQLite + Sync Engine.

---

# 11. Simulación electoral

Construir un simulador capaz de generar:

```text
elecciones
regiones
provincias
distritos
locales
mesas
personeros
actas
resultados
```

Generar eventos como:

```text
captura simultánea
sin internet
reconexión
sincronización
duplicados
errores
```

Medir comportamiento.

---

# 12. Go-live checklist

Antes de producción:

```text
[ ] Migraciones revisadas
[ ] Índices revisados
[ ] Backups probados
[ ] Restore probado
[ ] R2 probado
[ ] Sync probado
[ ] Idempotencia probada
[ ] OCR fallback probado
[ ] Seguridad auditada
[ ] Rate limits
[ ] Realtime probado
[ ] Realtime failure probado
[ ] Load test
[ ] Monitoring
[ ] Alerting
[ ] Disaster recovery
[ ] Runbooks
[ ] Rollback
```

# Criterio de aceptación

ConteoYA debe poder demostrar mediante pruebas que una operación electoral simulada puede ejecutarse durante horas bajo carga elevada sin:

- pérdida de actas;
- duplicación;
- corrupción;
- pérdida de evidencia;
- acceso no autorizado;
- inconsistencias de consolidación.

La prioridad es **integridad > disponibilidad > rendimiento > funcionalidades secundarias**.
