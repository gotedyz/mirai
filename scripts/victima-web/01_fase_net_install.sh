#!/usr/bin/env bash
# ==============================================================================
# NODO: Victima-Web
# FASE 4.1 (CON SALIDA A INTERNET - Nube "Net")
# Propósito: Obtener IP por DHCP, instalar Nginx + curl y verificar HTTP 200 OK
# Uso: sudo bash scripts/victima-web/01_fase_net_install.sh [interfaz=eth0]
# ==============================================================================
set -euo pipefail

IFACE="${1:-eth0}"

echo "=================================================================="
echo "[Victima-Web] Fase Previa (Net): Instalación de Servidor Web Nginx"
echo "=================================================================="

echo "[1/4] Solicitando IP por DHCP en la interfaz $IFACE..."
dhclient "$IFACE" || true
ip -4 addr show "$IFACE"

echo "[2/4] Actualizando repositorios e instalando nginx, curl y git..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y nginx curl git iproute2

echo "[3/4] Habilitando e iniciando el servicio Nginx..."
systemctl enable nginx
systemctl restart nginx

echo "[4/4] Verificando respuesta local HTTP..."
curl -I http://localhost

echo "=================================================================="
echo "[OK] Victima-Web lista."
echo " -> SIGUIENTE PASO: Ejecuta 'poweroff', elimina el cable hacia 'Net'"
echo "    y conecta '$IFACE' al puerto Gi0/1 de SW-Core."
echo "=================================================================="
