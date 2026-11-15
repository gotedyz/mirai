#!/usr/bin/env bash
# ==============================================================================
# PROYECTO MIRAI - PNETLab Host (root)
# Orquestador: Verifica/instala ishare2 y descarga todas las imágenes del lab
# Uso: sudo bash scripts/pnetlab-host/install_all_images.sh
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=================================================================="
echo "[0/3] Verificando disponibilidad de ishare2 en PNETLab..."
echo "=================================================================="
if ! command -v ishare2 >/dev/null 2>&1; then
    echo "[*] ishare2 no detectado. Instalando ishare2 automáticamente..."
    wget -q --show-progress -O /usr/sbin/ishare2 https://raw.githubusercontent.com/ishare2-org/ishare2-cli/main/ishare2
    chmod +x /usr/sbin/ishare2
    echo "[OK] ishare2 instalado en /usr/sbin/ishare2."
else
    echo "[OK] ishare2 ya se encuentra instalado."
fi

bash "$SCRIPT_DIR/01_install_mikrotik.sh"
bash "$SCRIPT_DIR/02_install_viosl2.sh"
bash "$SCRIPT_DIR/03_install_kali.sh"

echo "=================================================================="
echo "[OK] TODAS LAS IMÁGENES DEL LABORATORIO MIRAI ESTÁN LISTAS."
echo "=================================================================="
