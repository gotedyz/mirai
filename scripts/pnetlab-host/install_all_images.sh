#!/usr/bin/env bash
# ==============================================================================
# PROYECTO MIRAI - PNETLab Host (root)
# Orquestador: Verifica herramientas y valida cada imagen antes de descargarla
# Si una imagen o su instalador comprimido ya fue descargado, NO lo vuelve a descargar
# Uso: sudo bash scripts/pnetlab-host/install_all_images.sh
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=================================================================="
echo "[0/3] Verificando herramientas de descompresión (unzip, 7z) e ishare2..."
echo "=================================================================="

# 1. Asegurar unzip y 7z (vía apt o binario estático 7zz si los repos de PNETLab fallan)
if ! command -v unzip >/dev/null 2>&1 || ! command -v 7z >/dev/null 2>&1; then
    echo "[*] Instalando utilidades de descompresión (unzip / p7zip-full)..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y || true
    apt-get install -y unzip p7zip-full p7zip xz-utils || true
    hash -r || true
fi

if ! command -v 7z >/dev/null 2>&1; then
    echo "[*] Instalando binario estático oficial 7-Zip (7zz Linux x64) en /usr/bin/7z..."
    mkdir -p /tmp/7zip-static
    if wget -q --show-progress -O /tmp/7zip-static/7z.tar.xz "https://github.com/ip7z/7zip/releases/download/24.09/7z2409-linux-x64.tar.xz" || \
       wget -q --show-progress -O /tmp/7zip-static/7z.tar.xz "https://7-zip.org/a/7z2409-linux-x64.tar.xz"; then
        tar -xf /tmp/7zip-static/7z.tar.xz -C /tmp/7zip-static
        cp -f /tmp/7zip-static/7zz /usr/bin/7z
        cp -f /tmp/7zip-static/7zz /usr/local/bin/7z
        chmod +x /usr/bin/7z /usr/local/bin/7z
        rm -rf /tmp/7zip-static
        hash -r || true
    fi
fi
echo "[OK] Herramientas unzip y 7z listas."

# 2. Asegurar ishare2 y todos sus módulos en /opt/ishare2/cli/lib/
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

# 3. Ejecutar cada instalador (cada script valida si la imagen o el archivo comprimido ya existe)
bash "$SCRIPT_DIR/01_install_mikrotik.sh"
bash "$SCRIPT_DIR/02_install_viosl2.sh"
bash "$SCRIPT_DIR/03_install_kali.sh"

echo "=================================================================="
echo "[OK] TODAS LAS IMÁGENES DEL LABORATORIO MIRAI ESTÁN LISTAS."
echo "=================================================================="
