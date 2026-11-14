#!/usr/bin/env bash
# ==============================================================================
# NODO: SOC-Sniffer (linux-kali-2026.2)
# FASE 4.3 (CON SALIDA A INTERNET - Nube "Net")
# Propósito: Obtener IP por DHCP e instalar tcpdump, tshark y librerías IA/Kitsune
# Uso: sudo bash scripts/soc-sniffer/01_fase_net_install.sh [interfaz=eth0]
# ==============================================================================
set -euo pipefail

IFACE="${1:-eth0}"

echo "=================================================================="
echo "[SOC-Sniffer] Fase Previa (Net): Instalación de Sniffer y Motor IA"
echo "=================================================================="

echo "[1/3] Solicitando IP por DHCP en $IFACE..."
dhclient "$IFACE" || true
ip -4 addr show "$IFACE"

echo "[2/3] Instalando tcpdump, tshark y herramientas Python para IA..."
export DEBIAN_FRONTEND=noninteractive
echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections || true
apt-get update -y
apt-get install -y tcpdump tshark git python3 python3-pip python3-scapy python3-numpy python3-pandas python3-scipy python3-sklearn

echo "[3/3] Clonando repositorio oficial Kitsune-py (AfterImage) para uso offline..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
if [ ! -d "$PROJECT_ROOT/ai-pipeline/Kitsune-py" ]; then
    git clone https://github.com/ymirsky/Kitsune-py.git "$PROJECT_ROOT/ai-pipeline/Kitsune-py"
fi

echo "=================================================================="
echo "[OK] SOC-Sniffer listo con tcpdump, tshark y Kitsune-py preinstalados."
echo " -> SIGUIENTE PASO: Ejecuta 'poweroff', elimina el cable hacia 'Net'"
echo "    y conecta '$IFACE' al puerto espejo Gi0/2 de SW-Core."
echo "=================================================================="
