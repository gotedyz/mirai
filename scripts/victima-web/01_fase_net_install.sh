#!/usr/bin/env bash
# ==============================================================================
# NODO: Victima-Web
# FASE 4.1 (CON SALIDA A INTERNET - Nube "Net")
# Propósito:
#   1. Ejecutar actualización base y utilitarios Linux (00_prepare_linux_vm.sh)
#      (apt-get update, curl, wget, git, unzip, 7z, xz-utils, net-tools, iproute2, ping, etc.)
#   2. Instalar y habilitar el servidor web Nginx para recibir el tráfico del laboratorio
# Uso: sudo bash scripts/victima-web/01_fase_net_install.sh [interfaz=eth0]
# ==============================================================================
set -euo pipefail

IFACE="${1:-eth0}"
NODE_HOSTNAME="Victima-Web"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "=================================================================="
echo "[Victima-Web] Fase Previa (Net): Update + Utilitarios + Nginx"
echo "=================================================================="

# 1. Ejecutar preparación común de todas las MVs Linux (Hostname, DHCP, DNS, Update, Utilitarios y Descompresores)
bash "$PROJECT_ROOT/scripts/common/00_prepare_linux_vm.sh" "$IFACE" "$NODE_HOSTNAME"

# 2. Instalar servicio específico del nodo: Servidor Web Nginx
echo "[2/4] Instalando servidor web Nginx..."
export DEBIAN_FRONTEND=noninteractive
apt-get install -y --no-upgrade nginx

# 3. Habilitar e iniciar Nginx
echo "[3/4] Habilitando e iniciando el servicio Nginx..."
systemctl daemon-reexec 2>/dev/null || true
systemctl enable nginx 2>/dev/null || update-rc.d nginx defaults 2>/dev/null || true
systemctl restart nginx 2>/dev/null || service nginx restart 2>/dev/null || /usr/sbin/nginx || true

# 4. Verificar respuesta local HTTP
echo "[4/4] Verificando respuesta local HTTP..."
curl -I http://localhost

echo "=================================================================="
echo "[OK] Nodo '$NODE_HOSTNAME' actualizado y con todos sus utilitarios listos."
echo " -> SIGUIENTE PASO: Ejecuta 'sudo poweroff', elimina el cable hacia 'Net'"
echo "    y conecta '$IFACE' al puerto Gi0/1 de SW-Core."
echo "=================================================================="
