# ConteoYA — Guías Prácticas y Tutoriales (Diátaxis Framework)

> **Marco de Trabajo:** Diátaxis (Tutoriales & How-To Guides)  
> **Proyecto:** ConteoYA — Elecciones Regionales y Municipales 2026 (ERM 2026)

Este documento complementa la [Arquitectura arc42](file:///home/fredy/Documents/Proyectos/conteoya-project/docs/architecture_arc42.md), el [Modelo de Base de Datos](file:///home/fredy/Documents/Proyectos/conteoya-project/docs/database_modeling.md) y la [Referencia de API](file:///home/fredy/Documents/Proyectos/conteoya-project/docs/api_reference.md), organizando el conocimiento en los 4 cuadrantes de Diátaxis: **Tutoriales, Guías Prácticas (How-To), Explicación y Referencia**.

---

## 🧭 Cuadrante 1: Tutoriales (Aprendizaje Paso a Paso)

### Tutorial 1: Configurar el Entorno de Desarrollo Local desde Cero

**Objetivo:** Levantar la API Laravel con PostgreSQL y ejecutar los tests en menos de 5 minutos.

1. **Clonar el repositorio y configurar variables de entorno:**
   ```bash
   cd api
   cp .env.example .env
   composer install
   php artisan key:generate
   ```
2. **Configurar la base de datos PostgreSQL 16:**
   En `.env`, configurar:
   ```ini
   DB_CONNECTION=pgsql
   DB_HOST=127.0.0.1
   DB_PORT=5432
   DB_DATABASE=conteoya_bd
   DB_USERNAME=postgres
   DB_PASSWORD=tu_password
   ```
3. **Ejecutar migraciones y seeders de datos iniciales:**
   ```bash
   php artisan migrate:fresh --seed
   ```
4. **Verificar la suite de pruebas automatizadas:**
   ```bash
   php artisan test
   ```

---

## 🛠️ Cuadrante 2: Guías Prácticas (How-To Guides)

### Guía 1: ¿Cómo consultar la cédula y listas de una mesa para registrar un acta?

Utiliza el nuevo endpoint `/api/v1/ballot-template` que invoca la función almacenada PostgreSQL `fn_get_polling_station_ballot`:

```bash
curl -X GET "http://localhost:8000/api/v1/ballot-template?polling_station_code=030390&electoral_level_id=1" \
     -H "Authorization: Bearer {tu_token_sanctum}" \
     -H "Accept: application/json"
```

### Guía 2: ¿Cómo registrar un acta electoral de manera idempotente?

Envía la petición con `Idempotency-Key` o `client_operation_id`:

```bash
curl -X POST "http://localhost:8000/api/v1/acts" \
     -H "Authorization: Bearer {tu_token_sanctum}" \
     -H "Content-Type: application/json" \
     -H "Idempotency-Key: 550e8400-e29b-41d4-a716-446655440000" \
     -d '{
       "polling_station_code": "030390",
       "election_id": 1,
       "electoral_level_id": 1,
       "totals": {
         "registered_voters": 300,
         "voters_who_voted": 280,
         "total_votes": 280,
         "blank_votes": 10,
         "null_votes": 5,
         "challenged_votes": 0
       },
       "results": [
         {
           "political_organization_id": 4,
           "votes": 150,
           "source": "MANUAL"
         },
         {
           "political_organization_id": 14,
           "votes": 115,
           "source": "MANUAL"
         }
       ]
     }'
```

### Guía 3: ¿Cómo subir una evidencia fotográfica a Cloudflare R2?

1. **Solicitar URL presignada:**
   ```bash
   POST /api/v1/acts/1/evidence/upload-url
   Payload: { "file_name": "acta_030390.jpg", "file_mime": "image/jpeg", "file_size_bytes": 1048576, "sha256_hash": "..." }
   ```
2. **Subir directamente el binario a Cloudflare R2:**
   ```bash
   PUT {upload_url_recibida} (Headers: Content-Type: image/jpeg)
   ```
3. **Confirmar la subida ante el backend:**
   ```bash
   POST /api/v1/acts/1/evidence/confirm
   Payload: { "object_key": "...", "sha256_hash": "...", "file_size_bytes": 1048576, "captured_at": "..." }
   ```

---

## 💡 Cuadrante 3: Explicación (Conceptos y Diseño)

### ¿Por qué desacoplar `polling_stations` de `electoral_locations`?
En procesos electorales como ERM 2026, los locales de votación pueden cambiar o no estar completamente georreferenciados al inicio. Al dotar a `polling_stations` de campos de ubicación directa (`department_name`, `province_name`, `district_name`, `odpe`, `pdf_file`) y crear la vista `v_polling_stations_ubigeo`, el sistema es capaz de cruzar y resolver las listas electorales oficiales de forma autónoma sin bloquear la operación si no existe un local cargado en `electoral_locations`.

### ¿Cómo funciona el principio Human-in-the-Loop?
El reconocimiento mediante OCR o IA genera sugerencias con un valor de confianza decimal (`confidence`), pero el estado inicial de toda acta procesada por IA permanece en `DRAFT` o sugerencia. El personero humano debe validar visualmente las cifras contra el acta física antes de emitir la confirmación (`POST /api/v1/acts/{id}/confirm`).

---

## 📖 Cuadrante 4: Referencia Técnica

- **Documentación de Arquitectura:** [`docs/architecture_arc42.md`](file:///home/fredy/Documents/Proyectos/conteoya-project/docs/architecture_arc42.md)
- **Modelado de Base de Datos:** [`docs/database_modeling.md`](file:///home/fredy/Documents/Proyectos/conteoya-project/docs/database_modeling.md)
- **Referencia de la API REST:** [`docs/api_reference.md`](file:///home/fredy/Documents/Proyectos/conteoya-project/docs/api_reference.md)
