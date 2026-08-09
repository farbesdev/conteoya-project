# Prompt — ConteoYA Fase 0: Foundation

Actúa como **Software Architect + Backend Architect + Mobile Architect + PostgreSQL Architect + DevOps Engineer senior**.

Estamos construyendo **ConteoYA**, una plataforma para captura y posterior visualización de resultados electorales de las Elecciones Regionales y Municipales 2026 del Perú.

## Stack obligatorio

### Backend
- Laravel 13
- PHP 8.5
- Laravel Sanctum
- PostgreSQL
- Redis
- REST API
- OpenAPI

### Mobile
- Flutter 3.44
- Dart
- SQLite
- Drift

### Storage
- Cloudflare R2 inicialmente
- arquitectura S3-compatible

### Realtime futuro
- Laravel Reverb
- Laravel Echo
- pusher-js

## Objetivo de esta fase

Construir únicamente el foundation de ConteoYA.

No implementar todavía dashboard ni OCR/IA.

## Requerimientos

### Backend

Crear una arquitectura modular preparada para crecimiento.

Implementar:

- configuración de entornos;
- PostgreSQL;
- Redis;
- Sanctum;
- API versionada `/api/v1`;
- manejo uniforme de errores;
- Form Requests;
- API Resources;
- Policies;
- Services/Use Cases;
- DTOs;
- Events;
- Jobs;
- logs estructurados;
- OpenAPI.

### Dominios iniciales

- Identity
- Election
- Geography
- PollingStation
- PoliticalOrganization
- Candidate
- Personero
- Device

### Catálogos

Preparar tablas para:

- departamentos;
- provincias;
- distritos;
- locales;
- mesas;
- elecciones;
- tipos de elección;
- organizaciones políticas;
- candidatos;
- candidaturas.

### JEE JSON

Crear un proceso de importación del archivo:

`candidatos_todos_jee.json`

Debe existir:

```text
staging
→ validation
→ normalization
→ persistence
```

No usar directamente los nombres `strXxx` del JSON en el dominio.

Conservar el JSON original y registrar:

- archivo;
- hash;
- fecha;
- versión;
- cantidad de registros;
- registros válidos;
- registros rechazados;
- errores.

### Personero

Diseñar:

```text
users
personeros
devices
personero_polling_station
```

Un personero debe poder estar asociado a una o varias mesas según las reglas del negocio.

### Seguridad

Implementar:

- Sanctum;
- roles;
- policies;
- rate limiting;
- device registration;
- auditoría básica.

### Calidad

Crear:

- migrations;
- seeders;
- factories;
- tests unitarios;
- tests de integración;
- documentación API.

## Entregables

Entregar:

1. arquitectura;
2. estructura de carpetas;
3. migraciones;
4. modelos;
5. relaciones;
6. endpoints;
7. DTOs;
8. services;
9. policies;
10. seeders;
11. factories;
12. tests;
13. importador JEE;
14. documentación OpenAPI;
15. instrucciones de instalación.

## Restricciones

No implementar OCR.

No implementar IA.

No implementar dashboard.

No implementar Reverb todavía.

No acoplar el dominio a Cloudflare R2.

La solución debe quedar preparada para Fase 1.

## Criterio de aceptación

La API debe permitir:

```text
login
→ obtener usuario
→ obtener personero
→ obtener mesas asignadas
→ consultar catálogo electoral
→ consultar organizaciones
→ consultar candidaturas
```

Todo debe estar versionado bajo `/api/v1`.

Prioriza mantenibilidad, integridad de datos, seguridad y escalabilidad.
