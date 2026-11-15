#!/usr/bin/env bash
# ==============================================================================
# PROYECTO MIRAI - PNETLab Host (root)
# Script 00: Preparación integral para una instalación limpia (OVA) de PNETLab
# Propósito:
#   1. Actualizar listas de paquetes del sistema (apt-get update) y reparar dpkg
#   2. Instalar utilitarios esenciales (curl, wget, git, ca-certificates, jq)
#   3. Instalar descompresores e imágenes (unzip, zip, 7z/7zz, xz-utils, tar, qemu-utils)
#   4. Instalar herramientas de red y diagnóstico (net-tools, iproute2, ping, tcpdump, bridge-utils)
#   5. Instalar/reparar ishare2 completo (/usr/sbin/ishare2 + /opt/ishare2/cli/lib/*.sh)
# Uso: sudo bash scripts/pnetlab-host/00_prepare_pnetlab_host.sh
# ==============================================================================
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

echo "=================================================================="
echo "[0/4] Preparando instalación limpia del servidor PNETLab (Host)..."
echo "=================================================================="

# 1. Reparar posibles bloqueos de dpkg y actualizar índices APT
echo "[1/5] Actualizando repositorios del sistema (apt-get update)..."
dpkg --configure -a 2>/dev/null || true
if command -v add-apt-repository >/dev/null 2>&1; then
    add-apt-repository -y universe 2>/dev/null || true
    add-apt-repository -y multiverse 2>/dev/null || true
fi
apt-get update -y || true

# 2. Instalar paquetes de descarga, transferencia, certificados y control de versiones
echo "[2/5] Instalando utilitarios de transferencia y repositorios (curl, wget, git, jq)..."
apt-get install -y \
    curl \
    wget \
    git \
    ca-certificates \
    apt-transport-https \
    software-properties-common \
    gnupg \
    lsb-release \
    jq \
    nano || true

# 3. Instalar paquetes de descompresión y soporte de discos virtuales QEMU
echo "[3/5] Instalando paquetes de descompresión y QEMU (unzip, zip, p7zip-full, xz-utils, qemu-utils)..."
apt-get install -y \
    unzip \
    zip \
    p7zip-full \
    p7zip \
    xz-utils \
    tar \
    gzip \
    bzip2 \
    qemu-utils || true
hash -r || true

# Fallback garantizado para 7z si el repositorio de la OVA de PNETLab no instaló /usr/bin/7z
if ! command -v 7z >/dev/null 2>&1; then
    if command -v 7za >/dev/null 2>&1; then
        ln -sf "$(command -v 7za)" /usr/bin/7z
        hash -r || true
    else
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
fi

# 4. Instalar utilitarios de red y diagnóstico usados en PNETLab
echo "[4/5] Instalando utilitarios de red y diagnóstico (net-tools, iproute2, ping, tcpdump, bridge-utils)..."
apt-get install -y \
    net-tools \
    iproute2 \
    iputils-ping \
    dnsutils \
    tcpdump \
    bridge-utils \
    htop \
    tmux || true

# 5. Verificar/instalar ishare2 completo (binario + módulos en /opt/ishare2/cli/lib/)
echo "[5/5] Verificando instalación completa de ishare2 y sus librerías..."
if ! command -v ishare2 >/dev/null 2>&1 || [ ! -f /opt/ishare2/cli/lib/logger.sh ]; then
    echo "[*] Instalando/reparando ishare2 desde el repositorio oficial..."
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

echo "------------------------------------------------------------------"
echo "RESUMEN DE VERIFICACIÓN DE UTILITARIOS EN PNETLAB HOST:"
for cmd in git curl wget unzip 7z xz tar qemu-img ishare2 tcpdump ip ifconfig; do
    if command -v "$cmd" >/dev/null 2>&1; then
        echo "  [OK] $cmd -> $(command -v "$cmd")"
    else
        echo "  [!]  $cmd -> NO ENCONTRADO"
    fi
done
echo "=================================================================="
echo "[OK] Servidor PNETLab actualizado y con todos los utilitarios listos."
echo "=================================================================="
