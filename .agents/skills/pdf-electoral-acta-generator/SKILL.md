---
name: pdf-electoral-acta-generator
description: Experto y mejores prácticas en la generación programática de actas electorales (ONPE ERM 2026) mediante código Python y ReportLab con diseño vectorial pixel-perfect y cuadre matemático estricto.
---

# 📄 PDF Electoral Acta Generator — Skill de Especialista

Este skill proporciona la guía técnica, arquitectura y patrones para la **generación vectorial programática de actas electorales** (ONPE - Elecciones Regionales y Municipales ERM 2026) en PDF de alta fidelidad.

---

## 🎯 Capacidades Principales

1. **Diseño Vectorial Pixel-Perfect:**
   - Reproducción idéntica de plantillas oficiales ONPE (**Formato 1b** Regional y **Formato 4b** Municipal).
   - Insignias superiores de tipo de acta (`1b`, `4b`), casilleros de estado (`ACTA ELECTORAL ☐`), logos institucionales y cajas de ubigeo.
   - Líneas de firma vectoriales continuas y casilleros de observaciones oficiales.

2. **Tipografía y Maquetación Adaptativa:**
   - Auto-escalado de fuente (`fontSize` y `leading`) y padding de filas según el número de organizaciones políticas (de 4 a más de 25 listas por cédula).
   - Garantía de **1 sola página exacta A4 por acta**, evitando desbordamientos o páginas huérfanas.

3. **Integración Directa con Bases de Datos (PostgreSQL):**
   - Extracción de datos de mesa (`polling_stations`), ubigeo (`departments`, `provinces`, `districts`) y listas oficiales admitidas/inscritas.
   - Respeto del número real de electores hábiles (`registered_voters`).

4. **Motor de Cuadre Matemático Electoral:**
   - Distribución ponderada y realista de votos válidos entre partidos inscritos.
   - Inclusión de votos en blanco, nulos e impugnados garantizando la igualdad estricta:
     $$\sum \text{Votos Listas} + \text{Blancos} + \text{Nulos} + \text{Impugnados} = \text{Total Votos Emitidos} = \text{Total Ciudadanos que Votaron} \le \text{Electores Hábiles}$$
