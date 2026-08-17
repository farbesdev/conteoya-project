# 03 — Guía: Instalación y Puesta en Marcha Local

> **Guía:** Tutorial de Inicio Rápido  
> **Tiempo estimado:** 5 a 10 minutos

---

## 1. Requisitos Previos

- **PHP:** 8.2 o superior con extensiones `pdo_pgsql`, `mbstring`, `openssl`, `redis`, `gd`.
- **Composer:** v2+.
- **PostgreSQL:** 16+ (o Docker).
- **Flutter SDK:** 3.44+ con Dart.

---

## 2. Puesta en Marcha del Backend API

1. **Navegar e instalar dependencias:**
   ```bash
   cd api
   composer install
   ```
2. **Configurar el archivo de entorno `.env`:**
   ```bash
   cp .env.example .env
   php artisan key:generate
   ```
   Ajustar las credenciales de PostgreSQL:
   ```ini
   DB_CONNECTION=pgsql
   DB_HOST=127.0.0.1
   DB_PORT=5432
   DB_DATABASE=conteoya_bd
   DB_USERNAME=postgres
   DB_PASSWORD=tu_password
   ```
3. **Ejecutar migraciones y datos maestros iniciales:**
   ```bash
   php artisan migrate:fresh --seed
   ```
4. **Ejecutar la suite de pruebas unitarias y de integración:**
   ```bash
   php artisan test
   ```
5. **Iniciar el servidor de desarrollo:**
   ```bash
   php artisan serve --port=8000
   ```

---

## 3. Puesta en Marcha de la App Móvil

1. **Navegar e instalar paquetes:**
   ```bash
   cd mobile
   flutter pub get
   ```
2. **Generar código de Drift SQLite:**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
3. **Ejecutar en emulador o dispositivo:**
   ```bash
   flutter run
   ```
