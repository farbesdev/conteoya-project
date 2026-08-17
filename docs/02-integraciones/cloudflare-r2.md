# 02 — Integración: Cloudflare R2 (Almacenamiento Seguro S3)

> **Integración:** Storage de Evidencias Electorales  
> **Proveedor:** Cloudflare R2 (S3-compatible, bucket privado)

---

## 1. Principio de Seguridad y Privacidad

- **Zero Public Access:** El bucket R2 nunca es público. No existen URLs estáticas ni accesibles sin firma.
- **Credenciales Aisladas:** La aplicación móvil jamás conoce las llaves de acceso de Cloudflare R2 (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`). Toda autorización proviene del backend API.

---

## 2. Flujo de URLs Presignadas

1. **Solicitud de URL de Subida (`POST /api/v1/acts/{id}/evidence/upload-url`):**
   - El cliente envía `file_mime`, `file_size_bytes` y `sha256_hash`.
   - El backend valida que el usuario sea el personero asignado a la mesa.
   - El backend genera una URL presignada `PUT` con **TTL de 15 minutos**.
2. **Transferencia Directa:**
   - La app móvil envía el binario directamente al endpoint de Cloudflare R2 mediante `HTTP PUT`.
3. **Confirmación de Evidencia (`POST /api/v1/acts/{id}/evidence/confirm`):**
   - El cliente confirma el `object_key`, tamaño y hash SHA-256 final.
   - El backend valida la existencia del objeto y registra el acta de evidencia (`ActEvidence`).
4. **Descarga de Evidencias (`GET /api/v1/acts/{id}/evidence/{evidence}/download`):**
   - Retorna una URL presignada `GET` con **TTL de 60 minutos** solo para usuarios autorizados.
