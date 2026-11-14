# ==============================================================================
# NODO: Router-Hogar (MikroTik CHR 6.49.10)
# FASE 8: Cierre Operativo SOC - Aplicar "Cuarentena Suave" (Rate-Limiting)
# Marco: NIST AI RMF (Detección IA -> Alerta SOC -> Cuarentena Suave -> Verificación)
# ==============================================================================

/queue simple
add name="cuarentena-suave-iot" target=192.168.10.10/32 max-limit=64k/64k comment="Mitigacion SOC IA - Dispositivo IoT Comprometido (Mirai)"

/queue simple print stats
