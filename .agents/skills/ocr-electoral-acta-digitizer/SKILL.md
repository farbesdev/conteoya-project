---
name: ocr-electoral-acta-digitizer
description: Experto en visión computacional, preprocesamiento de imagen, segmentación de cuadrículas y OCR para digitalización y extracción de datos en actas electorales (ONPE ERM 2026).
---

# 👁️ OCR Electoral Acta Digitizer — Skill de Especialista

Este skill proporciona las técnicas y algoritmos para la **digitalización y lectura inteligente de actas electorales** (ONPE ERM 2026), desde la captura de imagen hasta la extracción validada de votos.

---

## 🎯 Pipeline de Procesamiento de Actas

1. **Preprocesamiento y Normalización de Imagen:**
   - **Deskew / Alineación:** Detección de orientación mediante transformada de Hough o ángulos de contorno de bordes de la página.
   - **Corrección de Perspectiva:** Detección de las 4 esquinas del acta y transformación afín/homografía a coordenadas A4 estándar (2480x3508 px a 300 DPI).
   - **Binarización y Limpieza:** Umbralización adaptativa (Sauvola / Otsu) y reducción de ruido para aislar texto y dígitos de sombras o pliegues.

2. **Detección y Clasificación del Tipo de Acta:**
   - **Localización del Badge Superior Derecho:** Reconocimiento de la insignia negra con texto blanco (`1b` para Regional, `4b` para Municipal).
   - **Extracción de Ubigeo y Mesa:** Segmentación de los casilleros de cabecera para extraer el número de mesa (6 dígitos) y electores hábiles.

3. **Segmentación de Cuadrículas y Celdas de Votación:**
   - Detección de líneas horizontales y verticales de la tabla de escrutinio para obtener las coordenadas exactas $(x, y, w, h)$ de cada celda de votación.
   - Alineación de filas con las organizaciones políticas oficiales registradas en la base de datos para esa mesa.

4. **Extracción y Reconocimiento de Votos (OCR/HTR):**
   - Reconocimiento óptico de caracteres impresos y manuscritos (HTR) en celdas numéricas.
   - Asignación de nivel de confianza (`confidence` 0.00 - 1.00) por cada casilla leída.

5. **Auditoría Matemática y Human-in-the-Loop (Regla ConteoYA):**
   - Verificación de consistencia aritmética entre votos de listas y filas de totales.
   - La IA **nunca confirma un acta de forma autónoma**: los datos leídos se presentan al personero o digitador como propuesta para su validación o ajuste manual.
