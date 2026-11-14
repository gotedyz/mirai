#!/usr/bin/env bash
# ==============================================================================
# PROYECTO MIRAI - PNETLab Host (root)
# Script 01: Descargar e instalar MikroTik CHR 6.49.10 oficial
# Uso: sudo bash scripts/pnetlab-host/01_install_mikrotik.sh
# ==============================================================================
set -euo pipefail

echo "=================================================================="
echo "[+] Instalando imagen MikroTik CHR 6.49.10 en PNETLab..."
echo "=================================================================="

TARGET_DIR="/opt/unetlab/addons/qemu/mikrotik-6.49"
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"
rm -f *

echo "[*] Descargando chr-6.49.10.img.zip desde MikroTik oficial..."
wget -q --show-progress https://download.mikrotik.com/routeros/6.49.10/chr-6.49.10.img.zip

echo "[*] Descomprimiendo y renombrando disco a virtioa.qcow2..."
unzip -o chr-6.49.10.img.zip
mv chr-6.49.10.img virtioa.qcow2
rm -f chr-6.49.10.img.zip

echo "[*] Aplicando fixpermissions de PNETLab..."
/opt/unetlab/wrappers/unl_wrapper -a fixpermissions

echo "[OK] MikroTik CHR 6.49.10 instalado correctamente en: $TARGET_DIR"
