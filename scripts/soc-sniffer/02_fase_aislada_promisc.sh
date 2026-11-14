#!/usr/bin/env bash
# ==============================================================================
# NODO: SOC-Sniffer (linux-kali-2026.2)
# FASE 5.3 (RED AISLADA - Conectado al puerto espejo Gi0/2 de SW-Core)
# Propósito: Asegurar hostname SOC-Sniffer y configurar eth0 en modo promiscuo puro (sin IP)
# Uso: sudo bash scripts/soc-sniffer/02_fase_aislada_promisc.sh [interfaz=eth0]
# ==============================================================================
set -euo pipefail

IFACE="${1:-eth0}"
NODE_HOSTNAME="SOC-Sniffer"

echo "=================================================================="
echo "[SOC-Sniffer] Configurando Sensor Pasivo en Modo Promiscuo ($IFACE)"
echo "=================================================================="

echo "[1/4] Verificando/asignando hostname '$NODE_HOSTNAME'..."
echo "$NODE_HOSTNAME" > /etc/hostname
hostname "$NODE_HOSTNAME" 2>/dev/null || true
hostnamectl set-hostname "$NODE_HOSTNAME" 2>/dev/null || true
if grep -q "^127\.0\.1\.1" /etc/hosts; then
    sed -i "s/^127\.0\.1\.1.*/127.0.1.1\t$NODE_HOSTNAME/" /etc/hosts
else
    echo -e "127.0.1.1\t$NODE_HOSTNAME" >> /etc/hosts
fi

echo "[2/4] Deteniendo cliente DHCP y limpiando direcciones IP en $IFACE..."
pkill -f "dhclient.*$IFACE" 2>/dev/null || true
ip addr flush dev "$IFACE"

echo "[3/4] Deshabilitando IPv6 en $IFACE para evitar ruido en las capturas..."
sysctl -w "net.ipv6.conf.$IFACE.disable_ipv6=1" >/dev/null 2>&1 || true

echo "[4/4] Activando interfaz $IFACE en modo PROMISCUO..."
ip link set "$IFACE" up promisc on
echo "Hostname activo: $(hostname)"
ip link show "$IFACE"

echo "=================================================================="
echo "[OK] Sensor $NODE_HOSTNAME activo en modo solo escucha (PROMISC)."
echo " -> Para verificar SPAN ejecuta: sudo tcpdump -i $IFACE -n"
echo "=================================================================="
