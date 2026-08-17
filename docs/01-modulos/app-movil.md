# 01 — Módulo: Aplicación Móvil (Flutter 3.44)

> **Módulo:** App Móvil  
> **Tecnología:** Flutter 3.44+ · Dart · Riverpod · Drift (SQLite) v5

---

## 1. Arquitectura de la App Móvil

La aplicación móvil está estructurada bajo **Clean Architecture** modular por features:

```text
mobile/lib/
├── core/
│   ├── database/       # Drift SQLite v5 (tables.dart, app_database.dart)
│   ├── network/        # Cliente HTTP, interceptores de autenticación
│   ├── sync/           # SyncEngine, BackoffCalculator, Connectivity
│   ├── theme/          # Sistema de diseño, colores y tipografía
│   └── utils/          # HashUtils (cálculo SHA-256 local)
└── features/
    ├── acts/           # Registro de actas, formularios, validadores, UI
    ├── auth/           # Login, gestión de tokens Sanctum
    ├── mesas/          # Consulta y asignación de mesas de sufragio
    ├── ocr_ai/         # Captura de cámara, recorte y preview de reconocimiento
    ├── personeros/     # Gestión de personeros de mesa
    └── sync/           # Panel de estado de sincronización offline
```

---

## 2. Persistencia y Filosofía Offline-First

- **Modo Normal = Offline:** La aplicación no asume conectividad. Toda acción (creación de acta, toma de foto, modificación de votos) se escribe primero en la base de datos local SQLite mediante Drift.
- **Cálculo de Hash SHA-256 en el Dispositivo:** Antes de persistir o intentar sincronizar una fotografía de acta, se calcula su checksum criptográfico localmente.
- **Riverpod State Management:** Notifiers inmutables y reactivos para sincronizar la UI con la base de datos local.
