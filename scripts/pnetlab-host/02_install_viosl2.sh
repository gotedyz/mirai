#!/usr/bin/env bash
# ==============================================================================
# PROYECTO MIRAI - PNETLab Host (root)
# Script 02: Instalar ishare2 (si no existe) y descargar Switch Cisco vIOS-L2 (ID 368)
# Uso: sudo bash scripts/pnetlab-host/02_install_viosl2.sh
# ==============================================================================
set -euo pipefail

echo "=================================================================="
echo "[+] Preparando descarga de Cisco vIOS-L2 (ID 368) mediante ishare2..."
echo "=================================================================="

if ! command -v ishare2 >/dev/null 2>&1; then
    echo "[*] ishare2 no está instalado en este servidor PNETLab. Instalando..."
    wget -q --show-progress -O /usr/sbin/ishare2 https://raw.githubusercontent.com/ishare2-org/ishare2-cli/main/ishare2
    chmod +x /usr/sbin/ishare2
    echo "[OK] ishare2 instalado correctamente en /usr/sbin/ishare2."
fi

# Si es la primera ejecución de ishare2 y solicita crear configuración por defecto, aceptar con Enter
if [ ! -f /opt/ishare2/ishare2.conf ]; then
    echo "[*] Inicializando configuración por defecto de ishare2..."
    printf "\n\n\n\n\n" | ishare2 >/dev/null 2>&1 || true
fi

echo "[*] Ejecutando: ishare2 pull qemu 368..."
ishare2 pull qemu 368
/opt/unetlab/wrappers/unl_wrapper -a fixpermissions

echo "[OK] Switch Cisco vIOS-L2 (ID 368) instalado y permisos corregidos."
