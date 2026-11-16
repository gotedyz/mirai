#!/usr/bin/env bash
# ==============================================================================
# NODO: IoT-Cam-1 (linux-kali-2026.2)
# FASE 4.2 (CON SALIDA A INTERNET - Nube "Net")
# Propósito:
#   1. Ejecutar actualización base y utilitarios Linux (00_prepare_linux_vm.sh)
#      (apt-get update, curl, wget, git, unzip, 7z, xz-utils, net-tools, iproute2, ping, etc.)
#   2. Instalar herramientas de telemetría IoT y emulación Mirai (nmap, hping3, netcat, telnet)
# Uso: sudo bash scripts/iot-cam-1/01_fase_net_install.sh [interfaz=eth0]
# ==============================================================================
set -euo pipefail

IFACE="${1:-eth0}"
NODE_HOSTNAME="IoT-Cam-1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "=================================================================="
echo "[IoT-Cam-1] Fase Previa (Net): Update + Utilitarios + Herramientas Mirai"
echo "=================================================================="

# 1. Ejecutar preparación común de todas las MVs Linux (Hostname, DHCP, DNS, Update, Utilitarios y Descompresores)
bash "$PROJECT_ROOT/scripts/common/00_prepare_linux_vm.sh" "$IFACE" "$NODE_HOSTNAME"

# 2. Instalar herramientas específicas de generación de tráfico y ataque Mirai
echo "[2/3] Instalando nmap, hping3, netcat y telnet..."
export DEBIAN_FRONTEND=noninteractive
apt-get install -y --no-upgrade nmap hping3 netcat-traditional telnet || \
apt-get install -y nmap hping3 netcat-traditional telnet || \
apt-get install -y nmap hping3

# 3. Verificar binarios instalados
echo "[3/3] Verificando binarios del nodo IoT-Cam-1..."
curl --version | head -n 1
nmap --version | head -n 1
hping3 --version | head -n 1

echo "=================================================================="
echo "[OK] Nodo '$NODE_HOSTNAME' actualizado y con todos sus utilitarios listos."
echo " -> SIGUIENTE PASO: Ejecuta 'sudo poweroff', elimina el cable hacia 'Net'"
echo "    y conecta '$IFACE' al puerto ether1 de Router-Hogar."
echo "=================================================================="
