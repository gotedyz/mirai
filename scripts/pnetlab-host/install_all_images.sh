#!/usr/bin/env bash
# ==============================================================================
# PROYECTO MIRAI - PNETLab Host (root)
# Orquestador: Instala todas las imágenes del laboratorio en un solo paso
# Uso: sudo bash scripts/pnetlab-host/install_all_images.sh
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$SCRIPT_DIR/01_install_mikrotik.sh"
bash "$SCRIPT_DIR/02_install_viosl2.sh"
bash "$SCRIPT_DIR/03_install_kali.sh"

echo "=================================================================="
echo "[OK] TODAS LAS IMÁGENES DEL LABORATORIO MIRAI ESTÁN LISTAS."
echo "=================================================================="
