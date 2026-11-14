#!/usr/bin/env bash
# ==============================================================================
# NODO: IoT-Cam-1 (192.168.10.10)
# FASE 6.2 - ESCENARIO 2: Propagación Botnet Mirai - Telnet Scan (label = 1)
# Propósito: Escaneo SYN agresivo sobre puertos Telnet 23 y 2323 en 172.16.0.0/24
# Uso: sudo bash scripts/iot-cam-1/04_escenario2_mirai_scan.sh [subred=172.16.0.0/24]
# ==============================================================================
set -euo pipefail

SUBNET="${1:-172.16.0.0/24}"

echo "=================================================================="
echo "[IoT-Cam-1] ESCENARIO 2: Propagación Mirai - Escaneo Telnet (label = 1)"
echo "Objetivo: $SUBNET | Puertos: 23, 2323 | Tasa mínima: 500 pkt/s"
echo "=================================================================="
echo "[!] Asegúrate de haber iniciado la captura en SOC-Sniffer:"
echo "    sudo bash scripts/soc-sniffer/03_capturar_escenario.sh mirai_scan"
echo "------------------------------------------------------------------"

nmap -sS -p 23,2323 --min-rate 500 "$SUBNET"

echo "=================================================================="
echo "[OK] Escenario 2 (Mirai Scan) finalizado."
echo " -> Presiona Ctrl + C en SOC-Sniffer para guardar 'mirai_scan.pcap'."
echo "=================================================================="
