#!/usr/bin/env bash
# ==============================================================================
# PROYECTO MIRAI - PNETLab Host (root)
# Orquestador Maestro:
#   0. Actualiza el sistema e instala todos los utilitarios (curl, git, unzip, 7z, ishare2, etc.)
#   1. Verifica/instala MikroTik CHR 6.49.10 (sin volver a descargar si ya existe)
#   2. Verifica/instala Switch Cisco vIOS-L2 ID 368 (sin volver a descargar si ya existe)
#   3. Verifica/instala Kali Linux 2026.2 (sin volver a descargar si ya existe)
# Uso: sudo bash scripts/pnetlab-host/install_all_images.sh
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$SCRIPT_DIR/00_prepare_pnetlab_host.sh"
bash "$SCRIPT_DIR/01_install_mikrotik.sh"
bash "$SCRIPT_DIR/02_install_viosl2.sh"
bash "$SCRIPT_DIR/03_install_kali.sh"

echo "=================================================================="
echo "[OK] SERVIDOR PNETLAB PREPARADO Y TODAS LAS IMÁGENES LISTAS."
echo "=================================================================="
