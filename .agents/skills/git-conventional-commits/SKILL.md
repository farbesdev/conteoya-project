---
name: git-conventional-commits
description: >
  Convenciones de commits semánticos y estrategia de ramas Git Flow para el monorepo
  farbesdev-saas. Usar SIEMPRE antes de hacer cualquier commit o crear una rama.
  Activa en "commit", "branch", "git", "release", "hotfix", "feature", "conventional commits".
---

# Git Conventional Commits y Git Flow — Guía del Proyecto

## 1. Formato de Commit Obligatorio

```
<emoji> <tipo>(<scope>): <descripción en español>

[cuerpo opcional]

[footer opcional: BREAKING CHANGE, Closes #issue]
```

## 2. Tipos de Commit y Emojis

| Emoji | Tipo | Cuándo usar |
|-------|------|-------------|
| ✨ | `feat` | Nueva funcionalidad |
| 🐛 | `fix` | Corrección de bug |
| ♻️ | `refactor` | Refactorización sin cambio de comportamiento |
| 📝 | `docs` | Solo documentación |
| 🎨 | `style` | Formato/estilo (sin cambio de lógica) |
| ✅ | `test` | Agregar o corregir pruebas |
| 🔧 | `chore` | Herramientas, configuración, dependencias |
| 🚀 | `perf` | Mejora de rendimiento |
| 🔒 | `security` | Corrección de vulnerabilidad |
| 🏗️ | `build` | Sistema de build, Turborepo, Bun |
| 🔁 | `ci` | Cambios en CI/CD pipelines |
| 🗑️ | `revert` | Revertir commit anterior |

## 3. Scopes del Monorepo

| Scope | Corresponde a |
|-------|--------------|
| `api` | `apps/api/` — Backend Fastify |
| `web` | `apps/web/` — Frontend Nuxt 4 |
| `api-contract` | `packages/api-contract/` |
| `database` | `packages/database/` — Drizzle schemas/migraciones |
| `ui-kit` | `packages/ui-kit/` |
| `config` | `packages/config/` |
| `turbo` | Configuración Turborepo raíz |
| `specs` | Documentación ADR/specs |

## 4. Ejemplos de Commits Correctos

```bash
# Nueva feature en el backend
git commit -m "✨ feat(api): implementar endpoint POST /api/v1/auth/login con TypeBox schema"

# Corrección de bug en frontend
git commit -m "🐛 fix(web): corregir validación del formulario de login en pantallas móviles"

# Nueva migración de base de datos
git commit -m "🏗️ build(database): agregar migración para tabla products con RLS habilitado"

# Cambio en spec ADR
git commit -m "📝 docs(specs): actualizar ADR-003 con patrón de repositorio multitenant"

# Actualización de dependencias
git commit -m "🔧 chore(turbo): actualizar versión de Turborepo a 2.1.0"

# Breaking change
git commit -m "✨ feat(api-contract): rediseñar LoginInputSchema eliminando campo legacyToken

BREAKING CHANGE: El campo 'legacyToken' es removido del contrato. Actualizar todos los consumidores."
```

## 5. Estrategia de Ramas Git Flow

```
main              ← Producción estable
  └── develop     ← Integración continua
        ├── feature/<scope>/<descripcion-corta>
        ├── fix/<scope>/<descripcion-corta>
        ├── hotfix/<descripcion-corta>
        └── release/<version>
```

### Nomenclatura de Ramas

```bash
# Features
feature/api/auth-login-endpoint
feature/web/security-users-crud
feature/database/products-schema-migration

# Fixes
fix/api/tenant-resolver-null-pointer
fix/web/mobile-responsive-table

# Hotfixes (desde main)
hotfix/api/security-rls-bypass-critical

# Releases
release/1.0.0
release/1.1.0-beta
```

## 6. Reglas Críticas

- ❌ **NUNCA** hacer commit directo a `main` o `develop`.
- ❌ **NUNCA** omitir el scope cuando el cambio es en un paquete específico.
- ✅ **SIEMPRE** escribir la descripción en **español** (imperativo presente: "implementar", "corregir", "agregar").
- ✅ **SIEMPRE** referenciar el issue o ADR cuando aplique: `Refs: specs/adr-001`.
- ✅ Los commits de `feat` que agregan endpoints nuevos deben referenciar la spec: `Refs: specs/{modulo}.md`.
