# 🛡️ Detección de Botnets IoT (Mirai) en PNETLab + Inteligencia Artificial (`N-BaIoT` / `AfterImage`)

**Curso:** Inteligencia Artificial para la Ciberseguridad  
**Institución:** Tecsup | **Periodo:** 2026 – Semestre II  
**Docente:** Godofredo Diaz 

---

## 🎯 Propósito del Repositorio

Este repositorio contiene todos los **scripts de automatización, archivos de configuración de red (`.rsc`, `.ios`) y el pipeline de Inteligencia Artificial (`.py`, `.ipynb`)** separados por dispositivo para desplegar el laboratorio de **Detección de Botnets IoT (Mirai) en PNETLab**.

El flujo está diseñado bajo el principio **"Clonar en Fase `Net` $\rightarrow$ Ejecutar en Red Aislada"**:
1. Durante la **Fase 4 (Conexión temporal a `Net` / Internet)**, cada nodo Linux (`Victima-Web`, `IoT-Cam-1`, `SOC-Sniffer`) clona este repositorio con `git clone`.
2. Una vez desconectados de `Net` y aislados en la topología del laboratorio (**Fases 5 y 6**), todos los scripts ya residen localmente dentro de `/opt/mirai` en cada máquina virtual, eliminando errores de tipeo manual.

---

## 🗺️ Topología del Laboratorio en PNETLab

```text
  [IoT-Cam-1] (linux-kali-2026.2)
   IP: 192.168.10.10/24  |  GW: 192.168.10.1
         │ (eth0)
         ▼
         │ (ether1 - LAN: 192.168.10.1/24)
  [Router-Hogar] (MikroTik CHR 6.49.10 - NAT Masquerade)
         │ (ether2 - WAN: 172.16.0.2/24)
         │
         ▼ (Gi0/0)
  ┌──────────────────────────────────────────────────────────┐
  │ SW-Core (viosl2-adventerprisek9-m.ssa.high_iron_20200929)│
  │   • SPAN: monitor session 1 source Gi0/0 -> dest Gi0/2   │
  └──────┬────────────────────────────────────┬──────────────┘
         │ (Gi0/1)                            │ (Gi0/2 - Puerto Espejo)
         ▼                                    ▼
  [Victima-Web] (Linux + Nginx)          [SOC-Sniffer] (linux-kali-2026.2)
   IP: 172.16.0.100/24                    • eth0 en modo promiscuo (sin IP)
   (Red 100% aislada, SIN Net)            • Graba .pcap con tcpdump
```

---

## 📂 Estructura de Archivos por Dispositivo

```text
mirai/
├── README.md                                      # Guía rápida de clonación y ejecución por nodo
├── lab7.md                                        # Guía de laboratorio completa paso a paso
├── scripts/
│   ├── pnetlab-host/                              # 0. Servidor PNETLab (Consola root)
│   │   ├── 01_install_mikrotik.sh                 # Instala MikroTik CHR 6.49.10
│   │   ├── 02_install_viosl2.sh                   # Instala Cisco vIOS-L2 (ID 368) con ishare2
│   │   ├── 03_install_kali.sh                     # Instala Kali Linux 2026.2 QEMU
│   │   └── install_all_images.sh                  # Instala todas las imágenes en un solo paso
│   ├── victima-web/                               # 1. Nodo Victima-Web (172.16.0.100/24)
│   │   ├── 01_fase_net_install.sh                 # [Con Net] Hostname Victima-Web + DHCP + instala Nginx, curl, git
│   │   └── 02_fase_aislada_ip.sh                  # [Aislado] Hostname Victima-Web + IP 172.16.0.100/24 + Nginx
│   ├── iot-cam-1/                                 # 2. Nodo IoT-Cam-1 (192.168.10.10/24)
│   │   ├── 01_fase_net_install.sh                 # [Con Net] Hostname IoT-Cam-1 + DHCP + instala curl, nmap, hping3
│   │   ├── 02_fase_aislada_ip.sh                  # [Aislado] Hostname IoT-Cam-1 + IP 192.168.10.10/24 + GW + Test NAT
│   │   ├── 03_escenario1_benigno.sh               # [Tráfico] Escenario 1 (label=0): HTTP normal (~60s)
│   │   ├── 04_escenario2_mirai_scan.sh            # [Ataque]  Escenario 2 (label=1): Escaneo Telnet 23/2323
│   │   └── 05_escenario3_mirai_syn.sh             # [Ataque]  Escenario 3 (label=1): DDoS TCP SYN Flood (10s)
│   └── soc-sniffer/                               # 3. Nodo SOC-Sniffer (eth0 Promiscuo sin IP)
│       ├── 01_fase_net_install.sh                 # [Con Net] Hostname SOC-Sniffer + DHCP + tcpdump, tshark, Kitsune-py
│       ├── 02_fase_aislada_promisc.sh             # [Aislado] Hostname SOC-Sniffer + Limpia IP + activa PROMISC
│       ├── 03_capturar_escenario.sh               # [Captura] Graba benign.pcap, mirai_scan.pcap o mirai_syn.pcap
│       └── 04_regresar_modo_net.sh                # [Con Net] Quita PROMISC, pide DHCP a Net y sincroniza para usar Colab
├── configs/
│   ├── router-hogar/                              # 4. Nodo Router-Hogar (MikroTik CHR 6.49.10)
│   │   ├── 01_config_inicial_nat.rsc              # LAN 192.168.10.1/24, WAN 172.16.0.2/24 y NAT Masquerade
│   │   ├── 02_activar_cuarentena_suave.rsc        # Respuesta SOC: Rate-limit 64k/64k a 192.168.10.10/32
│   │   └── 03_remover_cuarentena.rsc              # Levanta la cuarentena tras remediación
│   └── sw-core/                                   # 5. Nodo SW-Core (Cisco vIOS-L2)
│       └── 01_config_span.ios                     # Configura puertos Gi0/0-2 y SPAN Gi0/0 both -> Gi0/2
└── ai-pipeline/                                   # 6. Extracción N-BaIoT (115 features) y Modelos de IA
    ├── 01_extract_nbaiot_115_features.py          # Extrae las 115 features con AfterImage -> nbaiot_pnetlab.csv
    ├── 02_train_evaluate_models.py                # Entrena Random Forest vs Isolation Forest + Dictamen SOC
    ├── requirements.txt                           # Dependencias de Python
    └── Colab_Mirai_NBaIoT_Detector.ipynb          # Notebook listo para Google Colab
```

---

## 🚀 Guía Rápida de Clonación y Ejecución por Dispositivo

### 0. En el Servidor PNETLab (`root`) — Preparación de Imágenes
```bash
git clone https://github.com/gotedyz/mirai.git /opt/mirai
cd /opt/mirai
sudo bash scripts/pnetlab-host/install_all_images.sh
```

---

### 1. En `Victima-Web` (`172.16.0.100/24`)
**A) Conectado temporalmente a `Net` (Internet):**
```bash
sudo dhclient eth0
sudo apt-get update && sudo apt-get install -y git
sudo git clone https://github.com/gotedyz/mirai.git /opt/mirai
cd /opt/mirai
sudo bash scripts/victima-web/01_fase_net_install.sh
sudo poweroff
```
**B) Conectado a la Red Aislada (`Gi0/1` de `SW-Core`):**
```bash
cd /opt/mirai
sudo bash scripts/victima-web/02_fase_aislada_ip.sh
```

---

### 2. En `IoT-Cam-1` (`192.168.10.10/24`)
**A) Conectado temporalmente a `Net` (Internet):**
```bash
sudo dhclient eth0
sudo apt-get update && sudo apt-get install -y git
sudo git clone https://github.com/gotedyz/mirai.git /opt/mirai
cd /opt/mirai
sudo bash scripts/iot-cam-1/01_fase_net_install.sh
sudo poweroff
```
**B) Conectado a la Red Aislada (`ether1` de `Router-Hogar`):**
```bash
cd /opt/mirai
sudo bash scripts/iot-cam-1/02_fase_aislada_ip.sh

# Generación de los 3 escenarios (coordinado con SOC-Sniffer):
bash scripts/iot-cam-1/03_escenario1_benigno.sh
sudo bash scripts/iot-cam-1/04_escenario2_mirai_scan.sh
sudo bash scripts/iot-cam-1/05_escenario3_mirai_syn.sh
```

---

### 3. En `SOC-Sniffer` (`eth0` Promiscuo)
**A) Conectado temporalmente a `Net` (Internet):**
```bash
sudo dhclient eth0
sudo apt-get update && sudo apt-get install -y git
sudo git clone https://github.com/gotedyz/mirai.git /opt/mirai
cd /opt/mirai
sudo bash scripts/soc-sniffer/01_fase_net_install.sh
sudo poweroff
```
**B) Conectado al Puerto Espejo (`Gi0/2` de `SW-Core`):**
```bash
cd /opt/mirai
sudo bash scripts/soc-sniffer/02_fase_aislada_promisc.sh

# Capturar cada escenario (presionar Ctrl+C al finalizar cada uno):
sudo bash scripts/soc-sniffer/03_capturar_escenario.sh benign
sudo bash scripts/soc-sniffer/03_capturar_escenario.sh mirai_scan
sudo bash scripts/soc-sniffer/03_capturar_escenario.sh mirai_syn
```
**C) Reconectar `eth0` a la nube `Net` para tener Internet y subir a Google Colab:**
*(En PNETLab, desconecta `eth0` de `SW-Core Gi0/2`, conéctalo a la nube `Net` y ejecuta):*
```bash
cd /opt/mirai
sudo bash scripts/soc-sniffer/04_regresar_modo_net.sh
```

---

### 4. En `Router-Hogar` (MikroTik CHR `6.49.10`) y `SW-Core` (Cisco `vIOS-L2`)
- **Router-Hogar:** Copiar y pegar el contenido de [`configs/router-hogar/01_config_inicial_nat.rsc`](configs/router-hogar/01_config_inicial_nat.rsc) y, para la mitigación final del SOC, aplicar [`configs/router-hogar/02_activar_cuarentena_suave.rsc`](configs/router-hogar/02_activar_cuarentena_suave.rsc). Al finalizar con `/ip address print` y `/ip firewall nat print`, el resultado esperado es:
  ```text
  [admin@Router-Hogar] > /ip address print
  Flags: X - disabled, I - invalid, D - dynamic
   #   ADDRESS            NETWORK         INTERFACE
   0   ;;; LAN-Hogar
       192.168.10.1/24    192.168.10.0    ether1
   1   ;;; WAN-Operadora
       172.16.0.2/24      172.16.0.0      ether2

  [admin@Router-Hogar] > /ip firewall nat print
  Flags: X - disabled, I - invalid, D - dynamic
   0    ;;; NAT-Salida-Operadora
        chain=srcnat action=masquerade out-interface=ether2
  ```
- **SW-Core:** Copiar y pegar el contenido de [`configs/sw-core/01_config_span.ios`](configs/sw-core/01_config_span.ios). Al finalizar con `show monitor session 1`, el resultado esperado es:
  ```text
  SW-Core# show monitor session 1
  Session 1
  ---------
  Type                   : Local Session
  Source Ports           : 
      Both               : Gi0/0
  Destination Ports      : Gi0/2
      Encapsulation      : Native
            Ingress      : Disabled
  ```

---

### 5. Extracción de 115 Features N-BaIoT y Entrenamiento IA (Colab o Local)
Puedes abrir el notebook [`ai-pipeline/Colab_Mirai_NBaIoT_Detector.ipynb`](ai-pipeline/Colab_Mirai_NBaIoT_Detector.ipynb) directamente en **Google Colab**, o ejecutar el pipeline directamente en consola (incluso offline dentro de `SOC-Sniffer`):
```bash
cd /opt/mirai
python3 ai-pipeline/01_extract_nbaiot_115_features.py --pcap-dir ./pcaps --out nbaiot_pnetlab.csv
python3 ai-pipeline/02_train_evaluate_models.py --csv nbaiot_pnetlab.csv
```
