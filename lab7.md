# GUÍA DE LABORATORIO (COMPLETA Y AUTOMATIZADA VÍA GITHUB): DETECCIÓN DE BOTNETS IoT EN PNETLAB + IA

**Curso:** Inteligencia Artificial para la Ciberseguridad  
**Institución:** Tecsup | **Periodo:** 2026 – Semestre II  
**Docente:** Godofredo Diaz  

---

### 1. Objetivo del Laboratorio
Construir en **PNETLab** una topología aislada que simule una red doméstica conectada a una operadora de telecomunicaciones, automatizar el aprovisionamiento y ejecución en cada dispositivo clonando los scripts desde **GitHub**, capturar tráfico benigno y ataques tipo **Mirai** (`scan` y `SYN flood`) mediante **SPAN (*Port Mirroring*)**, extraer las **115 características estadísticas de N-BaIoT (`AfterImage`)** y entrenar clasificadores de IA (**Random Forest** e **Isolation Forest**) para detectar el dispositivo comprometido y aplicar una **cuarentena suave** en el router.

---

### 2. Topología de Red en PNETLab

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

#### Resumen de nodos, imágenes y scripts asociados en el repositorio

| Nodo en Topología | Imagen seleccionada | vCPU | RAM | Carpeta de Scripts / Config en GitHub | Rol en el laboratorio |
| :--- | :--- | :---: | :---: | :--- | :--- |
| **`PNETLab Host`** | Servidor PNETLab (`root`) | - | - | `scripts/pnetlab-host/` | Descarga e instala las imágenes QEMU del laboratorio. |
| **`Router-Hogar`** | `mikrotik-6.49` *(CHR 6.49.10)* | 1 | 256 MB | `configs/router-hogar/` | Router CPE del cliente (NAT + pruebas de cuarentena suave). |
| **`SW-Core`** | `viosl2-...20200929` *(ID `368`)* | 1 | 768 MB | `configs/sw-core/` | Switch de agregación que ejecuta el **SPAN** real sin afectar tráfico. |
| **`IoT-Cam-1`** | `linux-kali-2026.2` | 1 | 1024 MB | `scripts/iot-cam-1/` | Cámara/monitor IoT (genera tráfico sano y ataques `scan`/`SYN`). |
| **`Victima-Web`** | Linux ligero / Ubuntu + Nginx | 1 | 512 MB | `scripts/victima-web/` | Servidor víctima aislado que responde HTTP y recibe el ataque. |
| **`SOC-Sniffer`** | `linux-kali-2026.2` | 1–2 | 1024 MB | `scripts/soc-sniffer/` & `ai-pipeline/` | Sensor pasivo del SOC que captura `.pcap` desde el puerto espejo. |

---

### 3. Preparación de Imágenes en el Servidor PNETLab (Consola `root`)

Conéctate por SSH a la consola `root` de PNETLab, clona el repositorio y ejecuta los scripts de instalación de imágenes:

```bash
git clone https://github.com/gotedyz/mirai.git /opt/mirai
cd /opt/mirai

# Opción A: Instalar las 3 imágenes (MikroTik CHR, Cisco vIOS-L2 y Kali 2026.2) automáticamente:
sudo bash scripts/pnetlab-host/install_all_images.sh

# Opción B: O ejecutarlas de forma individual por separado:
sudo bash scripts/pnetlab-host/01_install_mikrotik.sh
sudo bash scripts/pnetlab-host/02_install_viosl2.sh
sudo bash scripts/pnetlab-host/03_install_kali.sh
```
*(Al agregar los nodos Kali en la interfaz web de PNETLab, selecciónalos bajo la plantilla **Linux** con el nombre **`linux-kali-2026.2`**; credenciales predeterminadas: usuario `kali` / contraseña `kali` o `root`)*.

---

### 4. FASE PREVIA OBLIGATORIA: Conexión temporal a `Net`, Clonación desde GitHub e Instalación

> **¡IMPORTANTE!**  
> Antes de interconectar los nodos entre sí y fijar IPs estáticas aisladas, **los 3 nodos Linux deben conectarse temporalmente a Internet mediante la nube `Net` (Cloud0 / NAT de PNETLab)** para clonar el repositorio desde GitHub (`/opt/mirai`) e instalar sus paquetes con su script `01_fase_net_install.sh`. Así, cuando pases a la **Red Aislada (sin Internet)**, cada dispositivo ya tendrá todos sus scripts descargados localmente.

```text
    ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
    │ Victima-Web  │     │  IoT-Cam-1   │     │ SOC-Sniffer  │
    └──────┬───────┘     └──────┬───────┘     └──────┬───────┘
           │ (eth0)             │ (eth0)             │ (eth0)
           ▼                    ▼                    ▼
    ┌────────────────────────────────────────────────────────┐
    │   Nube "Net" de PNETLab (Internet -> git clone repo)   │
    └────────────────────────────────────────────────────────┘
```

#### Paso 4.1: En `Victima-Web`
1. Conectar `eth0` a la red **`Net`** y encender el nodo.
2. Clonar el repositorio y ejecutar el script de aprovisionamiento (`01_fase_net_install.sh`):
   ```bash
   sudo dhclient eth0
   sudo apt-get update && sudo apt-get install -y git
   sudo git clone https://github.com/gotedyz/mirai.git /opt/mirai
   cd /opt/mirai
   sudo bash scripts/victima-web/01_fase_net_install.sh
   ```
3. Apagar el nodo (`sudo poweroff`) y **eliminar el cable conectado a `Net`**.

#### Paso 4.2: En `IoT-Cam-1` (`linux-kali-2026.2`)
1. Conectar `eth0` a la red **`Net`** y encender el nodo.
2. Clonar el repositorio y ejecutar el script de aprovisionamiento (`01_fase_net_install.sh`):
   ```bash
   sudo dhclient eth0
   sudo apt-get update && sudo apt-get install -y git
   sudo git clone https://github.com/gotedyz/mirai.git /opt/mirai
   cd /opt/mirai
   sudo bash scripts/iot-cam-1/01_fase_net_install.sh
   ```
3. Apagar el nodo (`sudo poweroff`) y **eliminar el cable conectado a `Net`**.

#### Paso 4.3: En `SOC-Sniffer` (`linux-kali-2026.2`)
1. Conectar `eth0` a la red **`Net`** y encender el nodo.
2. Clonar el repositorio y ejecutar el script de aprovisionamiento (`01_fase_net_install.sh` — instala `tcpdump`, `tshark`, librerías Python y pre-clona `Kitsune-py` para uso offline):
   ```bash
   sudo dhclient eth0
   sudo apt-get update && sudo apt-get install -y git
   sudo git clone https://github.com/gotedyz/mirai.git /opt/mirai
   cd /opt/mirai
   sudo bash scripts/soc-sniffer/01_fase_net_install.sh
   ```
3. Apagar el nodo (`sudo poweroff`) y **eliminar el cable conectado a `Net`**.

---

### 5. Configuración de la Red Aislada (Usando los Scripts Clonados)

Una vez retirados los cables hacia `Net` e interconectada la topología aislada definitiva:

#### Paso 5.1: Configurar `Router-Hogar` (MikroTik CHR `6.49.10`)
Archivo de configuración en el repositorio: **`configs/router-hogar/01_config_inicial_nat.rsc`**  
Entra por consola a MikroTik (`admin`, sin contraseña) y pega el bloque del script:

```rsc
/system identity set name=Router-Hogar

/ip address
add address=192.168.10.1/24 interface=ether1 comment="LAN-Hogar"
add address=172.16.0.2/24 interface=ether2 comment="WAN-Operadora"

/ip firewall nat
add chain=srcnat out-interface=ether2 action=masquerade comment="NAT-Salida-Operadora"

/ip address print
/ip firewall nat print
```

**Resultado esperado de `/ip address print` y `/ip firewall nat print`:**
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

#### Paso 5.2: Configurar `SW-Core` (`viosl2`) y activar SPAN
Archivo de configuración en el repositorio: **`configs/sw-core/01_config_span.ios`**  
Entra a la consola de `viosl2` y aplica la configuración:

```ios
enable
configure terminal
 hostname SW-Core
 interface range Gi0/0 - 1
  switchport mode access
  no shutdown
 exit
 interface Gi0/2
  no shutdown
 exit
 no monitor session 1
 monitor session 1 source interface Gi0/0 both
 monitor session 1 destination interface Gi0/2
end
write memory
show monitor session 1
```

**Resultado esperado de `show monitor session 1`:**
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

#### Paso 5.3: Ejecutar los scripts de Red Aislada en cada nodo Linux (Hostname + IP)

**En `Victima-Web` (Hostname `Victima-Web` | `172.16.0.100/24`):**
```bash
cd /opt/mirai
sudo bash scripts/victima-web/02_fase_aislada_ip.sh
```

**En `IoT-Cam-1` (Hostname `IoT-Cam-1` | `192.168.10.10/24` | GW `192.168.10.1`):**
```bash
cd /opt/mirai
sudo bash scripts/iot-cam-1/02_fase_aislada_ip.sh
```
*(El script configura el hostname `IoT-Cam-1`, asigna la IP, configura la ruta por defecto y verifica automáticamente `curl -I http://172.16.0.100` a través del NAT de `Router-Hogar`).*

**En `SOC-Sniffer` (Hostname `SOC-Sniffer` | `eth0` en modo promiscuo sin IP):**
```bash
cd /opt/mirai
sudo bash scripts/soc-sniffer/02_fase_aislada_promisc.sh
```

---

### 6. Generación de Tráfico y Captura Automatizada de los 3 Escenarios

Utiliza los scripts de captura en `SOC-Sniffer` y los scripts generadores en `IoT-Cam-1`:

1. **Escenario 1 — Tráfico Normal (`benign.pcap` $\rightarrow$ `label = 0`):**
   * En `SOC-Sniffer`:  
     ```bash
     cd /opt/mirai
     sudo bash scripts/soc-sniffer/03_capturar_escenario.sh benign
     ```
   * En `IoT-Cam-1` (simula navegación y *streaming* sano durante ~1 minuto):  
     ```bash
     cd /opt/mirai
     bash scripts/iot-cam-1/03_escenario1_benigno.sh
     ```
   * En `SOC-Sniffer`: Al finalizar el script en `IoT-Cam-1`, presiona **`Ctrl + C`** para guardar `pcaps/benign.pcap`.

2. **Escenario 2 — Propagación Mirai (`mirai_scan.pcap` $\rightarrow$ `label = 1`):**
   * En `SOC-Sniffer`:  
     ```bash
     cd /opt/mirai
     sudo bash scripts/soc-sniffer/03_capturar_escenario.sh mirai_scan
     ```
   * En `IoT-Cam-1` (ejecuta escaneo SYN rápido a puertos Telnet `23` y `2323`):  
     ```bash
     cd /opt/mirai
     sudo bash scripts/iot-cam-1/04_escenario2_mirai_scan.sh
     ```
   * En `SOC-Sniffer`: Presiona **`Ctrl + C`** para guardar `pcaps/mirai_scan.pcap`.

3. **Escenario 3 — Ataque DDoS Mirai (`mirai_syn.pcap` $\rightarrow$ `label = 1`):**
   * En `SOC-Sniffer`:  
     ```bash
     cd /opt/mirai
     sudo bash scripts/soc-sniffer/03_capturar_escenario.sh mirai_syn
     ```
   * En `IoT-Cam-1` (ejecuta ráfaga controlada *TCP SYN Flood* durante 10 segundos):  
     ```bash
     cd /opt/mirai
     sudo bash scripts/iot-cam-1/05_escenario3_mirai_syn.sh
     ```
   * En `SOC-Sniffer`: Presiona **`Ctrl + C`** para guardar `pcaps/mirai_syn.pcap`.

---

### 7. Extracción de 115 Características N-BaIoT y Detección con IA (Colab o Local)

Tienes dos modalidades para ejecutar el pipeline de Inteligencia Artificial ubicado en `ai-pipeline/`:

#### Modalidad A: Ejecución directa en `SOC-Sniffer` (100% Offline en el laboratorio)
Como `01_fase_net_install.sh` ya instaló Python, `scapy`, `scikit-learn` y `Kitsune-py` en `SOC-Sniffer`:
```bash
cd /opt/mirai
python3 ai-pipeline/01_extract_nbaiot_115_features.py --pcap-dir ./pcaps --out nbaiot_pnetlab.csv
python3 ai-pipeline/02_train_evaluate_models.py --csv nbaiot_pnetlab.csv
```

#### Modalidad B: Ejecución en Google Colab
1. Abre en Google Colab el notebook incluido en el repositorio: **`ai-pipeline/Colab_Mirai_NBaIoT_Detector.ipynb`**.
2. Sube los 3 archivos (`benign.pcap`, `mirai_scan.pcap`, `mirai_syn.pcap`) al entorno de Colab y ejecuta las celdas para:
   - Extraer las **115 características de N-BaIoT (`AfterImage`)** en `nbaiot_pnetlab.csv`.
   - Entrenar y comparar **Random Forest (Supervisado)** vs. **Isolation Forest (No Supervisado)** obteniendo **Exactitud, Precisión, Recall, F1-Score, FPR, Matriz de Confusión y Top 5 de Características**.

---

### 8. Cierre Operativo: Respuesta SOC con "Cuarentena Suave" en MikroTik

Cuando el modelo de IA confirme el tráfico anómalo/malicioso originado desde `IoT-Cam-1` (`192.168.10.10`), aplica en `Router-Hogar` el script **`configs/router-hogar/02_activar_cuarentena_suave.rsc`**:

```rsc
/queue simple
add name="cuarentena-suave-iot" target=192.168.10.10/32 max-limit=64k/64k comment="Mitigacion SOC IA - Dispositivo IoT Comprometido (Mirai)"
```
*(Y para revertir la medida tras parchar el dispositivo, utiliza **`configs/router-hogar/03_remover_cuarentena.rsc`**).*
