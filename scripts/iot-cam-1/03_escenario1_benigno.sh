#!/usr/bin/env bash
# ==============================================================================
# NODO: IoT-Cam-1 (192.168.10.10)
# FASE 6.1 - ESCENARIO 1: Tráfico Normal / Benigno en Modo Verbose (label = 0)
# Propósito: Simular peticiones HTTP periódicas sanas mostrando en vivo cada
#            transacción HTTP (código de estado, latencia, bytes y cabeceras)
# Uso: bash scripts/iot-cam-1/03_escenario1_benigno.sh [ip_victima=172.16.0.100] [iteraciones=120]
# ==============================================================================
set -euo pipefail

TARGET="${1:-172.16.0.100}"
ITERATIONS="${2:-120}"

echo "=================================================================="
echo "[IoT-Cam-1] ESCENARIO 1 (VERBOSE EN CALIENTE): Tráfico Benigno (label = 0)"
echo "Destino: http://$TARGET | Peticiones: $ITERATIONS (intervalo 0.5s)"
echo "=================================================================="
echo "[!] Asegúrate de tener corriendo en SOC-Sniffer:"
echo "    sudo bash scripts/soc-sniffer/03_capturar_escenario.sh benign"
echo "------------------------------------------------------------------"

for i in $(seq 1 "$ITERATIONS"); do
    TS="$(date +'%H:%M:%S')"
    # Obtener código HTTP, bytes descargados y tiempo de respuesta en vivo
    STATS="$(curl -s -o /dev/null -w "HTTP %{http_code} | Bytes: %{size_download} B | RTT: %{time_total}s | Local: %{local_ip}:%{local_port} -> %{remote_ip}:%{remote_port}" --connect-timeout 2 "http://$TARGET" || echo "ERROR: Sin respuesta de http://$TARGET (verifica que Victima-Web tenga el puerto 80 activo)")"
    echo "[$TS] [Benigno $i/$ITERATIONS] GET http://$TARGET/ -> $STATS"
    sleep 0.5
done

echo "=================================================================="
echo "[OK] Escenario 1 (Benigno) finalizado ($ITERATIONS peticiones enviadas)."
echo " -> Presiona [Ctrl + C] en SOC-Sniffer para guardar 'benign.pcap'."
echo "=================================================================="
