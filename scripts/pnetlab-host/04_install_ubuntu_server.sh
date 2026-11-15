#!/usr/bin/env bash
# ==============================================================================
# PROYECTO MIRAI - PNETLab Host (root)
# Script 04: Descargar e instalar Linux Ubuntu Server 20.04 (linux-ubuntu-server-20.04)
# Valida primero si la imagen ya fue descargada antes de volver a descargarla
# Uso: sudo bash scripts/pnetlab-host/04_install_ubuntu_server.sh
# ==============================================================================
set -euo pipefail

echo "=================================================================="
echo "[4/4] Verificando imagen Linux Ubuntu Server 20.04 en PNETLab..."
echo "=================================================================="

TARGET_DIR="/opt/unetlab/addons/qemu/linux-ubuntu-server-20.04"

# 1. Validar si la imagen ya existe y tiene su disco .qcow2
EXISTING_QCOW2="$(find "$TARGET_DIR" -maxdepth 1 -type f -name "*.qcow2" 2>/dev/null | head -n 1 || true)"
if [ -n "$EXISTING_QCOW2" ] && [ -s "$EXISTING_QCOW2" ]; then
    echo "[OK] La imagen linux-ubuntu-server-20.04 ya está instalada en: $TARGET_DIR"
    echo "     Disco detectado: $(basename "$EXISTING_QCOW2"). Omitiendo descarga."
    exit 0
fi

# 2. Asegurar que ishare2 y sus librerías estén instalados
if ! command -v ishare2 >/dev/null 2>&1 || [ ! -f /opt/ishare2/cli/lib/logger.sh ]; then
    echo "[*] Instalando/reparando ishare2 completo (binario + /opt/ishare2/cli/lib/)..."
    rm -rf /tmp/ishare2-cli
    git clone -q https://github.com/ishare2-org/ishare2-cli.git /tmp/ishare2-cli
    mkdir -p /opt/ishare2/cli/lib
    cp -rf /tmp/ishare2-cli/* /opt/ishare2/cli/
    cp -f /tmp/ishare2-cli/ishare2 /usr/sbin/ishare2
    chmod +x /usr/sbin/ishare2 /opt/ishare2/cli/ishare2 /opt/ishare2/cli/lib/*.sh
    rm -rf /tmp/ishare2-cli
    echo "[OK] ishare2 instalado correctamente."
fi

# 3. Buscar dinámicamente el ID de linux-ubuntu-server-20.04 en el catálogo de ishare2
echo "[*] Buscando ID de 'linux-ubuntu-server-20.04' en el catálogo de ishare2..."
CLEAN_SEARCH="$(ishare2 search ubuntu 2>/dev/null | sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' || true)"

UBUNTU_ID="$(echo "$CLEAN_SEARCH" | grep -i "linux-ubuntu-server-20.04" | sed -E 's/linux-ubuntu.*//I' | grep -oE '[0-9]+' | head -n 1 || true)"

if [ -z "$UBUNTU_ID" ]; then
    UBUNTU_ID="$(echo "$CLEAN_SEARCH" | grep -iE "ubuntu.*20\.04" | sed -E 's/(linux-)?ubuntu.*//I' | grep -oE '[0-9]+' | head -n 1 || true)"
fi

if [ -n "$UBUNTU_ID" ]; then
    echo "[*] Imagen encontrada en ishare2 con ID: $UBUNTU_ID. Descargando..."
    ishare2 pull qemu "$UBUNTU_ID" || true
fi

# 4. Verificar si se descargó con otro nombre similar (ej. linux-ubuntu-20.04*) y enlazar a linux-ubuntu-server-20.04
EXISTING_QCOW2="$(find "$TARGET_DIR" -maxdepth 1 -type f -name "*.qcow2" 2>/dev/null | head -n 1 || true)"
if [ -z "$EXISTING_QCOW2" ]; then
    ALT_UBUNTU_QCOW2="$(find /opt/unetlab/addons/qemu -maxdepth 2 -type f -path "/opt/unetlab/addons/qemu/*ubuntu*20.04*/*.qcow2" 2>/dev/null | head -n 1 || true)"
    if [ -n "$ALT_UBUNTU_QCOW2" ] && [ -s "$ALT_UBUNTU_QCOW2" ]; then
        mkdir -p "$TARGET_DIR"
        ln -f "$ALT_UBUNTU_QCOW2" "$TARGET_DIR/$(basename "$ALT_UBUNTU_QCOW2")"
    fi
fi

# 5. Fallback directo desde Ubuntu Cloud Images oficial si ishare2 no pudo descargarla
EXISTING_QCOW2="$(find "$TARGET_DIR" -maxdepth 1 -type f -name "*.qcow2" 2>/dev/null | head -n 1 || true)"
if [ -z "$EXISTING_QCOW2" ]; then
    echo "[*] Descargando imagen oficial Ubuntu Server 20.04 Cloud Image (virtioa.qcow2)..."
    mkdir -p "$TARGET_DIR"
    cd "$TARGET_DIR"
    wget -c --show-progress -O virtioa.qcow2 "https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img"
fi

echo "[*] Aplicando fixpermissions de PNETLab..."
/opt/unetlab/wrappers/unl_wrapper -a fixpermissions

echo "[OK] Imagen linux-ubuntu-server-20.04 lista en: $TARGET_DIR"
