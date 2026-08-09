---
name: software-engineering-best-practices
description: Experto y buenas prácticas en ingeniería de software, arquitectura limpia, trazabilidad, resiliencia offline y patrones de diseño.
---

# Experto y Buenas Prácticas en Ingeniería de Software

## Principios Fundamentales
1. **Offline-First & Eventual Consistency:**
   - La conectividad es volátil. El almacenamiento local (SQLite/Drift) debe actuar como la fuente primaria de verdad en el cliente móvil.
   - Las operaciones de red deben encapsularse en colas de sincronización asíncronas con claves de idempotencia (`client_operation_id`).
2. **Idempotencia y Trazabilidad (Auditability):**
   - Toda solicitud de modificación de estado (ingesta de actas, confirmaciones) debe incluir idempotency keys para tolerar reintentos de red sin duplicar transacciones.
   - Registrar audit logs detallados (quién, cuándo, dispositivo, payload, hash SHA-256 de imágenes).
3. **Separación de Responsabilidades & Dominio Limpio:**
   - Desacoplar catálogos (datos maestros como ubigeos, candidaturas, organizaciones) de transacciones (actas, votos, evidencias).
   - No amarrar esquemas de BD a formatos de entrada externos (ej. JSON del JEE con prefijos `strXxx`). Usar capas de Staging y ETL para mapear a modelos relacionales limpios.
4. **Human-In-The-Loop:**
   - Los modelos automatizados (OCR/IA) generan propuestas o sugerencias con grados de confianza; la confirmación definitiva la realiza siempre un operador humano (personero).
