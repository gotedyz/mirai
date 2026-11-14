#!/usr/bin/env bash
# ==============================================================================
# NODO: Victima-Web
# FASE 5.3 (RED AISLADA - Conectado a Gi0/1 de SW-Core)
# Propósito: Asegurar hostname Victima-Web, asignar IP 172.16.0.100/24 y validar Nginx
# Uso: sudo bash scripts/victima-web/02_fase_aislada_ip.sh [interfaz=eth0]
# ==============================================================================
set -euo pipefail

IFACE="${1:-eth0}"
STATIC_IP="172.16.0.100/24"
NODE_HOSTNAME="Victima-Web"

echo "=================================================================="
echo "[Victima-Web] Configuración en Red Aislada ($STATIC_IP)"
echo "=================================================================="

echo "[1/4] Verificando/asignando hostname '$NODE_HOSTNAME'..."
hostnamectl set-hostname "$NODE_HOSTNAME" 2>/dev/null || hostname "$NODE_HOSTNAME"
echo "$NODE_HOSTNAME" > /etc/hostname
if grep -q "^127\.0\.1\.1" /etc/hosts; then
    sed -i "s/^127\.0\.1\.1.*/127.0.1.1\t$NODE_HOSTNAME/" /etc/hosts
else
    echo -e "127.0.1.1\t$NODE_HOSTNAME" >> /etc/hosts
fi

echo "[2/4] Limpiando configuraciones IP previas en $IFACE..."
pkill -f "dhclient.*$IFACE" 2>/dev/null || true
ip addr flush dev "$IFACE"

echo "[3/4] Asignando IP estática $STATIC_IP y levantando $IFACE..."
ip addr add "$STATIC_IP" dev "$IFACE"
ip link set "$IFACE" up

echo "[4/4] Verificando estado del servicio Nginx..."
systemctl start nginx
echo "Hostname actual: $(hostname)"
ip -4 addr show "$IFACE"
curl -I http://172.16.0.100

echo "=================================================================="
echo "[OK] $NODE_HOSTNAME operativa en http://172.16.0.100 (Red 100% aislada)."
echo "=================================================================="
