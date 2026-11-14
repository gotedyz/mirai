#!/usr/bin/env bash
# ==============================================================================
# NODO: IoT-Cam-1 (linux-kali-2026.2)
# FASE 5.3 (RED AISLADA - Conectado a ether1 de Router-Hogar)
# Propósito: Asegurar hostname IoT-Cam-1, configurar IP 192.168.10.10/24, GW 192.168.10.1 y validar NAT
# Uso: sudo bash scripts/iot-cam-1/02_fase_aislada_ip.sh [interfaz=eth0]
# ==============================================================================
set -euo pipefail

IFACE="${1:-eth0}"
STATIC_IP="192.168.10.10/24"
GATEWAY="192.168.10.1"
TARGET_WEB="172.16.0.100"
NODE_HOSTNAME="IoT-Cam-1"

echo "=================================================================="
echo "[IoT-Cam-1] Configuración de Red Aislada ($STATIC_IP | GW: $GATEWAY)"
echo "=================================================================="

echo "[1/5] Verificando/asignando hostname '$NODE_HOSTNAME'..."
echo "$NODE_HOSTNAME" > /etc/hostname
hostname "$NODE_HOSTNAME" 2>/dev/null || true
hostnamectl set-hostname "$NODE_HOSTNAME" 2>/dev/null || true
if grep -q "^127\.0\.1\.1" /etc/hosts; then
    sed -i "s/^127\.0\.1\.1.*/127.0.1.1\t$NODE_HOSTNAME/" /etc/hosts
else
    echo -e "127.0.1.1\t$NODE_HOSTNAME" >> /etc/hosts
fi

echo "[2/5] Limpiando configuraciones previas en $IFACE..."
pkill -f "dhclient.*$IFACE" 2>/dev/null || true
ip addr flush dev "$IFACE"

echo "[3/5] Asignando IP $STATIC_IP y levantando $IFACE..."
ip addr add "$STATIC_IP" dev "$IFACE"
ip link set "$IFACE" up

echo "[4/5] Configurando puerta de enlace predeterminada ($GATEWAY)..."
ip route replace default via "$GATEWAY"
echo "Hostname activo: $(hostname)"
ip -4 addr show "$IFACE"
ip route show

echo "[5/5] Probando conectividad hacia Victima-Web ($TARGET_WEB) vía NAT MikroTik..."
if curl -I --connect-timeout 5 "http://$TARGET_WEB"; then
    echo "[OK] Conectividad exitosa: $NODE_HOSTNAME alcanza a Victima-Web a través de Router-Hogar."
else
    echo "[!] Aviso: No se obtuvo respuesta de http://$TARGET_WEB."
    echo "    Verifica que Router-Hogar, SW-Core y Victima-Web ya estén configurados."
fi
