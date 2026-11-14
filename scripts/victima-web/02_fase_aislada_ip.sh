#!/usr/bin/env bash
# ==============================================================================
# NODO: Victima-Web
# FASE 5.3 (RED AISLADA - Conectado a Gi0/1 de SW-Core)
# Propósito: Asignar IP estática 172.16.0.100/24 y asegurar Nginx activo
# Uso: sudo bash scripts/victima-web/02_fase_aislada_ip.sh [interfaz=eth0]
# ==============================================================================
set -euo pipefail

IFACE="${1:-eth0}"
STATIC_IP="172.16.0.100/24"

echo "=================================================================="
echo "[Victima-Web] Configuración en Red Aislada ($STATIC_IP)"
echo "=================================================================="

echo "[1/3] Limpiando configuraciones IP previas en $IFACE..."
pkill -f "dhclient.*$IFACE" 2>/dev/null || true
ip addr flush dev "$IFACE"

echo "[2/3] Asignando IP estática $STATIC_IP y levantando $IFACE..."
ip addr add "$STATIC_IP" dev "$IFACE"
ip link set "$IFACE" up

echo "[3/3] Verificando estado del servicio Nginx..."
systemctl start nginx
ip -4 addr show "$IFACE"
curl -I http://172.16.0.100

echo "=================================================================="
echo "[OK] Victima-Web operativa en http://172.16.0.100 (Red 100% aislada)."
echo "=================================================================="
