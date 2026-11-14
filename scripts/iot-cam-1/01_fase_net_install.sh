#!/usr/bin/env bash
# ==============================================================================
# NODO: IoT-Cam-1 (linux-kali-2026.2)
# FASE 4.2 (CON SALIDA A INTERNET - Nube "Net")
# Propósito: Configurar hostname IoT-Cam-1, obtener IP por DHCP e instalar curl, nmap y hping3
# Uso: sudo bash scripts/iot-cam-1/01_fase_net_install.sh [interfaz=eth0]
# ==============================================================================
set -euo pipefail

IFACE="${1:-eth0}"
NODE_HOSTNAME="IoT-Cam-1"

echo "=================================================================="
echo "[IoT-Cam-1] Fase Previa (Net): Hostname + Herramientas IoT/Mirai"
echo "=================================================================="

echo "[1/4] Configurando hostname del sistema como '$NODE_HOSTNAME'..."
hostnamectl set-hostname "$NODE_HOSTNAME" 2>/dev/null || hostname "$NODE_HOSTNAME"
echo "$NODE_HOSTNAME" > /etc/hostname
if grep -q "^127\.0\.1\.1" /etc/hosts; then
    sed -i "s/^127\.0\.1\.1.*/127.0.1.1\t$NODE_HOSTNAME/" /etc/hosts
else
    echo -e "127.0.1.1\t$NODE_HOSTNAME" >> /etc/hosts
fi

echo "[2/4] Solicitando IP por DHCP en $IFACE..."
dhclient "$IFACE" || true
ip -4 addr show "$IFACE"

echo "[3/4] Instalando curl, nmap, hping3 y git..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y curl nmap hping3 git iproute2

echo "[4/4] Verificando binarios instalados..."
curl --version | head -n 1
nmap --version | head -n 1
hping3 --version | head -n 1

echo "=================================================================="
echo "[OK] Nodo '$NODE_HOSTNAME' preparado."
echo " -> SIGUIENTE PASO: Ejecuta 'poweroff', elimina el cable hacia 'Net'"
echo "    y conecta '$IFACE' al puerto ether1 de Router-Hogar."
echo "=================================================================="
