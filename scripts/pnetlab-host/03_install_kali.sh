#!/usr/bin/env bash
# ==============================================================================
# PROYECTO MIRAI - PNETLab Host (root)
# Script 03: Descargar y preparar Kali Linux oficial (linux-kali-2026.2)
# Valida si virtioa.qcow2 o el archivo .7z ya existen para NO volver a descargar
# Uso: sudo bash scripts/pnetlab-host/03_install_kali.sh
# ==============================================================================
set -euo pipefail

echo "=================================================================="
echo "[3/3] Verificando imagen Kali Linux (linux-kali-2026.2) en PNETLab..."
echo "=================================================================="

TARGET_DIR="/opt/unetlab/addons/qemu/linux-kali-2026.2"
ARCHIVE_NAME="kali-linux-2026.2-qemu-amd64.7z"
ARCHIVE_URL="https://kali.download/base-images/kali-2026.2/$ARCHIVE_NAME"

mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

# 1. Validar si la imagen final virtioa.qcow2 ya está instalada y lista
if [ -s "$TARGET_DIR/virtioa.qcow2" ]; then
    echo "[OK] La imagen Kali Linux (virtioa.qcow2) ya está instalada en $TARGET_DIR."
    echo "     Omitiendo descarga y descompresión."
    exit 0
fi

# 2. Validar si ya hay un archivo .qcow2 descomprimido pendiente de renombrar
EXISTING_QCOW2="$(find "$TARGET_DIR" -maxdepth 1 -type f -name "*.qcow2" ! -name "virtioa.qcow2" | head -n 1 || true)"
if [ -n "$EXISTING_QCOW2" ] && [ -s "$EXISTING_QCOW2" ]; then
    echo "[OK] Imagen descomprimida detectada ($EXISTING_QCOW2). Renombrando a virtioa.qcow2..."
    mv -f "$EXISTING_QCOW2" "$TARGET_DIR/virtioa.qcow2"
    rm -f "$TARGET_DIR/$ARCHIVE_NAME"
    /opt/unetlab/wrappers/unl_wrapper -a fixpermissions
    echo "[OK] Imagen linux-kali-2026.2 lista en: $TARGET_DIR"
    exit 0
fi

# Función para asegurar que 7z esté instalado antes de descomprimir
ensure_7z() {
    if command -v 7z >/dev/null 2>&1; then
        echo "[OK] Descompresor 7z detectado: $(command -v 7z)"
        return 0
    fi

    echo "[*] 7z no encontrado. Intentando instalar p7zip-full vía apt-get..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y || true
    apt-get install -y p7zip-full p7zip unzip xz-utils || true
    hash -r || true

    if command -v 7z >/dev/null 2>&1; then
        echo "[OK] p7zip-full instalado correctamente vía apt."
        return 0
    fi

    if command -v 7za >/dev/null 2>&1; then
        ln -sf "$(command -v 7za)" /usr/bin/7z
        hash -r || true
        echo "[OK] Enlace /usr/bin/7z creado hacia 7za."
        return 0
    fi

    echo "[*] Instalando binario estático oficial 7-Zip (7zz Linux x64)..."
    mkdir -p /tmp/7zip-static
    if wget -q --show-progress -O /tmp/7zip-static/7z.tar.xz "https://github.com/ip7z/7zip/releases/download/24.09/7z2409-linux-x64.tar.xz" || \
       wget -q --show-progress -O /tmp/7zip-static/7z.tar.xz "https://7-zip.org/a/7z2409-linux-x64.tar.xz"; then
        tar -xf /tmp/7zip-static/7z.tar.xz -C /tmp/7zip-static
        cp -f /tmp/7zip-static/7zz /usr/bin/7z
        cp -f /tmp/7zip-static/7zz /usr/local/bin/7z
        chmod +x /usr/bin/7z /usr/local/bin/7z
        rm -rf /tmp/7zip-static
        hash -r || true
        echo "[OK] Binario estático 7-Zip instalado en /usr/bin/7z."
        return 0
    fi

    echo "[!] Error crítico: No se pudo instalar 7z."
    exit 1
}

ensure_7z

# 3. Validar si el archivo .7z ya fue descargado previamente
if [ -s "$TARGET_DIR/$ARCHIVE_NAME" ]; then
    FILE_SIZE="$(du -h "$TARGET_DIR/$ARCHIVE_NAME" | cut -f1)"
    echo "[OK] El archivo $ARCHIVE_NAME ($FILE_SIZE) ya se encuentra descargado en $TARGET_DIR."
    echo "[*] Descomprimiendo archivo existente sin volver a descargar..."
    if ! (/usr/bin/7z x -y "$ARCHIVE_NAME" || 7z x -y "$ARCHIVE_NAME"); then
        echo "[!] El archivo .7z existente estaba incompleto. Reanudando descarga con wget -c..."
        wget -c --show-progress "$ARCHIVE_URL"
        /usr/bin/7z x -y "$ARCHIVE_NAME" || 7z x -y "$ARCHIVE_NAME"
    fi
else
    echo "[*] El archivo $ARCHIVE_NAME no existe localmente. Iniciando descarga..."
    wget -c --show-progress "$ARCHIVE_URL"
    echo "[*] Descomprimiendo archivo .7z con 7z..."
    /usr/bin/7z x -y "$ARCHIVE_NAME" || 7z x -y "$ARCHIVE_NAME"
fi

echo "[*] Renombrando imagen .qcow2 a virtioa.qcow2..."
for f in *.qcow2; do
    if [ "$f" != "virtioa.qcow2" ]; then
        mv -f "$f" virtioa.qcow2
        break
    fi
done
rm -f "$ARCHIVE_NAME"

echo "[*] Reparando permisos de PNETLab..."
/opt/unetlab/wrappers/unl_wrapper -a fixpermissions

echo "[OK] Imagen linux-kali-2026.2 lista en: $TARGET_DIR"
echo "     Credenciales por defecto: usuario 'kali' / password 'kali'"
