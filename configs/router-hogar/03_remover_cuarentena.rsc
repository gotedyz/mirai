# ==============================================================================
# NODO: Router-Hogar (MikroTik CHR 6.49.10)
# FASE POST-REMEDIACIÓN: Levantar "Cuarentena Suave" tras parcheo del IoT
# ==============================================================================

/queue simple
remove [find name="cuarentena-suave-iot"]

/queue simple print
