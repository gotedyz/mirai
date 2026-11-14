# ==============================================================================
# NODO: Router-Hogar (MikroTik CHR 6.49.10)
# FASE 5.1: Configuración Inicial de Interfaces LAN/WAN y NAT Masquerade
# Uso en consola MikroTik: /import file-name=01_config_inicial_nat.rsc
# O copiar y pegar directamente en la terminal de RouterOS (usuario: admin)
# ==============================================================================

/system identity set name=Router-Hogar

/ip address
add address=192.168.10.1/24 interface=ether1 comment="LAN-Hogar"
add address=172.16.0.2/24 interface=ether2 comment="WAN-Operadora"

/ip firewall nat
add chain=srcnat out-interface=ether2 action=masquerade comment="NAT-Salida-Operadora"

/ip address print
/ip firewall nat print
