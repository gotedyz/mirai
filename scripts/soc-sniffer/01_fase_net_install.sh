#!/usr/bin/env bash
# ==============================================================================
# NODO: SOC-Sniffer (linux-kali-2026.2)
# FASE 4.3 (CON SALIDA A INTERNET - Nube "Net")
# Propósito: Configurar hostname SOC-Sniffer, obtener IP por DHCP e instalar tcpdump, tshark y Kitsune-py
# Uso: sudo bash scripts/soc-sniffer/01_fase_net_install.sh [interfaz=eth0]
# ==============================================================================
set -euo pipefail

IFACE="${1:-eth0}"
NODE_HOSTNAME="SOC-Sniffer"

echo "=================================================================="
echo "[SOC-Sniffer] Fase Previa (Net): Hostname + Sniffer y Motor IA"
echo "=================================================================="

echo "[1/4] Configurando hostname del sistema como '$NODE_HOSTNAME'..."
echo "$NODE_HOSTNAME" > /etc/hostname
hostname "$NODE_HOSTNAME" 2>/dev/null || true
hostnamectl set-hostname "$NODE_HOSTNAME" 2>/dev/null || true
if grep -q "^127\.0\.1\.1" /etc/hosts; then
    sed -i "s/^127\.0\.1\.1.*/127.0.1.1\t$NODE_HOSTNAME/" /etc/hosts
else
    echo -e "127.0.1.1\t$NODE_HOSTNAME" >> /etc/hosts
fi

echo "[2/4] Solicitando IP por DHCP en $IFACE..."
dhclient "$IFACE" 2>/dev/null || true
ip -4 addr show "$IFACE"

echo "[3/4] Instalando tcpdump, tshark y librerías IA (sin actualizar systemd/python3 base)..."
export DEBIAN_FRONTEND=noninteractive
echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections || true
apt-get update -y
apt-get install -y --no-upgrade tcpdump tshark git python3-scapy python3-numpy python3-pandas python3-scipy python3-sklearn

echo "[4/4] Clonando repositorio oficial Kitsune-py (AfterImage) para uso offline..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
if [ ! -d "$PROJECT_ROOT/ai-pipeline/Kitsune-py" ]; then
    git clone https://github.com/ymirsky/Kitsune-py.git "$PROJECT_ROOT/ai-pipeline/Kitsune-py"
fi
# Desactivar llamada innecesaria a pyximport en Kitsune-py/netStat.py (AfterImage es Python puro)
sed -i 's/^import pyximport/#import pyximport/g; s/^pyximport\.install()/#pyximport.install()/g' "$PROJECT_ROOT/ai-pipeline/Kitsune-py/netStat.py" 2>/dev/null || true
chmod -R 777 "$PROJECT_ROOT" 2>/dev/null || true

echo "=================================================================="
echo "[OK] Nodo '$NODE_HOSTNAME' listo con tcpdump, tshark y Kitsune-py preinstalados."
echo "     (El nuevo hostname '$NODE_HOSTNAME' se verá en el prompt tras reiniciar)."
echo " -> SIGUIENTE PASO: Ejecuta 'sudo poweroff', elimina el cable hacia 'Net'"
echo "    y conecta '$IFACE' al puerto espejo Gi0/2 de SW-Core."
echo "=================================================================="
