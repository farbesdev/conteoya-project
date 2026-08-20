# 01 — Módulo: Aplicación Móvil (Flutter 3.44)

> **Módulo:** App Móvil  
> **Tecnología:** Flutter 3.44+ · Dart · Riverpod · Drift (SQLite) v5 · Material 3

---

## 1. Arquitectura de la App Móvil

La aplicación móvil está estructurada bajo **Clean Architecture** modular por features:

```text
mobile/lib/
├── app/            # App Shell, navegación por roles, toggle de tema
├── core/
│   ├── database/   # Drift SQLite v5 (tables.dart, app_database.dart, DAOs)
│   ├── network/    # ApiClient (Dio), interceptores de autenticación, manejo 401/403
│   ├── sync/       # SyncEngine, BackoffCalculator, Connectivity
│   ├── theme/      # Tokens de diseño (AppColors, AppTheme Material 3)
│   ├── utils/      # HashUtils (cálculo SHA-256 local)
│   └── widgets/    # Componentes base (AppCard, StatMetricCard, etc.)
└── features/
    ├── acts/       # Registro y validación de actas electorales (Regional/Municipal)
    ├── auth/       # Login, selector de servidor demo, tokens Sanctum
    ├── dashboard/  # Paneles según rol (Admin / Personero)
    ├── mesas/      # Consulta y asignación de mesas de sufragio
    ├── ocr_ai/     # Captura de cámara, recorte y preview de reconocimiento
    ├── personeros/ # Gestión de personeros de mesa
    ├── sync/       # Panel de estado de sincronización offline
    └── users/      # Gestión integral de usuarios del sistema
```

---

## 2. Sistema de Diseño Mobile-First (`core/theme/`)

La interfaz móvil fue optimizada siguiendo los estándares de **`mobile-design`**, **`ui-styling`** y **`ui-ux-pro-max`**:

### 2.1. Eliminación de Saturación por Bordes (*Anti-Border Hell*)
- **Separación Tonal:** Se reemplazó el contorno oscuro perimetral en tarjetas, contenedores anidados y avatares por elevación tonal de superficies (`surface` y `surfaceElevated`).
- **Trazo Hairline Suave:** Los divisores y bordes mínimos se estandarizaron en **`0.5px`** con opacidad sutil (`0x1AFFFFFF` en modo oscuro / `0x0F0F172A` en modo claro).
- **Badges y Chips Tonal:** Fondos translúcidos pasteles (alpha 12%) sin bordes exteriores redundantes.

### 2.2. Accesibilidad Cromática y Anti-Chromostereopsis (WCAG 2.1 AA/AAA)
- Los colores de estado (`warning`, `success`, `danger`, `info`, `accent`) se adaptan dinámicamente según el brillo del entorno mediante helpers semánticos contextuales en `AppColors`:
  - `warningOf(context)`: **Amber 400 (`#FBBF24`)** en modo oscuro (evita la vibración cromática sobre fondos azul marino/slate) y **Amber 700 (`#B45309`)** en modo claro (garantiza ratio de contraste superior a **5.5:1** para visualización óptima bajo luz solar).
  - `successOf(context)`: Emerald 400 / Emerald 600.
  - `dangerOf(context)`: Rose 400 / Rose 600.
  - `surfaceOf(context)` y `backgroundOf(context)`: Responden en tiempo real al cambio de tema (*Dark/Light Mode Switcher* con rotación animada en AppBar).

### 2.3. Ergonomía Táctil, Anti-Colisión y Prevención de Desbordamientos
- **Padding Anti-Colisión (110dp):** Todos los `ListView.builder` principales cuentan con `padding: EdgeInsets.fromLTRB(16, 16, 16, 110)` para evitar que los botones de la última tarjeta queden ocultos por el botón flotante (*Extended FAB* o *SpeedDial*).
- **Touch Targets ≥ 44dp:** Los botones de acción en tarjetas (`Clave`, `Editar`, `Eliminar`) utilizan `IconButton` con `minimumSize: Size(44, 44)` y padding de 10dp.
- **Filtros Ergonómicos:** Carrusel horizontal táctil con `BouncingScrollPhysics` en lugar de filas de botones estáticas.
- **Prevención de Desbordamiento en Desplegables (*No-Overflow*):** Todos los `DropdownButtonFormField` y `DropdownMenuItem` en modales (`AddMesaModal`, `UserFormModal`, `PersoneroFormModal`) cuentan con `isExpanded: true` y `Text(..., overflow: TextOverflow.ellipsis)` para evitar excepciones de `RenderFlex overflow`.

---

## 3. Persistencia y Filosofía Offline-First

- **Modo Normal = Offline:** Toda acción (creación de acta, fotografía, asignación) se persiste primero localmente en SQLite vía Drift antes de encolar una operación de sincronización.
- **Idempotencia:** Cada mutación genera un UUID `client_operation_id` en el dispositivo móvil.
- **Cálculo de Hash SHA-256 en el Dispositivo:** Antes de almacenar localmente o subir evidencias a Cloudflare R2, se calcula el hash criptográfico del archivo.
- **Resiliencia de Sincronización:**
  - `SyncEngine` comprueba `apiClient.hasAuthToken` antes de iniciar sincronizaciones en segundo plano.
  - Manejo transparente de respuestas `401` y `403` durante ciclos de pull para no interrumpir la experiencia offline si la sesión expira.

---

## 4. Estrategia de Búsqueda y Paginación Híbrida (`AdminActasScreen` & Modales)

Para optimizar la experiencia de usuario y el consumo de red en catálogos extensos (miles de mesas y distritos):

- **Filtro Local Instantáneo:** Cuando no hay búsqueda remota activa o antes del umbral de caracteres (`longitud < 2`), la UI filtra en tiempo real sobre la base de datos SQLite local (`Drift`).
- **Debounce Controlado (350 ms):** Al ingresar 2 o más caracteres, se activa un temporizador *debounce* (`Timer`) de 350 ms. Si el usuario sigue tecleando, la petición anterior se cancela inmediatamente, evitando condiciones de carrera (*race conditions*) y múltiples llamadas redundantes a la API.
- **Indicador de Búsqueda en Vivo:** Durante la ejecución de la consulta remota, el icono de la barra de búsqueda cambia a un `CircularProgressIndicator` sutil sin congelar ni hacer saltos bruscos en la interfaz.
- **Paginación en Memoria (*Infinite Scroll*):** La vista remota (`_remoteMesas`) acumula los resultados paginados (`per_page: 10/15`) y carga la siguiente página de manera transparente al alcanzar el final del scroll.
- **Reset Limpio:** Al vaciar la caja de búsqueda (`query.isEmpty`), se restablece el estado a la vista local reactiva de Drift de inmediato.
- **Asignación Multi-Mesa a Personeros:** Soporte para asignar múltiples mesas electorales a un personero mediante modal interactivo con búsqueda remota paginada (`MesaSearchSelectorModal`).


