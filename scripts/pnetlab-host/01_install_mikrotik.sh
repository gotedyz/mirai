#!/usr/bin/env bash
# ==============================================================================
# PROYECTO MIRAI - PNETLab Host (root)
# Script 01: Descargar e instalar MikroTik CHR 6.49.10 oficial
# Valida si la imagen o el archivo .zip ya fueron descargados antes de descargar
# Uso: sudo bash scripts/pnetlab-host/01_install_mikrotik.sh
# ==============================================================================
set -euo pipefail

echo "=================================================================="
echo "[1/3] Verificando imagen MikroTik CHR 6.49.10 en PNETLab..."
echo "=================================================================="

TARGET_DIR="/opt/unetlab/addons/qemu/mikrotik-6.49"
ARCHIVE_ZIP="chr-6.49.10.img.zip"
RAW_IMG="chr-6.49.10.img"

mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

# 1. Validar si la imagen final ya está instalada
if [ -s "$TARGET_DIR/virtioa.qcow2" ]; then
    echo "[OK] MikroTik CHR 6.49.10 (virtioa.qcow2) ya está instalado en $TARGET_DIR. Omitiendo descarga."
    exit 0
fi

# 2. Validar si el archivo .img ya fue descomprimido previamente
if [ -s "$TARGET_DIR/$RAW_IMG" ]; then
    echo "[OK] Archivo $RAW_IMG detectado localmente. Renombrando a virtioa.qcow2..."
    mv -f "$RAW_IMG" virtioa.qcow2
    rm -f "$ARCHIVE_ZIP"
    /opt/unetlab/wrappers/unl_wrapper -a fixpermissions
    echo "[OK] MikroTik CHR 6.49.10 listo en: $TARGET_DIR"
    exit 0
fi

# 3. Validar si el .zip ya fue descargado previamente
if [ -s "$TARGET_DIR/$ARCHIVE_ZIP" ]; then
    echo "[OK] El archivo $ARCHIVE_ZIP ya fue descargado previamente. Omitiendo descarga..."
else
    echo "[*] Descargando $ARCHIVE_ZIP desde MikroTik oficial..."
    wget -c -q --show-progress "https://download.mikrotik.com/routeros/6.49.10/$ARCHIVE_ZIP"
fi

echo "[*] Descomprimiendo y renombrando disco a virtioa.qcow2..."
unzip -o "$ARCHIVE_ZIP"
mv -f "$RAW_IMG" virtioa.qcow2
rm -f "$ARCHIVE_ZIP"

echo "[*] Aplicando fixpermissions de PNETLab..."
/opt/unetlab/wrappers/unl_wrapper -a fixpermissions

echo "[OK] MikroTik CHR 6.49.10 instalado correctamente en: $TARGET_DIR"
