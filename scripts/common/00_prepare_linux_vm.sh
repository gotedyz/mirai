#!/usr/bin/env bash
# ==============================================================================
# PROYECTO MIRAI - Script Común para TODAS las MVs Linux del Laboratorio
# Nodos aplicables: Victima-Web, IoT-Cam-1, SOC-Sniffer (Kali Linux / Ubuntu / Debian)
# Propósito:
#   1. Asegurar conectividad IP por DHCP y resolución DNS en la fase "Net"
#   2. Reparar bloqueos de dpkg/apt y ejecutar apt-get update
#   3. Instalar utilitarios base en todas las MVs Linux:
#      - Transferencia y repositorios: curl, wget, git, ca-certificates, jq, nano
#      - Descompresión: unzip, zip, p7zip-full (7z + fallback estático 7zz), xz-utils, tar, gzip, bzip2
#      - Red y diagnóstico: iproute2, net-tools, iputils-ping, dnsutils, tcpdump, isc-dhcp-client, psmisc, procps
# Uso: sudo bash scripts/common/00_prepare_linux_vm.sh [interfaz=eth0] [hostname_opcional]
# ==============================================================================
set -euo pipefail

IFACE="${1:-eth0}"
TARGET_HOSTNAME="${2:-}"
export DEBIAN_FRONTEND=noninteractive

echo "------------------------------------------------------------------"
echo "[Base Linux VM] Preparando sistema, repositorios y utilitarios..."
echo "------------------------------------------------------------------"

# 1. Configurar hostname si fue proporcionado
if [ -n "$TARGET_HOSTNAME" ]; then
    echo "[*] Configurando hostname del sistema como '$TARGET_HOSTNAME'..."
    echo "$TARGET_HOSTNAME" > /etc/hostname
    hostname "$TARGET_HOSTNAME" 2>/dev/null || true
    hostnamectl set-hostname "$TARGET_HOSTNAME" 2>/dev/null || true
    if grep -q "^127\.0\.1\.1" /etc/hosts; then
        sed -i "s/^127\.0\.1\.1.*/127.0.1.1\t$TARGET_HOSTNAME/" /etc/hosts
    else
        echo -e "127.0.1.1\t$TARGET_HOSTNAME" >> /etc/hosts
    fi
fi

# 2. Asegurar IP por DHCP y DNS funcional en la interfaz conectada a "Net"
echo "[*] Verificando IP por DHCP en $IFACE y resolución DNS..."
ip link set "$IFACE" up 2>/dev/null || true
if ! ip -4 addr show "$IFACE" | grep -q "inet "; then
    dhclient "$IFACE" 2>/dev/null || true
fi
if ! grep -q "nameserver" /etc/resolv.conf 2>/dev/null; then
    echo -e "nameserver 8.8.8.8\nnameserver 1.1.1.1" > /etc/resolv.conf
fi
ip -4 addr show "$IFACE" | grep "inet " || true

# 3. Reparar posibles bloqueos de dpkg/apt y actualizar índices de paquetes
echo "[*] Reparando dpkg (si aplica) y ejecutando apt-get update..."
rm -f /var/lib/apt/lists/lock /var/cache/apt/archives/lock /var/lib/dpkg/lock* 2>/dev/null || true
dpkg --configure -a 2>/dev/null || true

# Si es Kali Linux y falta la llave actualizada del archivo, intentar actualizar kali-archive-keyring
apt-get update -y || true

# 4. Instalar paquetes utilitarios comunes (con --no-upgrade para no romper systemd/D-Bus en vivo)
echo "[*] Instalando utilitarios esenciales (curl, wget, git, descompresores y herramientas de red)..."
apt-get install -y --no-upgrade \
    curl \
    wget \
    git \
    ca-certificates \
    jq \
    nano \
    unzip \
    zip \
    p7zip-full \
    xz-utils \
    tar \
    gzip \
    bzip2 \
    iproute2 \
    net-tools \
    iputils-ping \
    dnsutils \
    tcpdump \
    isc-dhcp-client \
    psmisc \
    procps || true
hash -r || true

# 5. Garantizar comando 7z (fallback a binario estático 7zz si p7zip-full falló)
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

echo "[OK] Utilitarios base de Linux verificados:"
for cmd in git curl wget unzip 7z xz tar ip ifconfig ping dig tcpdump; do
    if command -v "$cmd" >/dev/null 2>&1; then
        echo "  [OK] $cmd -> $(command -v "$cmd")"
    fi
done
echo "------------------------------------------------------------------"
