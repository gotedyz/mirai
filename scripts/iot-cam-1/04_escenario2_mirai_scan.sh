#!/usr/bin/env bash
# ==============================================================================
# NODO: IoT-Cam-1 (192.168.10.10)
# FASE 6.2 - ESCENARIO 2: Propagación Botnet Mirai - Telnet Scan Verbose (label = 1)
# Propósito: Escaneo SYN agresivo sobre puertos Telnet 23 y 2323 en 172.16.0.0/24
#            mostrando EN CALIENTE (--packet-trace -vv) cada paquete SYN enviado y recibido
# Uso: sudo bash scripts/iot-cam-1/04_escenario2_mirai_scan.sh [subred=172.16.0.0/24]
# ==============================================================================
set -euo pipefail

SUBNET="${1:-172.16.0.0/24}"

echo "=================================================================="
echo "[IoT-Cam-1] ESCENARIO 2 (VERBOSE EN CALIENTE): Propagación Mirai Telnet Scan"
echo "Objetivo: $SUBNET | Puertos: 23, 2323 | Tasa mínima: 500 pkt/s"
echo "Modo    : Verbose + Packet Trace en vivo (--packet-trace -vv)"
echo "=================================================================="
echo "[!] Asegúrate de tener corriendo en SOC-Sniffer:"
echo "    sudo bash scripts/soc-sniffer/03_capturar_escenario.sh mirai_scan"
echo "------------------------------------------------------------------"

nmap -vv --packet-trace --stats-every 1s -sS -p 23,2323 --min-rate 500 "$SUBNET"

echo "=================================================================="
echo "[OK] Escenario 2 (Mirai Scan) finalizado."
echo " -> Presiona [Ctrl + C] en SOC-Sniffer para guardar 'mirai_scan.pcap'."
echo "=================================================================="
