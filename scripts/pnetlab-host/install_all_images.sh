#!/usr/bin/env bash
# ==============================================================================
# PROYECTO MIRAI - PNETLab Host (root)
# Orquestador: Verifica/instala ishare2 completo y descarga las imágenes del lab
# Uso: sudo bash scripts/pnetlab-host/install_all_images.sh
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=================================================================="
echo "[0/3] Verificando disponibilidad de ishare2 y sus módulos en PNETLab..."
echo "=================================================================="
if ! command -v ishare2 >/dev/null 2>&1 || [ ! -f /opt/ishare2/cli/lib/logger.sh ]; then
    echo "[*] Instalando/reparando ishare2 completo (binario + /opt/ishare2/cli/lib/)..."
    rm -rf /tmp/ishare2-cli
    git clone -q https://github.com/ishare2-org/ishare2-cli.git /tmp/ishare2-cli
    mkdir -p /opt/ishare2/cli/lib
    cp -rf /tmp/ishare2-cli/* /opt/ishare2/cli/
    cp -f /tmp/ishare2-cli/ishare2 /usr/sbin/ishare2
    chmod +x /usr/sbin/ishare2 /opt/ishare2/cli/ishare2 /opt/ishare2/cli/lib/*.sh
    rm -rf /tmp/ishare2-cli
    echo "[OK] ishare2 y librerías instaladas en /usr/sbin/ishare2 y /opt/ishare2/cli/lib/."
else
    echo "[OK] ishare2 y sus módulos ya se encuentran instalados."
fi

bash "$SCRIPT_DIR/01_install_mikrotik.sh"
bash "$SCRIPT_DIR/02_install_viosl2.sh"
bash "$SCRIPT_DIR/03_install_kali.sh"

echo "=================================================================="
echo "[OK] TODAS LAS IMÁGENES DEL LABORATORIO MIRAI ESTÁN LISTAS."
echo "=================================================================="
