# ConteoYA — Propuesta técnica y plan de implementación
## Plataforma de ingesta, validación y visualización de resultados electorales ERM 2026 — Perú

**Proyecto:** ConteoYA  
**Objetivo:** permitir que personeros registren los resultados de las actas electorales desde una aplicación móvil, incluso sin conexión, con captura manual o asistida por OCR/IA; conservar la imagen del acta como evidencia; sincronizar de forma segura con la API; y posteriormente mostrar resultados consolidados en dashboards y reportes en tiempo real.

---

## 1. Visión

ConteoYA no debe diseñarse únicamente como un aplicativo de conteo de votos. Debe ser una plataforma de **captura, validación, trazabilidad y consolidación de resultados electorales**.

Principios:

1. **Offline-first:** la falta de internet no debe impedir registrar un acta.
2. **Human-in-the-loop:** OCR/IA propone datos; el personero verifica y confirma.
3. **Evidence-first:** la fotografía del acta se conserva como evidencia.
4. **Idempotencia:** una misma operación sincronizada no debe duplicar resultados.
5. **Trazabilidad:** registrar quién, cuándo, desde qué dispositivo y qué versión de los datos fue enviada.
6. **Separación entre catálogo electoral y resultados:** candidatos, organizaciones, circunscripciones y mesas son datos maestros; los resultados son transacciones.
7. **Escalabilidad:** la arquitectura debe soportar un pico importante de sincronizaciones durante la jornada electoral.

---

# 2. Arquitectura general

```text
                    ┌─────────────────────┐
                    │      CONTEOYA       │
                    └──────────┬──────────┘
                               │
             ┌─────────────────┴─────────────────┐
             │                                   │
       FASE 1: INGESTA                    FASE 2: RESULTADOS
             │                                   │
       Flutter 3.44                         Vue 3.5
       SQLite + Drift                       Vuetify 4
       Offline-first                        Tailwind CSS
       Cámara/OCR/IA                        TypeScript 5.9
             │                              Vite 8 + Pinia
             └─────────────────┬─────────────────┘
                               │
                         Laravel 13 API
                           PHP 8.5
                               │
                ┌──────────────┼──────────────┐
                │              │              │
           PostgreSQL        Redis          Reverb
                │              │              │
                └──────────────┼──────────────┘
                               │
                    Cloudflare R2 / S3
```

### Stack principal

| Capa | Tecnología |
|---|---|
| API | Laravel 13 |
| Runtime | PHP 8.5 |
| Autenticación | Laravel Sanctum |
| BD | PostgreSQL |
| Cache/colas | Redis |
| Tiempo real | Laravel Reverb |
| Frontend web | Vue 3.5 + TypeScript 5.9 |
| UI | Vuetify 4 + Tailwind CSS |
| Build | Vite 8 |
| Estado | Pinia |
| Mobile | Flutter 3.44 |
| Persistencia móvil | SQLite + Drift |
| Storage | Cloudflare R2, S3-compatible |
| OCR/IA | Arquitectura desacoplada mediante servicio/adaptador |
| Observabilidad | Logs estructurados + métricas + tracing |
| API | REST + OpenAPI |

> Para Flutter Android se recomienda SQLite + Drift, no localStorage ni IndexedDB. La aplicación debe funcionar como cliente local y sincronizar con la API cuando exista conectividad.

---

# 3. Modelo conceptual

La base de datos no debe tener columnas rígidas como `votos_gobernador`, `votos_alcalde_provincial`, etc.

Debe modelarse alrededor de:

```text
Elección
   │
   ├── Circunscripción
   ├── Organización política
   ├── Candidatura / lista
   └── Mesa
             │
             ▼
           Acta
             │
             ├── Evidencia fotográfica
             ├── Datos generales
             ├── Resultado por organización/lista/candidato
             └── Totales del acta
```

Esto permite soportar:

- Gobernador y vicegobernador regional.
- Consejero regional.
- Alcalde provincial.
- Regidores provinciales.
- Alcalde distrital.
- Regidores distritales.
- Nuevos tipos de elección sin rediseñar toda la BD.

---

# 4. Datos maestros

El archivo `candidatos_todos_jee.json` se considera **fuente de alimentación**, no contrato de la aplicación.

Pipeline:

```text
candidatos_todos_jee.json
          │
          ▼
       staging
          │
          ▼
     normalización
          │
    ┌─────┴──────────┐
    ▼                ▼
organizations    candidates
                       │
                       ▼
                 candidacies
```

Los campos externos como:

```text
strDepartamento
strProvincia
strDistrito
strOrganizacionPolitica
strDocumentoIdentidad
strNombreCompleto
...
```

deben mapearse a un modelo interno limpio.

El JSON original debe conservarse para trazabilidad y posibilidad de reprocesamiento.

---

# 5. Base de datos PostgreSQL

Entidades principales:

```text
users
personeros
devices
elections
electoral_types
departments
provinces
districts
electoral_locations
polling_places
polling_stations
political_organizations
candidates
candidacies
electoral_lists
acts
act_results
act_totals
act_evidence
sync_operations
audit_logs
```

## Acta

Un acta debe contener, como mínimo:

```text
id
election_id
polling_station_id
act_type
registered_voters
voters_who_voted
total_votes
blank_votes
null_votes
challenged_votes
status
captured_by
captured_at
confirmed_at
created_at
updated_at
```

## Resultado

```text
id
act_id
organization_id nullable
candidate_id nullable
list_id nullable
electoral_level
votes
source
confidence nullable
created_at
updated_at
```

`source` puede ser:

```text
MANUAL
OCR
AI
IMPORTED
```

La IA jamás debe convertirse automáticamente en un resultado definitivo.

---

# 6. Evidencia

Cada acta podrá tener una o más evidencias:

```text
act_evidence
    │
    ├── original_image
    ├── processed_image
    ├── OCR_JSON
    └── metadata
```

Metadata recomendada:

```text
storage_provider
object_key
mime_type
size
sha256
width
height
captured_at
device_id
```

La fotografía original debe conservarse sin alteraciones.

---

# 7. Offline-first

El flujo móvil:

```text
              PERSONERO
                  │
                  ▼
            Crear captura
                  │
          ┌───────┴───────┐
          │               │
       Manual          Cámara
          │               │
          │          OCR / IA
          │               │
          └───────┬───────┘
                  ▼
          Revisión humana
                  │
                  ▼
             Confirmación
                  │
                  ▼
             SQLite/Drift
                  │
            Sync Queue
                  │
          ┌───────┴───────┐
       Internet          Sin internet
          │                   │
          ▼                   ▼
        API              queda pendiente
```

La cola debe soportar:

- retry;
- backoff;
- idempotency key;
- estados;
- errores recuperables;
- conflictos;
- reanudación después de cerrar la aplicación.

---

# 8. Fase 0 — Foundation

Objetivo: preparar la infraestructura y datos maestros.

Incluye:

- repositorios;
- estructura Laravel;
- PostgreSQL;
- Sanctum;
- Redis;
- migraciones;
- catálogos;
- importación JEE;
- elecciones;
- mesas;
- organizaciones;
- candidatos;
- personeros;
- dispositivos;
- OpenAPI;
- CI/CD;
- entornos.

**Resultado:** API funcional y catálogo electoral listo.

---

# 9. Fase 1 — Ingesta de actas

Es la fase crítica del proyecto.

### Manual

El personero:

1. inicia sesión;
2. selecciona su mesa;
3. selecciona el tipo de elección;
4. registra los resultados;
5. valida totales;
6. fotografía el acta;
7. confirma;
8. guarda localmente;
9. sincroniza cuando exista internet.

### Captura asistida

```text
Foto
 ↓
Preprocesamiento
 ↓
OCR
 ↓
Extracción estructurada
 ↓
Validación de reglas
 ↓
Personero revisa
 ↓
Personero confirma
 ↓
Persistencia
```

### Reglas

Ejemplo:

```text
SUMA(resultados) + blancos + nulos + impugnados
    ≈
total_votos_emitidos
```

El sistema debe señalar inconsistencias, no inventar valores.

**Resultado:** personeros pueden capturar actas online/offline y sincronizarlas con trazabilidad.

---

# 10. Fase 2 — Consolidación, dashboard y tiempo real

Una vez que la ingesta sea estable:

```text
Actas confirmadas
      │
      ▼
Consolidación
      │
      ├── Regional
      ├── Provincial
      └── Distrital
      │
      ▼
Redis / consultas optimizadas
      │
      ▼
Laravel Reverb
      │
      ▼
Vue / Flutter
```

Dashboards:

- actas esperadas;
- actas recibidas;
- actas pendientes;
- cobertura;
- participación;
- votos por organización;
- votos por candidatura;
- resultados por región;
- provincia;
- distrito;
- mesa;
- hora de recepción;
- avance de captura.

---

# 11. Tiempo real

Se recomienda:

```text
Laravel Broadcasting
        │
      Reverb
        │
 Laravel Echo
        │
 ┌──────┴──────┐
Vue          Flutter
```

No es necesario añadir Socket.IO si Reverb cubre el canal realtime de Laravel.

---

# 12. Fase 3 — Hardening electoral

Antes de una jornada real:

- pruebas unitarias;
- integración;
- E2E;
- pruebas de sincronización;
- pruebas de duplicados;
- pruebas de concurrencia;
- pruebas de carga;
- pruebas de recuperación;
- backups;
- disaster recovery;
- rate limiting;
- auditoría;
- observabilidad;
- seguridad de storage;
- simulación de miles de dispositivos.

---

# 13. Seguridad

Principios:

- Sanctum;
- tokens revocables;
- autorización por rol;
- personero limitado a sus mesas;
- device binding;
- rate limiting;
- idempotencia;
- auditoría;
- cifrado en tránsito;
- URLs temporales para evidencia;
- buckets privados;
- validación estricta de archivos;
- checksum SHA-256;
- protección contra replay;
- logs sin información sensible innecesaria.

---

# 14. Orden recomendado de desarrollo

```text
1. Foundation
2. Catálogo electoral
3. Login
4. Asignación de personero → mesa
5. Registro manual
6. SQLite/Drift
7. Sincronización
8. Evidencia fotográfica
9. Validaciones
10. OCR
11. IA asistida
12. Consolidación
13. Dashboard
14. Realtime
15. Hardening
16. Simulación electoral
```

**No empezar por IA.**

La aplicación debe ser operativa aunque OCR/IA no exista.

---

# 15. Criterio de éxito de ConteoYA

La prueba más importante de Fase 1 será:

> Un personero puede registrar un acta sin internet, cerrar completamente la aplicación, volver a abrirla, visualizar el acta pendiente, recuperar la conexión y sincronizarla una sola vez con el servidor sin perder información ni generar duplicados.

Si esto funciona de forma confiable, la base operacional de ConteoYA estará correctamente construida.
