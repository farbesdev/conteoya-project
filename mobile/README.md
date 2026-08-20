# conteoya_mobile — App Móvil Flutter 3.44 (Fase 1 — Ingesta)

App móvil **offline-first** para la captura, validación y sincronización de actas electorales en las Elecciones Regionales y Municipales 2026 (ERM 2026) — Perú.

Permite a los personeros registrar actas desde la mesa de sufragio, con o sin conexión a internet, usando captura manual o asistida por OCR/IA.

---

## 🛠️ Stack Tecnológico

| Capa | Tecnología |
|------|-----------|
| Framework | Flutter 3.44 (Dart 3.12+) |
| Persistencia local | Drift 2.24 (SQLite) — schema v4 |
| State Management | Riverpod 2.6 |
| HTTP Client | Dio 5.7 |
| Hashing (evidencias) | crypto 3.0 (SHA-256) |
| UUID | uuid 4.5 |
| Conectividad | connectivity_plus 6.1 |
| Cámara / Galería | image_picker 1.1 |

---

## ⚙️ Instalación

### Requisitos previos

- Flutter 3.44+ (`flutter --version`)
- Dart 3.12+
- Android SDK / Xcode (para ejecutar en dispositivo/emulador)

### Pasos

```bash
cd mobile/

# 1. Instalar dependencias
flutter pub get

# 2. Generar código Drift (base de datos local)
flutter pub run build_runner build --delete-conflicting-outputs

# 3. Correr en modo debug
flutter run

# 4. Correr en modo release
flutter run --release
```

### Variables de entorno

Configurar la URL base de la API en `lib/core/network/`:

```dart
// lib/core/network/api_client.dart
const String kApiBaseUrl = 'http://localhost:8000/api/v1';
```

---

## 🏛️ Arquitectura

La app sigue **Clean Architecture** con separación estricta en 3 capas:

```
Domain → Data → Presentation
```

Nunca se saltan capas. Las capas internas no dependen de las externas.

```text
lib/
├── app/                        # Configuración de la app, rutas, tema
├── core/
│   ├── database/               # Drift schema (AppDatabase, tablas, DAOs)
│   ├── network/                # ApiClient (Dio), interceptores, auth
│   ├── sync/                   # SyncEngine, BackoffCalculator
│   ├── theme/                  # Tema visual (colores, tipografía)
│   ├── utils/                  # Utilidades compartidas
│   └── widgets/                # Widgets reutilizables
└── features/
    ├── acts/                   # Captura y gestión de actas electorales
    ├── auth/                   # Login, sesión, token Sanctum
    ├── dashboard/              # Panel principal por rol
    ├── mesas/                  # Mesas asignadas al personero
    ├── ocr_ai/                 # Reconocimiento OCR/IA de actas
    ├── personeros/             # Gestión de personeros (ADMIN/DIRECTOR)
    ├── sync/                   # UI de estado de sincronización
    └── users/                  # Gestión de usuarios (ADMIN/DIRECTOR)
```

Cada feature sigue la estructura: `domain/` → `data/` → `presentation/`

---

## 🗄️ Base de Datos Local (Drift / SQLite)

**Schema Version:** `4`

| Tabla Drift | Descripción |
|-------------|-------------|
| `LocalActsTable` | Actas electorales creadas offline |
| `LocalActTotalsTable` | Totales de control del acta |
| `LocalActResultsTable` | Resultados de votos por organización política |
| `LocalActEvidenceTable` | Evidencias fotográficas (path local + SHA-256) |
| `LocalSyncOperationsTable` | Cola de operaciones pendientes de sincronización |
| `LocalPollingStationsTable` | Mesas de sufragio asignadas (descargadas del servidor) |
| `LocalPoliticalOrganizationsTable` | Organizaciones políticas (descargadas del servidor) |
| `LocalPersonerosTable` | Perfil del personero autenticado |

Configuración SQLite activa:
- `PRAGMA foreign_keys = ON`
- `PRAGMA journal_mode = WAL`

---

## ⚡ Motor de Sincronización Offline (SyncEngine)

El `SyncEngine` gestiona la sincronización bidireccional Flutter ↔ Laravel:

- **Cola local:** Todas las operaciones se encolan en `LocalSyncOperationsTable` con estado `PENDING`
- **Idempotencia:** Cada operación tiene un `client_operation_id` (UUID) generado en el cliente. El servidor nunca lo genera.
- **Retry con Exponential Backoff:** `BackoffCalculator` con jitter aleatorio
- **Checksum:** SHA-256 de cada payload para verificar integridad
- **Resolución de conflictos:** `last-write-wins` con timestamp del servidor

### Estados de una SyncOperation

```
PENDING → PROCESSING → DONE
                     ↘ ERROR → PENDING (retry)
                     ↘ FAILED (max intentos)
```

---

## 🎨 Sistema de Diseño Mobile-First (`core/theme/`)

La aplicación implementa las directrices de los skills **`mobile-design`**, **`ui-styling`** y **`ui-ux-pro-max`**:

- **Dark / Light Mode Switcher:** Toggle animado con rotación en el AppBar que conmuta instantáneamente entre temas claro y oscuro adaptando todas las superficies, modales y campos de entrada.
- **Anti-Border Hell:** Se eliminó la sobrecarga de bordes duros de 1px. La jerarquía se logra mediante **elevación tonal** (`surface` / `surfaceElevated`) y bordes *hairline* ultra-sutiles de `0.5px` (`0x1AFFFFFF` en Dark / `0x0F0F172A` en Light).
- **Anti-Chromostereopsis y Calibración WCAG 2.1 AAA:** Helpers dinámicos (`warningOf`, `successOf`, `dangerOf`) ajustan la gama cromática:
  - `Amber 400` (`#FBBF24`) en modo oscuro para evitar fatiga visual sobre fondo oscuro.
  - `Amber 700` (`#B45309`) en modo claro garantizando contraste superior a **5.5:1** para lectura bajo luz solar directa.
- **Prevención de Desbordamientos (*RenderFlex Overflow*):** Todos los selectores desplegables en modales cuentan con `isExpanded: true` y truncamiento con elipsis.
- **Ergonomía Táctil:**
  - **Padding Anti-Colisión:** `110dp` en listas para que el FAB no tape la última tarjeta ni sus botones.
  - **Touch Targets:** Botones de acción ergonómicos con `minimumSize: Size(44, 44)`.
  - **Carrusel de Filtros Móvil:** Navegación horizontal fluida (`BouncingScrollPhysics`) con chips redondeados de 20px.

---

## 🔑 Principios Críticos

1. **Offline es el modo normal.** Toda acción del usuario funciona sin red. La sync es siempre asíncrona.
2. **La IA nunca confirma un acta.** OCR/IA solo propone valores con `source: AI|OCR` y `confidence`. El personero siempre confirma.
3. **SHA-256 se calcula en el cliente** antes de guardar localmente y antes de subir a R2.
4. **Validaciones no bloqueantes (Soft Warnings):** Discrepancias en la suma de votos se advierten visualmente pero no impiden registrar el acta física.
5. **Null safety estricto.** No se usa `dynamic` ni el operador `!` sin justificación.
6. **Riverpod para estado global.** No se usa `setState` para estado de aplicación.
7. **Autenticación controlada:** `SyncEngine` comprueba `hasAuthToken` y gestiona respuestas `401/403` de forma resiliente.

---

## 🔧 Comandos útiles

```bash
# Regenerar código Drift tras cambios en tablas
flutter pub run build_runner build --delete-conflicting-outputs

# Análisis estático
flutter analyze

# Tests
flutter test

# Limpiar build
flutter clean && flutter pub get

# Ver dependencias desactualizadas
flutter pub outdated
```

---

## 📄 Licencia

Proyecto privado — Plataforma ConteoYA para ERM 2026.
