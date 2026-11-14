#!/usr/bin/env bash
# ==============================================================================
# NODO: SOC-Sniffer (linux-kali-2026.2)
# FASE 6: Captura de los 3 Escenarios de Tráfico (.pcap)
# Uso:
#   sudo bash scripts/soc-sniffer/03_capturar_escenario.sh benign [eth0]
#   sudo bash scripts/soc-sniffer/03_capturar_escenario.sh mirai_scan [eth0]
#   sudo bash scripts/soc-sniffer/03_capturar_escenario.sh mirai_syn [eth0]
# ==============================================================================
set -euo pipefail

SCENARIO="${1:-}"
IFACE="${2:-eth0}"

if [[ -z "$SCENARIO" ]]; then
    echo "Uso: sudo bash $0 <benign | mirai_scan | mirai_syn> [interfaz=eth0]"
    exit 1
fi

case "$SCENARIO" in
    benign|1)
        PCAP_NAME="benign.pcap"
        DESC="Escenario 1: Tráfico Normal / Benigno (label = 0)"
        ;;
    mirai_scan|scan|2)
        PCAP_NAME="mirai_scan.pcap"
        DESC="Escenario 2: Propagación Mirai Telnet Scan (label = 1)"
        ;;
    mirai_syn|syn|3)
        PCAP_NAME="mirai_syn.pcap"
        DESC="Escenario 3: Ataque DDoS Mirai TCP SYN Flood (label = 1)"
        ;;
    *)
        PCAP_NAME="${SCENARIO}.pcap"
        DESC="Escenario personalizado: $SCENARIO"
        ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PCAP_DIR="$PROJECT_ROOT/pcaps"
mkdir -p "$PCAP_DIR"
OUT_FILE="$PCAP_DIR/$PCAP_NAME"

# Asegurar modo promiscuo antes de capturar
ip link set "$IFACE" up promisc on 2>/dev/null || true

echo "=================================================================="
echo "[SOC-Sniffer] INICIANDO CAPTURA: $DESC"
echo "Interfaz : $IFACE (Modo Promiscuo)"
echo "Archivo  : $OUT_FILE"
echo "=================================================================="
echo "[!] Lanza ahora el tráfico desde IoT-Cam-1."
echo "[!] Cuando termine, presiona [Ctrl + C] para cerrar y guardar el archivo."
echo "------------------------------------------------------------------"

tcpdump -i "$IFACE" -U -w "$OUT_FILE" || true

# Crear enlace simbólico o copia en el directorio actual para acceso rápido
cp -f "$OUT_FILE" "./$PCAP_NAME" 2>/dev/null || true

echo ""
echo "=================================================================="
echo "[OK] Captura guardada en: $OUT_FILE (y ./$PCAP_NAME)"
if command -v capinfos >/dev/null 2>&1; then
    capinfos -c "$OUT_FILE" || true
else
    COUNT=$(tcpdump -r "$OUT_FILE" 2>/dev/null | wc -l || echo "0")
    echo "[*] Total de paquetes capturados: $COUNT"
fi
echo "=================================================================="
