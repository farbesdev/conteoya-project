# 🛡️ Rule: Pre-Commit & Pre-Push Automatic Verification Protocol

> **Scope:** Este archivo define las reglas obligatorias de verificación automática que el agente DEBE ejecutar SIEMPRE que el usuario solicite realizar un **commit**, **push**, o **modificación/desarrollo de funcionalidades**.

---

## ⚡ Protocolo Obligatorio Pre-Commit / Pre-Push

Antes de ejecutar cualquier comando `git commit` o `git push`, o al finalizar un conjunto de modificaciones en la solución, el agente DEBE ejecutar automáticamente y sin excepción el siguiente flujo de validación de calidad:

### 1. 🎨 Verificación UI/UX (Skill `ui-ux-pro-max`)
Si el cambio incluye modificaciones en la interfaz de usuario de `mobile/` o `web/`:
- [ ] Ejecutar auditoría de componentes UI/UX contra los lineamientos de `ui-ux-pro-max` (contraste WCAG AAA, safe areas, touch targets ≥ 44pt, micro-interacciones, consistencia de tokens de color y elevación).
- [ ] Garantizar que no existan emojis como íconos estructurales ni hardcodeo de estilos.

### 2. 📋 Code Review y Calidad Integrada (Skill `code-review-and-quality`)
Verificar todo el proyecto en sus módulos activos (`api/`, `mobile/`, `web/`):
- [ ] **Mobile (`mobile/`)**:
  - Ejecutar `flutter analyze` ➔ Confirmar **0 errores / 0 advertencias críticas**.
  - Ejecutar `flutter test` ➔ Confirmar que **el 100% de las pruebas pasen**.
- [ ] **Backend API (`api/`)**:
  - Ejecutar `php artisan test` ➔ Confirmar que **todos los tests unitarios y de integración pasen**.
  - Si se modificaron rutas o controladores: exportar spec de Scramble con `php artisan scramble:export` y verificar `docs/api_reference.md`.
- [ ] **Frontend Web (`web/` cuando aplique)**:
  - Verificar sintaxis, lints y compilación limpia del subproyecto.

### 3. 📝 Convenciones Semánticas Git (Skill `git-conventional-commits`)
- [ ] Elaborar un mensaje de commit estructurado en español siguiendo el estándar:
  `<emoji> <tipo>(<scope>): <descripción en español>`

---

## ⛔ Criterio de Bloqueo
Si cualquiera de los tests o analizadores en `api/` o `mobile/` arroja un fallo, el agente **NO DEBE REALIZAR EL COMMIT NI EL PUSH** hasta diagnosticar, justificar y corregir la falla de raíz.
