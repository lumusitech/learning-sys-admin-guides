# 🔍 Dahua — Descubrir dispositivos en la red

**Nivel:** 🟢 Básico
**Herramientas:** `nmap`, `arp-scan`, `curl`, `dnsmasq`

---

## ⚡ Quick command

```bash
sudo nmap -sU -p 37777 192.168.1.0/24
```

---

## 🧠 ¿Por qué es necesario?

Las cámaras Dahua vienen con IP por defecto `192.168.1.108`. Si tu red es distinta (lo más probable), no podrás alcanzarlas hasta que sepas qué IP tienen.

También: en instalaciones grandes (50+ cámaras), es común perder el registro de cuál cámara tiene cada IP. El discovery desde terminal es la única forma eficiente de auditar la red.

---

## 📋 Método 1: Puerto Dahua propietario (37777)

Dahua usa el puerto TCP/UDP 37777 para su protocolo de comunicación.

```bash
# UDP scan (rápido, detecta la mayoría)
sudo nmap -sU -p 37777 192.168.1.0/24

# TCP scan (alternativa)
sudo nmap -sT -p 37777 192.168.1.0/24

# Con detección de versión (más info)
sudo nmap -sU -p 37777 --script=dahua-info 192.168.1.0/24
```

**Salida esperada:**

```text
Nmap scan report for 192.168.1.108
Host is up (0.0082s latency).
PORT      STATE         SERVICE
37777/udp open|filtered dahua-discovery

Nmap scan report for 192.168.1.50
Host is up (0.0031s latency).
PORT      STATE         SERVICE
37777/udp open|filtered dahua-discovery
```

---

## 📋 Método 2: ONVIF Discovery (puerto 3702)

Todas las cámaras Dahua modernas soportan ONVIF. El puerto de discovery es 3702 UDP.

```bash
# Discovery ONVIF broadcast
sudo nmap -sU -p 3702 192.168.1.0/24

# Con script NSE específico
sudo nmap -sU -p 3702 --script=onvif-info 192.168.1.0/24
```

**Ventaja:** Detecta cualquier marca, no solo Dahua (Hikvision, Uniview, Axis, etc.)

---

## 📋 Método 3: DHCP Logs

Si tu servidor Linux es el que da DHCP (con dnsmasq o isc-dhcp-server), los logs te muestran cada cámara que pide IP:

```bash
# Ver solicitudes DHCP recientes (asignaciones)
grep DHCPACK /var/log/syslog | tail -20

# Ver solicitudes DHCP de un rango de IPs (cámaras)
grep DHCPACK /var/log/syslog | grep "192.168.100" | tail -50

# Formato: DHCPACK on 192.168.1.1 to 3e:f7:fb:b6:13:24 via eth0
# La MAC identifica al fabricante (Dahua = 9C:EB:xx:xx:xx:xx)
```

**Fabricantes por MAC (OUI):**

| Fabricante | OUI |
|------------|-----|
| Dahua | 9C:EB, 54:BF |
| Hikvision | A4:F3, 88:67 |
| Uniview | 68:C4 |

---

## 📋 Método 4: ARP scan (solo LAN)

```bash
# ARP scan rápido (no requiere nmap)
sudo arp-scan --localnet | grep -iE "dahua|hikvision|9c:eb|54:bf"

# O con nmap
sudo nmap -sn 192.168.1.0/24
# Luego mirar la tabla ARP
arp -a
```

---

## 📋 Método 5: Consultar servidor DHCP del router

Si el router es Linux, puedes consultar el archivo de leases:

```bash
# dnsmasq leases
cat /var/lib/misc/dnsmasq.leases

# isc-dhcp-server leases
cat /var/lib/dhcp/dhcpd.leases

# Formato: 1722345678 9c:eb:xx:xx:xx:xx 192.168.100.50 CAMARA-PORTON *
```

---

## 📋 Método 6: HTTP probe (rápido, sin nmap)

Si conoces un rango de IPs posible, puedes hacer un curl masivo:

```bash
#!/bin/bash
# Probar IPs del 1 al 254 en busca de interfaz web Dahua
for i in $(seq 1 254); do
  IP="192.168.100.$i"
  curl -s -m 1 "http://$IP/cgi-bin/magicBox.cgi?action=getSystemInfo" \
    | grep -q "deviceName" && echo "✅ Dahua detectada en $IP"
done
```

---

## 💡 Uno-liners

```bash
# Descubrir cámaras Dahua por puerto propietario
sudo nmap -sU -p 37777 192.168.1.0/24

# Descubrir por ONVIF
sudo nmap -sU -p 3702 192.168.1.0/24

# Listar todas las IPs con MAC Dahua desde leases DHCP
grep -i "9c:eb\|54:bf" /var/lib/misc/dnsmasq.leases | awk '{print $3, $4}'

# Escaneo rápido con sólo curl
for i in $(seq 1 254); do curl -s -m 0.5 http://192.168.100.$i:80 >/dev/null && echo "Host up: $i"; done
```

---

## 🔗 Ver también

- [`dahua-camera-api.md`](dahua-camera-api.md) — una vez descubierta, consultarla
- [`dahua-mass-config.md`](dahua-mass-config.md) — configurar muchas a la vez
- [`../nmap.md`](../nmap.md) — guía completa de nmap
