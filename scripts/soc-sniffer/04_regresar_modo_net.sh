#!/usr/bin/env bash
# ==============================================================================
# NODO: SOC-Sniffer (linux-kali-2026.2)
# FASE 7 (RECONEXIÓN A "Net" PARA SALIDA A INTERNET / GOOGLE COLAB)
# Propósito:
#   1. Desactivar modo promiscuo en eth0 tras haber capturado los 3 .pcap
#   2. Solicitar IP y puerta de enlace por DHCP desde la nube "Net" de PNETLab
#   3. Sincronizar el repositorio (/opt/mirai) con 'git pull' y ajustar permisos
#   4. Dejar listo el navegador / entorno para usar Google Colab o IA local
#
# Uso (después de mover el cable de eth0 desde SW-Core Gi0/2 hacia la nube "Net"):
#   sudo bash scripts/soc-sniffer/04_regresar_modo_net.sh [interfaz=eth0]
# ==============================================================================
set -euo pipefail

IFACE="${1:-eth0}"
NODE_HOSTNAME="SOC-Sniffer"

echo "=================================================================="
echo "[SOC-Sniffer] Revirtiendo Modo Promiscuo -> Reconectando a 'Net'"
echo "=================================================================="

echo "[1/5] Asegurando hostname '$NODE_HOSTNAME'..."
echo "$NODE_HOSTNAME" > /etc/hostname
hostname "$NODE_HOSTNAME" 2>/dev/null || true
hostnamectl set-hostname "$NODE_HOSTNAME" 2>/dev/null || true
if grep -q "^127\.0\.1\.1" /etc/hosts; then
    sed -i "s/^127\.0\.1\.1.*/127.0.1.1\t$NODE_HOSTNAME/" /etc/hosts
else
    echo -e "127.0.1.1\t$NODE_HOSTNAME" >> /etc/hosts
fi

echo "[2/5] Desactivando modo PROMISCUO y limpiando interfaz $IFACE..."
pkill -f "dhclient.*$IFACE" 2>/dev/null || true
ip link set "$IFACE" promisc off
ip addr flush dev "$IFACE"
sysctl -w "net.ipv6.conf.$IFACE.disable_ipv6=0" >/dev/null 2>&1 || true
ip link set "$IFACE" up

echo "[3/5] Solicitando IP por DHCP a la nube 'Net' en $IFACE..."
dhclient -v "$IFACE" || dhclient "$IFACE" || true

# Asegurar DNS funcional por si DHCP no sobreescribió resolv.conf
if ! grep -q "nameserver" /etc/resolv.conf 2>/dev/null; then
    echo -e "nameserver 8.8.8.8\nnameserver 1.1.1.1" > /etc/resolv.conf
fi

ip -4 addr show "$IFACE"
ip route show

echo "[4/5] Verificando salida a Internet y sincronizando /opt/mirai desde GitHub..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

if ping -c 2 -W 3 8.8.8.8 >/dev/null 2>&1; then
    echo "[OK] Salida a Internet confirmada."
    git -C "$PROJECT_ROOT" pull --ff-only 2>/dev/null || true
else
    echo "[!] Aviso: Aún no responde ping a 8.8.8.8. Verifica que el cable de $IFACE esté conectado a la nube 'Net'."
fi

echo "[5/5] Aplicando parche Kitsune-py (pyximport) y permisos de lectura/escritura a los .pcap..."
if [ -f "$PROJECT_ROOT/ai-pipeline/Kitsune-py/netStat.py" ]; then
    sed -i 's/^import pyximport/#import pyximport/g; s/^pyximport\.install()/#pyximport.install()/g' "$PROJECT_ROOT/ai-pipeline/Kitsune-py/netStat.py" 2>/dev/null || true
fi
chmod -R 777 "$PROJECT_ROOT" 2>/dev/null || true

echo "=================================================================="
echo "[OK] SOC-Sniffer reconectado a Internet y con permisos listos."
echo " -> Archivos .pcap disponibles en: $PROJECT_ROOT/pcaps/"
ls -lh "$PROJECT_ROOT/pcaps/"*.pcap 2>/dev/null || true
echo " -> Ya puedes abrir el navegador hacia Google Colab o ejecutar en terminal:"
echo "    python3 ai-pipeline/01_extract_nbaiot_115_features.py --pcap-dir ./pcaps --out nbaiot_pnetlab.csv"
echo "    python3 ai-pipeline/02_train_evaluate_models.py --csv nbaiot_pnetlab.csv"
echo "=================================================================="
