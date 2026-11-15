#!/usr/bin/env bash
# ==============================================================================
# NODO: SOC-Sniffer (linux-kali-2026.2)
# FASE 4.3 (CON SALIDA A INTERNET - Nube "Net")
# Propósito:
#   1. Ejecutar actualización base y utilitarios Linux (00_prepare_linux_vm.sh)
#      (apt-get update, curl, wget, git, unzip, 7z, xz-utils, net-tools, iproute2, ping, etc.)
#   2. Instalar herramientas de captura y extracción IA (tcpdump, tshark, scapy, numpy, pandas, scipy, sklearn)
#   3. Pre-clonar y parchear Kitsune-py (AfterImage) para extracción N-BaIoT offline
# Uso: sudo bash scripts/soc-sniffer/01_fase_net_install.sh [interfaz=eth0]
# ==============================================================================
set -euo pipefail

IFACE="${1:-eth0}"
NODE_HOSTNAME="SOC-Sniffer"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "=================================================================="
echo "[SOC-Sniffer] Fase Previa (Net): Update + Utilitarios + Sniffer/IA"
echo "=================================================================="

# 1. Ejecutar preparación común de todas las MVs Linux (Hostname, DHCP, DNS, Update, Utilitarios y Descompresores)
bash "$PROJECT_ROOT/scripts/common/00_prepare_linux_vm.sh" "$IFACE" "$NODE_HOSTNAME"

# 2. Instalar analizadores de paquetes y stack de Inteligencia Artificial en Python
echo "[2/3] Instalando tcpdump, tshark y librerías IA (scapy, numpy, pandas, scipy, scikit-learn)..."
export DEBIAN_FRONTEND=noninteractive
echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections || true
apt-get install -y --no-upgrade \
    tcpdump \
    tshark \
    python3 \
    python3-pip \
    python3-scapy \
    python3-numpy \
    python3-pandas \
    python3-scipy \
    python3-sklearn

# 3. Clonar y parchear Kitsune-py (AfterImage) para uso offline sin requerir Cython/pyximport
echo "[3/3] Clonando y configurando repositorio oficial Kitsune-py (AfterImage)..."
if [ ! -d "$PROJECT_ROOT/ai-pipeline/Kitsune-py" ]; then
    git clone https://github.com/ymirsky/Kitsune-py.git "$PROJECT_ROOT/ai-pipeline/Kitsune-py"
fi
sed -i 's/^import pyximport/#import pyximport/g; s/^pyximport\.install()/#pyximport.install()/g' "$PROJECT_ROOT/ai-pipeline/Kitsune-py/netStat.py" 2>/dev/null || true
chmod -R 777 "$PROJECT_ROOT" 2>/dev/null || true

echo "=================================================================="
echo "[OK] Nodo '$NODE_HOSTNAME' actualizado, con utilitarios, tshark y Kitsune-py listos."
echo " -> SIGUIENTE PASO: Ejecuta 'sudo poweroff', elimina el cable hacia 'Net'"
echo "    y conecta '$IFACE' al puerto espejo Gi0/2 de SW-Core."
echo "=================================================================="
