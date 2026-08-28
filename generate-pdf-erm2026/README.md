# 📄 Generador de Actas Electorales ERM 2026 (ONPE)

Módulo en Python para la **generación vectorial programática de actas electorales** oficiales para las Elecciones Regionales y Municipales 2026 (Perú), con renderizado pixel-perfect y simulación de escrutinio con cuadre matemático estricto según la normativa de la ONPE y el JNE.

---

## 🎯 Formatos Generados

1. **Acta Regional Gobernador y Vicegobernador (Formato `1b`):**
   - Encabezado con logo institucional ONPE (plantilla), título de nivel electoral y casilla de verificación `ACTA ELECTORAL ☐`.
   - Insignia negra superior derecha `1b`.
   - Cajas de número de mesa, total de electores hábiles y ubigeo departamental, provincial y distrital.
   - Tabla de escrutinio con columna única de votación para Gobernador y Vicegobernador Regional.
   - Bloque independiente de totales: Votos en Blanco, Nulos, Impugnados, Total Votos Emitidos y Total Ciudadanos que Votaron.
   - Sección de observaciones `( X ) NO HAY OBSERVACIONES` y líneas continuas vectoriales para firmas reglamentarias (Presidente, Secretario, Tercer Miembro y Personero).

2. **Acta Municipal Provincial y Distrital (Formato `4b`):**
   - Insignia negra superior derecha `4b`.
   - Tabla de doble columna: **Total Votos Municipal Provincial** y **Total Votos Municipal Distrital**.
   - Auto-escalado de fuente y espaciado para soportar circunscripciones de alta densidad electoral (ej. Lima Metropolitana con más de 25 organizaciones políticas) en **1 sola página A4**.

3. **Actas Completas ERM 2026 (PDF Combinado de 2 Páginas):**
   - Página 1: Formato Municipal `4b`.
   - Página 2: Formato Regional `1b`.

---

## 🗄️ Fuente de Datos y Conexión PostgreSQL

El script se conecta dinámicamente a la base de datos PostgreSQL (`conteoya_bd`) leyendo las credenciales de `api/.env`:
- `polling_stations`: Código de mesa, electores hábiles, estado y nombres de ubigeo.
- `departments`, `provinces`, `districts`: Resolución de códigos de ubigeo.
- `electoral_lists`, `political_organizations`, `electoral_levels`: Filtro estricto de listas con estado `ADMITIDO` o `INSCRITO`.

---

## 📐 Reglas de Cuadre Matemático ONPE

El motor de simulación garantiza en todas las generaciones:
$$\sum \text{Votos de Listas} + \text{Votos en Blanco} + \text{Votos Nulos} + \text{Votos Impugnados} = \text{Total Votos Emitidos} = \text{Total Ciudadanos que Votaron} \le \text{Electores Hábiles}$$

---

## 🚀 Instalación y Uso

### Opción 1: Mediante Script Bash (Recomendado)
```bash
# Desde la raíz del proyecto
./scripts/generate_pdf_erm2026.sh 030390 040104 021038

# Especificando carpeta de salida
./scripts/generate_pdf_erm2026.sh 030390 -o generate-pdf-erm2026/output

# Modo interactivo
./scripts/generate_pdf_erm2026.sh
```

### Opción 2: Ejecución Directa con Python
```bash
# 1. Crear e instalar dependencias
cd generate-pdf-erm2026/
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# 2. Ejecutar generador
python generate.py 030390 040104 021038 -o output/
```

---

## 📂 Archivos Generados en `output/`

Para cada mesa procesada (`{MESA}`), se generan 3 archivos:
* `Acta_Regional_1b_Mesa_{MESA}.pdf`
* `Acta_Municipal_4b_Mesa_{MESA}.pdf`
* `Actas_Completas_ERM2026_Mesa_{MESA}.pdf`
