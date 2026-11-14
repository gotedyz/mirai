#!/usr/bin/env bash
# ==============================================================================
# PROYECTO MIRAI - PNETLab Host (root)
# Script 02: Descargar Switch Cisco vIOS-L2 (ID 368 - Soporta SPAN real)
# Uso: sudo bash scripts/pnetlab-host/02_install_viosl2.sh
# ==============================================================================
set -euo pipefail

echo "=================================================================="
echo "[+] Descargando Cisco vIOS-L2 (ID 368) mediante ishare2..."
echo "=================================================================="

if ! command -v ishare2 >/dev/null 2>&1; then
    echo "[!] Error: ishare2 no está instalado en este servidor PNETLab."
    exit 1
fi

ishare2 pull qemu 368
/opt/unetlab/wrappers/unl_wrapper -a fixpermissions

echo "[OK] Switch Cisco vIOS-L2 (ID 368) instalado y permisos corregidos."
