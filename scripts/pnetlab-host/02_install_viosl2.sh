#!/usr/bin/env bash
# ==============================================================================
# PROYECTO MIRAI - PNETLab Host (root)
# Script 02: Instalar/reparar ishare2 completo y descargar Switch Cisco vIOS-L2 (ID 368)
# Uso: sudo bash scripts/pnetlab-host/02_install_viosl2.sh
# ==============================================================================
set -euo pipefail

echo "=================================================================="
echo "[+] Preparando descarga de Cisco vIOS-L2 (ID 368) mediante ishare2..."
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
    echo "[OK] ishare2 instalado correctamente con todos sus módulos."
fi

echo "[*] Ejecutando: ishare2 pull qemu 368..."
ishare2 pull qemu 368
/opt/unetlab/wrappers/unl_wrapper -a fixpermissions

echo "[OK] Switch Cisco vIOS-L2 (ID 368) instalado y permisos corregidos."
