#!/usr/bin/env bash
# ==============================================================================
# NODO: SOC-Sniffer (linux-kali-2026.2)
# FASE 5.3 (RED AISLADA - Conectado al puerto espejo Gi0/2 de SW-Core)
# Propósito: Configurar eth0 en modo promiscuo puro (sin IPv4 ni IPv6)
# Uso: sudo bash scripts/soc-sniffer/02_fase_aislada_promisc.sh [interfaz=eth0]
# ==============================================================================
set -euo pipefail

IFACE="${1:-eth0}"

echo "=================================================================="
echo "[SOC-Sniffer] Configurando Sensor Pasivo en Modo Promiscuo ($IFACE)"
echo "=================================================================="

echo "[1/3] Deteniendo cliente DHCP y limpiando direcciones IP en $IFACE..."
pkill -f "dhclient.*$IFACE" 2>/dev/null || true
ip addr flush dev "$IFACE"

echo "[2/3] Deshabilitando IPv6 en $IFACE para evitar ruido en las capturas..."
sysctl -w "net.ipv6.conf.$IFACE.disable_ipv6=1" >/dev/null 2>&1 || true

echo "[3/3] Activando interfaz $IFACE en modo PROMISCUO..."
ip link set "$IFACE" up promisc on
ip link show "$IFACE"

echo "=================================================================="
echo "[OK] Sensor SOC-Sniffer activo en modo solo escucha (PROMISC)."
echo " -> Para verificar SPAN ejecuta: sudo tcpdump -i $IFACE -n"
echo "=================================================================="
