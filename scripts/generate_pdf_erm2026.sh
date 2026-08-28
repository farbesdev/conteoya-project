#!/usr/bin/env bash
# ==============================================================================
# ConteoYA — Script de Ejecución: Generador de Actas Electorales ERM 2026 (ONPE)
# ==============================================================================

set -e

# Colores para salida de terminal
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m' # Sin color

# Directorio raíz del proyecto
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GEN_DIR="${PROJECT_ROOT}/generate-pdf-erm2026"
VENV_DIR="${GEN_DIR}/.venv"
PYTHON_BIN="${VENV_DIR}/bin/python"

echo -e "${BLUE}${BOLD}======================================================================"
echo -e "   CONTEOYA — GENERADOR DE ACTAS ELECTORALES ERM 2026 (ONPE)"
echo -e "======================================================================${NC}"

# 1. Verificar o crear entorno virtual
if [ ! -f "${PYTHON_BIN}" ]; then
    echo -e "${YELLOW}[INFO] Creando entorno virtual Python en ${VENV_DIR}...${NC}"
    python3 -m venv "${VENV_DIR}"
    echo -e "${YELLOW}[INFO] Instalando dependencias desde requirements.txt...${NC}"
    "${VENV_DIR}/bin/pip" install --upgrade pip
    "${VENV_DIR}/bin/pip" install -r "${GEN_DIR}/requirements.txt"
fi

# 2. Ejecutar el generador con los argumentos pasados
cd "${PROJECT_ROOT}"
"${PYTHON_BIN}" "${GEN_DIR}/generate.py" "$@"

