#!/usr/bin/env bash
# ==============================================================================
# NODO: SOC-Sniffer (linux-kali-2026.2)
# FASE 6: Captura Interactiva y Verbose EN CALIENTE de los 3 Escenarios (.pcap)
# Propósito:
#   - Captura el tráfico del puerto espejo (SPAN) guardándolo en el archivo .pcap
#   - Muestra EN TIEMPO REAL (modo verbose en caliente) cada paquete capturado
#     en pantalla mientras se escribe simultáneamente en disco
# Uso:
#   sudo bash scripts/soc-sniffer/03_capturar_escenario.sh [benign | mirai_scan | mirai_syn] [eth0]
#   (Si no se indica el escenario por parámetro, muestra un menú interactivo)
# ==============================================================================
set -euo pipefail

SCENARIO="${1:-}"
IFACE="${2:-eth0}"

# Menú interactivo si el usuario no pasa el escenario como argumento
if [[ -z "$SCENARIO" ]]; then
    echo "=================================================================="
    echo "   [SOC-Sniffer] SELECCIÓN INTERACTIVA DE ESCENARIO A CAPTURAR"
    echo "=================================================================="
    echo "  1) benign      -> Escenario 1: Tráfico Normal / Benigno (label = 0)"
    echo "  2) mirai_scan  -> Escenario 2: Propagación Mirai Telnet Scan (label = 1)"
    echo "  3) mirai_syn   -> Escenario 3: Ataque DDoS Mirai TCP SYN Flood (label = 1)"
    echo "------------------------------------------------------------------"
    read -r -p "Selecciona el número o nombre del escenario [1/2/3]: " SCENARIO
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
echo "[SOC-Sniffer] CAPTURA EN CALIENTE (MODO VERBOSE EN TIEMPO REAL)"
echo "Escenario : $DESC"
echo "Interfaz  : $IFACE (Modo Promiscuo ACTIVO)"
echo "Archivo   : $OUT_FILE"
echo "=================================================================="
echo "[!] Lanza ahora el tráfico en la consola de IoT-Cam-1."
echo "[!] Verás cada paquete en vivo aquí abajo conforme atraviese el SPAN."
echo "[!] Cuando termine el escenario, presiona [Ctrl + C] para guardar."
echo "------------------------------------------------------------------"

trap 'echo ""; echo "[*] Deteniendo captura en vivo y cerrando archivo PCAP..."' INT

set +e
# Captura binaria packet-buffered (-U) hacia archivo y simultáneamente decodifica en vivo (-v -n -l) en pantalla
tcpdump -i "$IFACE" -U -w - 2>/dev/null | tee "$OUT_FILE" | tcpdump -r - -n -l -v
set -e

trap - INT

# Crear copia en el directorio actual y dar permisos completos para tshark (.tsv)
cp -f "$OUT_FILE" "./$PCAP_NAME" 2>/dev/null || true
chmod -R 777 "$PCAP_DIR" "./$PCAP_NAME" 2>/dev/null || true

echo ""
echo "=================================================================="
echo "[OK] CAPTURA FINALIZADA Y GUARDADA: $OUT_FILE"
echo "------------------------------------------------------------------"
COUNT=$(tcpdump -r "$OUT_FILE" -n 2>/dev/null | wc -l || echo "0")
FILE_SIZE=$(du -h "$OUT_FILE" 2>/dev/null | cut -f1 || echo "0K")
echo "  -> Total de paquetes capturados : $COUNT paquetes"
echo "  -> Tamaño del archivo .pcap     : $FILE_SIZE"
echo "------------------------------------------------------------------"
echo "  -> Muestra de los últimos 5 paquetes registrados en $PCAP_NAME:"
tcpdump -r "$OUT_FILE" -n -c 5 2>/dev/null || true
echo "=================================================================="
