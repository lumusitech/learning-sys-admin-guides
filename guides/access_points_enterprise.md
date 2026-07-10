# Access Points Enterprise — Guía completa

**Nivel:** 🔴 Avanzado
**Archivos de práctica:** Sistema en vivo
**Ver escenarios relacionados:** N/A

---

## ⚡ Quick command

```bash
# Ubiquiti UniFi
ssh admin@unifi-controller "mca-cli-op dump ap"

# Aruba/HP
ssh admin@aruba-controller "show ap debug radio-statistics"

# Cisco WLC
ssh admin@cisco-wlc "show ap summary"
```

---

## 📑 Índice

1. [¿Qué son Access Points Enterprise?](#qué-son-access-points-enterprise)
2. [Modelo mental](#modelo-mental)
3. [Ubiquiti UniFi](#ubiquiti-unifi)
4. [Aruba/HP](#arubahp)
5. [Cisco WLC](#cisco-wlc)
6. [Ruckus](#ruckus)
7. [Diagnóstico de señal WiFi](#diagnóstico-de-señal-wifi)
8. [VLANs para WiFi corporativo](#vlans-para-wifi-corporativo)
9. [Autenticación (RADIUS, LDAP)](#autenticación-radius-ldap)
10. [Troubleshooting](#troubleshooting)
11. [Uno-liners imprescindibles](#uno-liners-imprescindibles)
12. [Referencias internas](#referencias-internas)

---

## 🧠 ¿Qué son Access Points Enterprise?

Los **Access Points Enterprise** son puntos de acceso WiFi diseñados para entornos corporativos con:

- **Controller centralizado**: gestión unificada de múltiples APs
- **Roaming seamless**: clientes se mueven entre APs sin perder conexión
- **VLANs múltiples**: diferentes SSIDs en diferentes VLANs
- **Autenticación enterprise**: RADIUS, LDAP, Active Directory
- **Monitoreo avanzado**: métricas de rendimiento, interferencia, clientes
- **Alta densidad**: diseñados para 50-100+ clientes simultáneos

### Diferencias vs Access Points Consumer

| Característica | Enterprise | Consumer |
|----------------|------------|----------|
| **Controller** | ✅ Centralizado | ❌ Standalone |
| **Roaming** | ✅ Seamless | ⚠️ Básico |
| **VLANs** | ✅ Múltiples por SSID | ❌ Una sola |
| **RADIUS/LDAP** | ✅ Soportado | ❌ No |
| **Monitoreo** | ✅ Avanzado | ⚠️ Básico |
| **Densidad** | ✅ 50-100+ clientes | ⚠️ 10-20 clientes |
| **PoE** | ✅ 802.3af/at | ⚠️ Algunos modelos |
| **Precio** | 💰💰💰 $200-800 | 💰 $30-100 |

---

## 🧠 Modelo mental

Un AP enterprise es un **transceptor de radio gestionado centralizadamente**.

Piensa en el sistema como:

- **Controller**: cerebro central (configuración, políticas, monitoreo)
- **APs**: extremos de radio (transmiten/reciben, aplican políticas)
- **Clientes**: dispositivos WiFi (laptops, phones, IoT)

El controller decide:

- Qué SSID broadcastar
- En qué VLAN colocar cada SSID
- Qué canal usar (evitar interferencia)
- Qué potencia de transmisión
- A qué AP hacer roaming

---

## 📡 Ubiquiti UniFi

### Arquitectura

```text
[UniFi Controller] ←→ [UniFi APs] ←→ [Clientes WiFi]
       ↓
[Switch PoE] ←→ [Router/Gateway]
```

### Acceso SSH al AP

```bash
# Credenciales por defecto
ssh ubnt@192.168.1.20
# Password: ubnt (o la configurada en el controller)
```

### Comandos útiles

```bash
# Ver información del AP
mca-cli-op dump ap

# Ver clientes conectados
mca-cli-op dump sta

# Ver estadísticas de radio
mca-cli-op dump radio

# Ver canales y potencia
mca-cli-op dump radio | grep -E "channel|txpower"

# Ver interferencia
mca-cli-op dump spectrum

# Reiniciar AP
reboot

# Factory reset
syswrapper.sh restore-default
```

### API del Controller

```bash
# Autenticar y obtener token
curl -k -X POST "https://controller:8443/api/login" \
  -d '{"username":"admin","password":"admin"}' \
  -c /tmp/unifi_cookies

# Listar APs
curl -k -b /tmp/unifi_cookies \
  "https://controller:8443/api/s/default/stat/device"

# Listar clientes
curl -k -b /tmp/unifi_cookies \
  "https://controller:8443/api/s/default/stat/sta"

# Reiniciar AP específico
curl -k -b /tmp/unifi_cookies -X POST \
  "https://controller:8443/api/s/default/cmd/devmgr" \
  -d '{"cmd":"restart","mac":"00:11:22:33:44:55"}'
```

---

## 📡 Aruba/HP

### Arquitectura

```text
[Aruba Mobility Controller] ←→ [Aruba APs] ←→ [Clientes WiFi]
       ↓
[Switch PoE] ←→ [Router/Gateway]
```

### Acceso SSH al Controller

```bash
ssh admin@192.168.1.1
# Password: configurado
```

### Comandos útiles

```bash
# Ver APs conectados
show ap active

# Ver información de un AP específico
show ap debug radio-statistics ap-name AP01

# Ver clientes conectados
show ap association ap-name AP01

# Ver interferencia
show ap radio-counters ap-name AP01

# Ver canales
show ap radio-summary

# Reiniciar AP
ap-reset AP01

# Factory reset
ap-reset AP01 factory
```

### AirWave (monitoreo)

```bash
# API de AirWave
curl -u admin:admin \
  "https://airwave:443/API/apList.xml"

# Ver métricas de AP
curl -u admin:admin \
  "https://airwave:443/API/apDetails.xml?mac=00:11:22:33:44:55"
```

---

## 📡 Cisco WLC

### Arquitectura

```text
[Cisco WLC] ←→ [Cisco APs (Lightweight)] ←→ [Clientes WiFi]
       ↓
[Switch PoE] ←→ [Router/Gateway]
```

### Acceso SSH al WLC

```bash
ssh admin@192.168.1.1
# Password: configurado
```

### Comandos útiles

```bash
# Ver APs registrados
show ap summary

# Ver información de un AP específico
show ap detail -n AP01

# Ver clientes conectados
show client summary

# Ver interferencia
show ap interference-summary

# Ver canales
show ap channel-summary

# Reiniciar AP
reset-system ap AP01

# Factory reset
reset-system ap AP01 factory
```

### API del WLC

```bash
# API REST (WLC 8.x+)
curl -k -u admin:admin \
  "https://wlc:443/api/v1/accesspoint"

# Ver APs
curl -k -u admin:admin \
  "https://wlc:443/api/v1/accesspoint?macAddress=00:11:22:33:44:55"
```

---

## 📡 Ruckus

### Arquitectura

```text
[Ruckus SmartZone] ←→ [Ruckus APs] ←→ [Clientes WiFi]
       ↓
[Switch PoE] ←→ [Router/Gateway]
```

### Acceso SSH al AP

```bash
ssh admin@192.168.1.20
# Password: configurado
```

### Comandos útiles

```bash
# Ver información del AP
get system-info

# Ver clientes conectados
get station

# Ver estadísticas de radio
get radio-stats

# Ver interferencia
get interference

# Reiniciar AP
reboot

# Factory reset
factory-reset
```

### SmartZone Controller

```bash
# API de SmartZone
curl -k -u admin:admin \
  "https://smartzone:8443/wsg/api/scg/ap"

# Ver APs
curl -k -u admin:admin \
  "https://smartzone:8443/wsg/api/scg/ap?listSize=100"
```

---

## 🔍 Diagnóstico de señal WiFi

### Herramientas de diagnóstico

```bash
# Ver redes WiFi disponibles
iwlist wlan0 scan

# Ver información de la conexión actual
iwconfig wlan0

# Ver detalles de la conexión (señal, ruido, etc.)
iw dev wlan0 link

# Ver canales disponibles
iwlist wlan0 channel

# Monitorear tráfico WiFi
tcpdump -i wlan0 -n

# Capturar paquetes WiFi (modo monitor)
airmon-ng start wlan0
tcpdump -i mon0 -n
```

### Interpretación de señal

| RSSI (dBm) | Calidad | Interpretación |
|------------|---------|----------------|
| -30 a -50 | Excelente | Cerca del AP, máxima velocidad |
| -50 a -67 | Buena | Velocidad alta, streaming OK |
| -67 a -70 | Aceptable | Velocidad media, navegación OK |
| -70 a -80 | Débil | Velocidad baja, posible desconexión |
| < -80 | Muy débil | Conexión inestable |

### Diagnóstico de interferencia

```bash
# Escanear canales WiFi
iwlist wlan0 scan | grep -E "Channel|Quality|ESSID"

# Ver uso de canales
iw dev wlan0 survey dump

# Analizar espectro (requiere hardware compatible)
wavemon -i wlan0
```

---

## 🌐 VLANs para WiFi corporativo

### Configuración típica

```text
SSID: Empresa-Secure → VLAN 10 (empleados)
SSID: Empresa-Guest  → VLAN 200 (invitados)
SSID: Empresa-IoT    → VLAN 30 (dispositivos IoT)
SSID: Empresa-Voice  → VLAN 40 (teléfonos VoIP)
```

### Configurar VLANs en AP Ubiquiti

```bash
# En el UniFi Controller
# 1. Ir a Settings → Networks
# 2. Crear red "VLAN 10 - Empleados"
# 3. Asignar SSID "Empresa-Secure" a la red
# 4. Configurar DHCP para la VLAN
```

### Configurar VLANs en AP Aruba

```bash
# En el Mobility Controller
vlan 10
  name "Empleados"
  untagged ap-group default

wlan ssid-profile "Empresa-Secure"
  essid "Empresa-Secure"
  opmode wpa2-aes
  vlan 10
```

---

## 🔐 Autenticación (RADIUS, LDAP)

### Configurar RADIUS en Ubiquiti

```bash
# En el UniFi Controller
# 1. Ir a Settings → Profiles → RADIUS
# 2. Agregar servidor RADIUS
# 3. Configurar SSID para usar RADIUS
```

### Configurar RADIUS en Aruba

```bash
# En el Mobility Controller
aaa authentication dot1x default radius
aaa server group "RADIUS-SERVERS"
  auth-server 192.168.1.100
  acct-server 192.168.1.100

wlan ssid-profile "Empresa-Secure"
  essid "Empresa-Secure"
  opmode wpa2-enterprise
  aaa profile "RADIUS-PROFILE"
```

### Diagnóstico de autenticación

```bash
# Ver logs de autenticación
tail -f /var/log/radius.log

# Probar autenticación RADIUS
radtest usuario password radius-server 1812 secret

# Ver clientes autenticados
show dot1x associations
```

---

## 🚨 Troubleshooting

### Problema 1: AP no aparece en controller

```bash
# Verificar conectividad
ping 192.168.1.20

# Verificar que el AP tiene IP
# (conectar directamente y verificar DHCP)

# Verificar que el AP puede alcanzar el controller
ssh ubnt@192.168.1.20
ping controller-ip

# Factory reset si es necesario
syswrapper.sh restore-default
```

### Problema 2: Clientes no se conectan

```bash
# Verificar SSID broadcast
iwlist wlan0 scan | grep "Empresa-Secure"

# Verificar autenticación
# (revisar logs del RADIUS server)

# Verificar VLAN
# (verificar que el DHCP está configurado para la VLAN)
```

### Problema 3: Roaming no funciona

```bash
# Verificar que los APs tienen el mismo SSID
# Verificar que los APs están en el mismo controller
# Verificar que los canales no se superponen
show ap channel-summary
```

### Problema 4: Baja velocidad

```bash
# Verificar señal
iwconfig wlan0 | grep "Link Quality"

# Verificar interferencia
iwlist wlan0 scan | grep "Channel"

# Verificar canal
# (cambiar a canal menos congestionado)
```

---

## 💡 Uno-liners imprescindibles

```bash
# Ubiquiti: Listar APs activos
ssh admin@unifi "mca-cli-op dump ap | grep -E 'name|ip|mac'"

# Aruba: Listar APs activos
ssh admin@aruba "show ap active | grep -E 'AP Name|IP Address'"

# Cisco: Listar APs registrados
ssh admin@cisco "show ap summary | grep -E 'AP Name|IP Address'"

# Ver clientes conectados en todos los APs
for ap in ap01 ap02 ap03; do ssh admin@$ap "show station"; done

# Ver interferencia en todos los APs
for ap in ap01 ap02 ap03; do ssh admin@$ap "show interference"; done

# Reiniciar todos los APs de un piso
for ap in $(grep "piso1" /etc/ap-list.txt); do ssh admin@$ap "reboot"; done

# Capturar tráfico WiFi en modo monitor
sudo airmon-ng start wlan0 && sudo tcpdump -i mon0 -n -w /tmp/wifi.pcap
```

---

## 🔗 Referencias internas

- [`guides/network_segmentation.md`](network_segmentation.md) — VLANs y segmentación
- [`guides/ssh.md`](ssh.md) — acceso remoto a APs
- [`guides/tcpdump.md`](tcpdump.md) — captura de paquetes WiFi
