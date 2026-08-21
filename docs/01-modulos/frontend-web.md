# 01 — Módulo: Frontend Web Dashboard (Vue 3.5 + Vuetify 3)

> **Módulo:** Panel de Control y Visualización Pública de Resultados  
> **Tecnología:** Vue 3.5 (Composition API · `<script setup>`) · Vite 7/8 · TypeScript · Vuetify 3.10 · Pinia · Tabler Icons / Remix Icons

---

## 1. Arquitectura y Estructura del Frontend

El cliente web está diseñado bajo una arquitectura modular desacoplada del backend, con tipado estricto en TypeScript y componentes basados en Vuetify 3:

```text
web/
├── .env.production         # Variables oficiales de producción (https://api.unifact.net.pe/api/v1)
├── .env.development        # Variables de entorno local para desarrollo
├── dist/                   # Bundle estático pre-compilado listo para producción (cero build en VPS)
├── src/
│   ├── api/                # Clientes HTTP (ofetch), DTOs y servicios (candidates, results, auth, mesas)
│   ├── stores/             # Estado global con Pinia (useAuthStore, useResultsStore, useRealtimeStore)
│   ├── pages/              # Enrutamiento automático basado en archivos (unplugin-vue-router)
│   │   ├── admin/          # Panel administrativo privado (dashboard, actas, personeros, usuarios, candidatos)
│   │   ├── resultados/     # Dashboard electoral público standalone (/resultados)
│   │   └── login.vue       # Acceso autenticado (soporta DNI y correo)
│   ├── views/              # Componentes de presentación por feature (candidatos, resultados, mesas, etc.)
│   └── plugins/            # Configuración de Vuetify, i18n, router, iconify, fake-api
```

---

## 2. Gestión de Entornos y Compilación Diferenciada

Para evitar discrepancias entre desarrollo y producción, y para proteger servidores con memoria RAM limitada (ej. VPS de 1 CPU / 2 GB RAM):

| Script | Modo Vite | Archivo `.env` usado | Propósito |
|---|---|---|---|
| `npm run dev` | `development` | `.env.development` | Servidor local con HMR en `http://localhost:5173`. |
| `npm run build:prod` | `production` | `.env.production` | Genera `web/dist/` apuntando a `https://api.unifact.net.pe/api/v1`. |
| `npm run build:dev` | `development` | `.env.development` | Genera bundle para pruebas locales. |

> [!IMPORTANT]
> **Despliegue Ligero en VPS:** La carpeta `web/dist/` se encuentra versionada en el repositorio. En el servidor de producción **no es necesario ejecutar `npm run build`** (lo que evita el error OOM / exit code 137). Basta con ejecutar `git pull origin main` y Nginx servirá los archivos estáticos de forma instantánea.

---

## 3. Control de Tiempo Real y Modo Ahorro en VPS (`useRealtimeStore`)

El frontend integra un mecanismo reactivo para pausar o activar las actualizaciones automáticas:

1. **Configuración por `.env`**:
   ```env
   # false: Apaga Reverb y Polling para reposo total (0% consumo de CPU/RAM)
   VITE_ENABLE_REALTIME=false
   VITE_REALTIME_POLLING_INTERVAL=30000
   ```
2. **Toggle Interactivo en UI**:
   - En el Dashboard (`/admin/dashboard`), los administradores cuentan con un botón interactivo `[En Pausa (Ahorro VPS)]` / `[En Vivo]`.
   - Al estar en pausa, se destruyen todos los intervalos activos (`clearInterval`) y suscripciones WebSocket, permitiendo refrescar bajo demanda con el botón `ri-refresh-line`.

---

## 4. Almacenamiento Local de Imágenes y Logos

El frontend consume directamente los activos visuales desde las rutas locales generadas en el backend:
- **Fotografías de Candidatos**: `/storage/candidates/{id}/foto.webp`
- **Logos de Organizaciones Políticas**: `/storage/political-organizationals/{id}.webp`

Se incluye soporte para previsualización inmediata y carga de archivos mediante `VFileInput` y `FormData` en los formularios de candidatos.
