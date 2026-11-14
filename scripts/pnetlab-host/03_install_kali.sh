#!/usr/bin/env bash
# ==============================================================================
# PROYECTO MIRAI - PNETLab Host (root)
# Script 03: Descargar y preparar Kali Linux oficial (linux-kali-2026.2)
# Uso: sudo bash scripts/pnetlab-host/03_install_kali.sh
# ==============================================================================
set -euo pipefail

echo "=================================================================="
echo "[+] Instalando Kali Linux (linux-kali-2026.2) en PNETLab..."
echo "=================================================================="

if ! command -v 7z >/dev/null 2>&1; then
    echo "[*] Instalando dependencia p7zip-full..."
    apt-get update && apt-get install -y p7zip-full
fi

TARGET_DIR="/opt/unetlab/addons/qemu/linux-kali-2026.2"
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

echo "[*] Descargando kali-linux-2026.2-qemu-amd64.7z..."
wget -c --show-progress https://kali.download/base-images/kali-2026.2/kali-linux-2026.2-qemu-amd64.7z

echo "[*] Descomprimiendo archivo .7z..."
7z x -y kali-linux-2026.2-qemu-amd64.7z

echo "[*] Renombrando imagen .qcow2 a virtioa.qcow2..."
mv *.qcow2 virtioa.qcow2
rm -f kali-linux-2026.2-qemu-amd64.7z

echo "[*] Reparando permisos de PNETLab..."
/opt/unetlab/wrappers/unl_wrapper -a fixpermissions

echo "[OK] Imagen linux-kali-2026.2 lista en: $TARGET_DIR"
echo "     Credenciales por defecto: usuario 'kali' / password 'kali'"
