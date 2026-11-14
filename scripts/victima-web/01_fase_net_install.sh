#!/usr/bin/env bash
# ==============================================================================
# NODO: Victima-Web
# FASE 4.1 (CON SALIDA A INTERNET - Nube "Net")
# Propósito: Configurar hostname Victima-Web, obtener IP por DHCP, instalar Nginx + curl
# Uso: sudo bash scripts/victima-web/01_fase_net_install.sh [interfaz=eth0]
# ==============================================================================
set -euo pipefail

IFACE="${1:-eth0}"
NODE_HOSTNAME="Victima-Web"

echo "=================================================================="
echo "[Victima-Web] Fase Previa (Net): Hostname + Servidor Web Nginx"
echo "=================================================================="

echo "[1/5] Configurando hostname del sistema como '$NODE_HOSTNAME'..."
hostnamectl set-hostname "$NODE_HOSTNAME" 2>/dev/null || hostname "$NODE_HOSTNAME"
echo "$NODE_HOSTNAME" > /etc/hostname
if grep -q "^127\.0\.1\.1" /etc/hosts; then
    sed -i "s/^127\.0\.1\.1.*/127.0.1.1\t$NODE_HOSTNAME/" /etc/hosts
else
    echo -e "127.0.1.1\t$NODE_HOSTNAME" >> /etc/hosts
fi

echo "[2/5] Solicitando IP por DHCP en la interfaz $IFACE..."
dhclient "$IFACE" || true
ip -4 addr show "$IFACE"

echo "[3/5] Actualizando repositorios e instalando nginx, curl y git..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y nginx curl git iproute2

echo "[4/5] Habilitando e iniciando el servicio Nginx..."
systemctl enable nginx
systemctl restart nginx

echo "[5/5] Verificando respuesta local HTTP..."
curl -I http://localhost

echo "=================================================================="
echo "[OK] Nodo '$NODE_HOSTNAME' listo."
echo " -> SIGUIENTE PASO: Ejecuta 'poweroff', elimina el cable hacia 'Net'"
echo "    y conecta '$IFACE' al puerto Gi0/1 de SW-Core."
echo "=================================================================="
