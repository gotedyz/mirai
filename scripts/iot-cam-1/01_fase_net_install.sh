#!/usr/bin/env bash
# ==============================================================================
# NODO: IoT-Cam-1 (linux-kali-2026.2)
# FASE 4.2 (CON SALIDA A INTERNET - Nube "Net")
# Propósito: Obtener IP por DHCP e instalar curl, nmap y hping3
# Uso: sudo bash scripts/iot-cam-1/01_fase_net_install.sh [interfaz=eth0]
# ==============================================================================
set -euo pipefail

IFACE="${1:-eth0}"

echo "=================================================================="
echo "[IoT-Cam-1] Fase Previa (Net): Instalación de herramientas IoT/Mirai"
echo "=================================================================="

echo "[1/3] Solicitando IP por DHCP en $IFACE..."
dhclient "$IFACE" || true
ip -4 addr show "$IFACE"

echo "[2/3] Instalando curl, nmap, hping3 y git..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y curl nmap hping3 git iproute2

echo "[3/3] Verificando binarios instalados..."
curl --version | head -n 1
nmap --version | head -n 1
hping3 --version | head -n 1

echo "=================================================================="
echo "[OK] IoT-Cam-1 preparada."
echo " -> SIGUIENTE PASO: Ejecuta 'poweroff', elimina el cable hacia 'Net'"
echo "    y conecta '$IFACE' al puerto ether1 de Router-Hogar."
echo "=================================================================="
