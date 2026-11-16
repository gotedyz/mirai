#!/usr/bin/env bash
# ==============================================================================
# NODO: Victima-Web
# FASE 5.3 (RED AISLADA - Conectado a Gi0/1 de SW-Core)
# Propósito:
#   1. Asegurar hostname Victima-Web y asignar IP 172.16.0.100/24 en eth0
#   2. Iniciar Nginx (o en su defecto un servidor HTTP Python3 en el puerto 80
#      si la MV está aislada y no tiene Nginx instalado)
#   3. Verificar respuesta HTTP 200 OK en http://172.16.0.100
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
echo "$NODE_HOSTNAME" > /etc/hostname
hostname "$NODE_HOSTNAME" 2>/dev/null || true
hostnamectl set-hostname "$NODE_HOSTNAME" 2>/dev/null || true
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

echo "[4/4] Iniciando y verificando servicio HTTP en puerto 80..."
mkdir -p /var/www/html
if [ ! -f /var/www/html/index.html ]; then
    cat << 'EOF' > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head><title>Victima-Web - Servidor Corporativo</title></head>
<body><h1>Servidor Web Operativo (172.16.0.100) - Laboratorio Mirai PNETLab</h1></body>
</html>
EOF
fi

# Intentar iniciar nginx o apache2 si están instalados
if command -v nginx >/dev/null 2>&1; then
    systemctl restart nginx 2>/dev/null || service nginx restart 2>/dev/null || /usr/sbin/nginx 2>/dev/null || true
elif command -v apache2 >/dev/null 2>&1; then
    systemctl restart apache2 2>/dev/null || service apache2 restart 2>/dev/null || true
fi

sleep 1

# Fallback automático: Si el puerto 80 aún no responde (ej. Nginx no instalado en red aislada),
# levantar servidor HTTP nativo con Python3 en el puerto 80
if ! curl -sI --connect-timeout 2 http://172.16.0.100 >/dev/null 2>&1; then
    echo "[*] Nginx no detectado activo. Levantando servidor HTTP nativo (Python3) en puerto 80..."
    pkill -f "http\.server 80" 2>/dev/null || true
    nohup python3 -m http.server 80 --bind 0.0.0.0 --directory /var/www/html >/var/log/victima_http.log 2>&1 &
    sleep 1
fi

echo "Hostname activo: $(hostname)"
ip -4 addr show "$IFACE"
echo "------------------------------------------------------------------"
curl -I http://172.16.0.100

echo "=================================================================="
echo "[OK] $NODE_HOSTNAME operativa en http://172.16.0.100 (Puerto 80 ACTIVO)."
echo "=================================================================="
