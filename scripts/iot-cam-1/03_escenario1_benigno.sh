#!/usr/bin/env bash
# ==============================================================================
# NODO: IoT-Cam-1 (192.168.10.10)
# FASE 6.1 - ESCENARIO 1: Tráfico Normal / Benigno (label = 0)
# Propósito: Simular peticiones HTTP periódicas sanas durante ~60 segundos
# Uso: bash scripts/iot-cam-1/03_escenario1_benigno.sh [ip_victima=172.16.0.100]
# ==============================================================================
set -euo pipefail

TARGET="${1:-172.16.0.100}"
ITERATIONS="${2:-120}"

echo "=================================================================="
echo "[IoT-Cam-1] ESCENARIO 1: Tráfico Benigno (label = 0)"
echo "Destino: http://$TARGET | Peticiones: $ITERATIONS (intervalo 0.5s)"
echo "=================================================================="
echo "[!] Asegúrate de haber iniciado la captura en SOC-Sniffer:"
echo "    sudo bash scripts/soc-sniffer/03_capturar_escenario.sh benign"
echo "------------------------------------------------------------------"

for i in $(seq 1 "$ITERATIONS"); do
    curl -s "http://$TARGET" > /dev/null || true
    printf "\r[*] Enviando telemetría/HTTP benigno: [%d/%d]" "$i" "$ITERATIONS"
    sleep 0.5
done

echo ""
echo "=================================================================="
echo "[OK] Escenario 1 (Benigno) finalizado."
echo " -> Presiona Ctrl + C en SOC-Sniffer para guardar 'benign.pcap'."
echo "=================================================================="
