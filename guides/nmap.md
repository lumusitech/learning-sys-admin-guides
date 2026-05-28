# nmap — Guía completa

**Nivel:** 🔴 Avanzado
**Archivos de práctica:** Red local o contenedores Docker
**Ver escenarios relacionados:** [`networking/03-port-scan`](../scenarios/networking/03-port-scan-detection.md)

## ⚡ Quick command

`nmap -sT localhost`

## ⚡ Quick run

```bash
nmap -sS -T4 localhost
```

---

## Índice

1. [¿Qué es nmap?](#qué-es-nmap)
2. [Tipos de escaneo](#tipos-de-escaneo)
3. [Opciones principales](#opciones-principales)
4. [Detección de servicios y versiones](#detección-de-servicios-y-versiones)
5. [Detección de SO (OS Fingerprinting)](#detección-de-so-os-fingerprinting)
6. [Scripts NSE](#scripts-nse)
7. [Salida y formatos](#salida-y-formatos)
8. [Escenarios de red](#escenarios-de-red)
9. [Escenarios de seguridad](#escenarios-de-seguridad)
10. [Evasión de firewalls](#evasión-de-firewalls)
11. [Uno-liners imprescindibles](#uno-liners-imprescindibles)

---

## ¿Qué es nmap?

**nmap** (Network Mapper) descubre hosts y servicios en una red informática mediante el envío de paquetes y el análisis de las respuestas. Es la herramienta estándar para:

- **Descubrimiento de hosts**: qué dispositivos están en la red
- **Escaneo de puertos**: qué puertos están abiertos
- **Detección de versiones**: qué software y versión corre en cada puerto
- **Detección de SO**: qué sistema operativo tiene cada host
- **Scripts NSE**: automatización de tareas de red y seguridad

```bash
# Verificar instalación
nmap --version

# Escaneo básico
nmap 192.168.1.1
```

---

## Tipos de escaneo

| Tipo | Opción | Descripción |
|------|--------|-------------|
| **SYN scan** | `-sS` | Escaneo semi-abierto (por defecto como root). Rápido, sigiloso |
| **TCP connect** | `-sT` | Conexión completa. Cuando no eres root |
| **UDP scan** | `-sU` | Escanea puertos UDP |
| **FIN scan** | `-sF` | Envía paquetes FIN (evasión firewalls) |
| **Xmas scan** | `-sX` | Envía FIN+PSH+URG (evasión) |
| **Null scan** | `-sN` | Sin flags (evasión) |
| **Ping sweep** | `-sn` | Descubre hosts sin escanear puertos |
| **Version detection** | `-sV` | Detecta versiones de servicios |
| **OS detection** | `-O` | Detecta sistema operativo |
| **Aggressive** | `-A` | OS + version + scripts + traceroute |
| **Idle scan** | `-sI` | Escaneo usando zombie (muy sigiloso) |

### SYN scan (-sS) — el más usado

```bash
# SYN scan (requiere root)
sudo nmap -sS 192.168.1.1
```

Envía SYN, espera SYN-ACK (abierto) o RST (cerrado) o nada (filtrado). No completa el handshake TCP.

### TCP connect (-sT)

```bash
# TCP connect (sin root)
nmap -sT 192.168.1.1
```

Completa el handshake TCP. Más ruidoso, queda registrado en logs.

### UDP scan (-sU)

```bash
# UDP scan (lento, requiere root)
sudo nmap -sU 192.168.1.1
```

UDP no tiene handshake. Se basa en: sin respuesta = abierto/filtrado, ICMP unreachable = cerrado.

### FIN / Xmas / Null scan

```bash
# FIN: solo paquete FIN
sudo nmap -sF 192.168.1.1

# Xmas: FIN+PSH+URG
sudo nmap -sX 192.168.1.1

# Null: sin flags
sudo nmap -sN 192.168.1.1
```

Windows responde con RST a todos (no funciona). Linux/Unix ignora → puerto abierto, RST → cerrado.

### Ping sweep (-sn)

```bash
# Descubrir hosts activos en la subred (sin escanear puertos)
nmap -sn 192.168.1.0/24

# Sin resolver nombres (más rápido)
nmap -sn -n 192.168.1.0/24
```

---

## Opciones principales

| Opción | Descripción |
|--------|-------------|
| `-p N` | Puerto(s) a escanear (ej: `-p 22,80,443`, `-p-` = todos) |
| `-p N-N` | Rango de puertos (ej: `-p 1-1000`) |
| `--top-ports N` | Escanea los N puertos más comunes |
| `-n` | No resolver nombres DNS |
| `-R` | Resolver nombres DNS (por defecto para hosts) |
| `-Pn` | Saltar descubrimiento de host (asume que está vivo) |
| `-PS` | SYN ping (descubrimiento de hosts) |
| `-PA` | ACK ping |
| `-PE` | ICMP echo ping |
| `-PP` | ICMP timestamp ping |
| `-PM` | ICMP netmask ping |
| `-PO` | IP protocol ping |
| `-PR` | ARP ping (LAN, el más rápido) |
| `-T N` | Timing template (0-5): Paranoid, Sneaky, Polite, Normal, Aggressive, Insane |
| `--min-rate N` | Velocidad mínima de paquetes/segundo |
| `--max-rate N` | Velocidad máxima de paquetes/segundo |
| `--open` | Solo mostrar puertos abiertos |
| `--reason` | Mostrar por qué nmap determinó el estado |
| `--packet-trace` | Mostrar cada paquete enviado/recibido |
| `--disable-arp-ping` | No usar ARP ping |
| `-g puerto` | Puerto origen (spoofing de puerto) |

### -p: selección de puertos

```bash
# Puertos específicos
nmap -p 22,80,443 192.168.1.1

# Rango
nmap -p 1-1000 192.168.1.1

# Todos los puertos (65535) — lento
nmap -p- 192.168.1.1

# Puertos más comunes (top 100)
nmap --top-ports 100 192.168.1.1

# Servicios por nombre
nmap -p http,https,ssh 192.168.1.1

# Por protocolo
nmap -p T:80,U:53 192.168.1.1
```

### -T: plantillas de timing

| Template | Opción | Velocidad | Uso |
|----------|--------|-----------|-----|
| Paranoid | `-T0` | Muy lenta | Evasión de IDS (serial, 5min entre paquetes) |
| Sneaky | `-T1` | Lenta | Evasión sigilosa |
| Polite | `-T2` | Moderada | Menos ancho de banda, redes compartidas |
| Normal | `-T3` | Normal | Por defecto |
| Aggressive | `-T4` | Agresiva | Redes rápidas, escaneos típicos |
| Insane | `-T5` | Muy agresiva | Redes muy rápidas, puede perder paquetes |

```bash
# Escaneo rápido (recomendado para redes rápidas)
sudo nmap -T4 -sS 192.168.1.1

# Escaneo sigiloso (evasión IDS)
sudo nmap -T1 -sS 192.168.1.1

# Escaneo insano (máxima velocidad)
sudo nmap -T5 --max-retries 1 192.168.1.1
```

### -Pn: saltar ping

```bash
# Escanear aunque el host no responda ping
nmap -Pn 192.168.1.1
# Útil cuando el firewall bloquea ICMP pero los puertos están abiertos
```

---

## Detección de servicios y versiones (-sV)

### -sV

```bash
# Detectar versiones de servicios
sudo nmap -sV 192.168.1.1

# Más agresivo en detección
sudo nmap -sV --version-intensity 9 192.168.1.1

# Menos agresivo (más rápido)
sudo nmap -sV --version-intensity 0 192.168.1.1

# Light (solo probar puertos abiertos comunes)
sudo nmap -sV --version-light 192.168.1.1
```

Salida típica:

```text
PORT     STATE SERVICE  VERSION
22/tcp   open  ssh      OpenSSH 8.9p1 Ubuntu 3
80/tcp   open  http     Apache httpd 2.4.57
443/tcp  open  ssl/http Apache httpd 2.4.57
3306/tcp open  mysql    MySQL 8.0.35
```

### -A (aggressive)

Combina: OS detection + version detection + scripts + traceroute.

```bash
# Escaneo agresivo completo
sudo nmap -A 192.168.1.1

# Equivale a: -O -sV -sC --traceroute
```

---

## Detección de SO (OS Fingerprinting)

### -O

```bash
# Detectar sistema operativo
sudo nmap -O 192.168.1.1

# Con mayor precisión
sudo nmap -O --osscan-guess 192.168.1.1
```

Salida típica:

```text
Device type: general purpose
Running: Linux 5.X
OS CPE: cpe:/o:linux:linux_kernel:5
OS details: Linux 5.4 - 5.15
Network Distance: 2 hops
```

### OS detection en múltiples hosts

```bash
# Detectar SO en toda la subred
sudo nmap -O 192.168.1.0/24 --osscan-limit
```

---

## Scripts NSE (Nmap Scripting Engine)

### -sC (default scripts)

```bash
# Scripts por defecto
sudo nmap -sC 192.168.1.1
```

### --script

```bash
# Script específico
sudo nmap --script http-headers 192.168.1.1

# Categorías
sudo nmap --script "default" 192.168.1.1
sudo nmap --script "safe" 192.168.1.1
sudo nmap --script "vuln" 192.168.1.1
sudo nmap --script "exploit" 192.168.1.1
sudo nmap --script "auth" 192.168.1.1
sudo nmap --script "brute" 192.168.1.1
sudo nmap --script "discovery" 192.168.1.1

# Múltiples categorías
sudo nmap --script "default or safe" 192.168.1.1

# Excluir categorías
sudo nmap --script "not intrusive" 192.168.1.1

# Scripts personalizados
sudo nmap --script /ruta/mis-scripts.nse 192.168.1.1
```

### Scripts útiles

```bash
# HTTP security headers
sudo nmap --script http-security-headers -p 80,443 192.168.1.1

# HTTP methods (OPTIONS)
sudo nmap --script http-methods -p 80,443 192.168.1.1

# Detectar SQL injection básico
sudo nmap --script http-sql-injection -p 80 192.168.1.1

# Detectar XSS
sudo nmap --script http-xssed -p 80 192.168.1.1

# Enumerar directorios web
sudo nmap --script http-enum -p 80 192.168.1.1

# Verificar si soporta HTTP TRACE (XST attack)
sudo nmap --script http-trace -p 80 192.168.1.1

# Detectar slowloris DoS
sudo nmap --script http-slowloris-check -p 80 192.168.1.1

# Certificado SSL
sudo nmap --script ssl-cert -p 443 192.168.1.1

# Heartbleed (CVE-2014-0160)
sudo nmap --script ssl-heartbleed -p 443 192.168.1.1

# Logjam (CVE-2015-4000)
sudo nmap --script ssl-dh-params -p 443 192.168.1.1

# SMB vulnerabilities
sudo nmap --script smb-vuln-* -p 445 192.168.1.1

# NetBIOS enumeration
sudo nmap --script nbstat -p 137 192.168.1.1

# DNS zone transfer
sudo nmap --script dns-zone-transfer -p 53 ns1.ejemplo.com

# SSH enumeration
sudo nmap --script ssh2-enum-algos -p 22 192.168.1.1
```

### Argumentos de scripts

```bash
# Pasar argumentos a scripts
sudo nmap --script http-enum --script-args http-enum.fingerprintfile=./my-fingerprints.txt 192.168.1.1

# Lista de argumentos
sudo nmap --script http-title --script-args http.title.maxlen=100 192.168.1.1
```

### Listar scripts disponibles

```bash
# Todos los scripts
ls /usr/share/nmap/scripts/

# Buscar script por palabra clave
ls /usr/share/nmap/scripts/ | grep http

# Buscar por categoría
grep -l 'categories.*vuln' /usr/share/nmap/scripts/*.nse
```

---

## Salida y formatos

### -oN (normal), -oX (XML), -oG (grepable), -oA (todos)

```bash
# Salida normal
nmap -oN escaneo.txt 192.168.1.1

# Salida XML (para parsear con herramientas o programas)
nmap -oX escaneo.xml 192.168.1.1

# Salida grepable (para usar con grep/awk)
nmap -oG escaneo.gnmap 192.168.1.1

# Todos los formatos
nmap -oA escaneo 192.168.1.1
```

### -v (verboso), -d (debug)

```bash
# Verboso
nmap -v 192.168.1.1

# Muy verboso
nmap -vv 192.168.1.1

# Debug
nmap -d 192.168.1.1
```

---

## Escenarios de red

### 1. Descubrir todos los hosts en la red local

```bash
# Ping sweep completo
nmap -sn 192.168.1.0/24

# Más rápido: ARP scan (solo LAN)
sudo nmap -sn -PR 192.168.1.0/24

# Sin resolver nombres
nmap -sn -n 192.168.1.0/24

# Listar solo hosts vivos
nmap -sn -n 192.168.1.0/24 | grep "Nmap done" -B 100 | grep "report"
```

### 2. Escanear puertos abiertos de un servidor

```bash
# Puertos comunes (rápido)
nmap --top-ports 1000 -sS 192.168.1.1

# Todos los puertos (completo)
sudo nmap -p- -sS 192.168.1.1

# TCP y UDP
sudo nmap -sS -sU --top-ports 100 192.168.1.1
```

### 3. Detectar servicios y versiones

```bash
# Versiones de servicios en puertos abiertos
sudo nmap -sV -p 22,80,443,3306 192.168.1.1

# Escaneo completo con versiones
sudo nmap -sS -sV -O 192.168.1.1
```

### 4. Escaneo de toda la red con servicios

```bash
# Red completa: hosts vivos + puertos + versiones
sudo nmap -sS -sV -T4 192.168.1.0/24

# Red completa: más detalle
sudo nmap -A -T4 192.168.1.0/24
```

---

## Escenarios de seguridad

### 1. Detectar puertos abiertos no autorizados

```bash
# Escanear un servidor y buscar puertos inesperados
sudo nmap -sS -p- servidor

# Comparar con escaneo anterior (detección de cambios)
# Usar diff sobre salidas XML o grepable
nmap -oG antes.gnmap servidor
# ... tiempo después ...
nmap -oG despues.gnmap servidor
diff antes.gnmap despues.gnmap
```

### 2. Detectar servidores con servicios vulnerables

```bash
# Escanear red y buscar versiones vulnerables
sudo nmap -sV --script vuln 192.168.1.0/24

# Heartbleed
sudo nmap -sV --script ssl-heartbleed -p 443 192.168.1.0/24

# SMB vulnerabilities (EternalBlue, WannaCry)
sudo nmap --script smb-vuln-* -p 445 192.168.1.0/24
```

### 3. Detectar sistemas operativos

```bash
# OS fingerprinting de toda la red
sudo nmap -O 192.168.1.0/24

# Dispositivos no identificados (IoT, routers, etc.)
sudo nmap -O -osscan-guess 192.168.1.0/24 | grep "OS details"
```

### 4. Auditoría de firewall

```bash
# Ver qué puertos están filtrados
sudo nmap -sS -p 1-1000 192.168.1.1

# Probar evasión de firewall
sudo nmap -sS -f -D 10.0.0.1,10.0.0.2 192.168.1.1
```

### 5. Detectar servicios con scripts NSE

```bash
# Enumeración completa
sudo nmap -sC 192.168.1.1

# http-enum: directorios web comunes
sudo nmap --script http-enum -p 80 192.168.1.1

# DNS enumeration
sudo nmap --script dns-brute --script-args dns-brute.domain=ejemplo.com
```

---

## Evasión de firewalls

### Fragmentación (-f)

```bash
# Fragmentar paquetes (evasión de filtros simples)
sudo nmap -f 192.168.1.1

# Fragmentación con tamaño específico
sudo nmap --mtu 24 192.168.1.1
```

### Decoy (-D)

```bash
# IPs señuelo (aparentar que el escaneo viene de varias IPs)
sudo nmap -D 10.0.0.1,10.0.0.2,10.0.0.3 192.168.1.1

# Señuelo aleatorio (RND:N)
sudo nmap -D RND:5 192.168.1.1

# Me: incluir tu IP real entre señuelos
sudo nmap -D decoy1,decoy2,ME 192.168.1.1
```

### Source port (-g)

```bash
# Cambiar puerto origen (a veces puertos como 53, 20, 80 pasan firewalls)
sudo nmap -g 53 192.168.1.1
sudo nmap --source-port 53 192.168.1.1
```

### Spoof MAC

```bash
# Cambiar MAC origen
sudo nmap --spoof-mac 00:11:22:33:44:55 192.168.1.1

# MAC aleatoria
sudo nmap --spoof-mac 0 192.168.1.1

# MAC de marca específica
sudo nmap --spoof-mac Apple 192.168.1.1
```

### Timing lento

```bash
# Escaneo extremadamente lento (evasión IDS)
sudo nmap -T0 --max-rate 1 192.168.1.1
```

### Idle scan (zombie)

```bash
# Escaneo usando zombie (no dejas tu IP en los logs del objetivo)
sudo nmap -sI zombie_ip 192.168.1.1
```

---

## Interpretación de estados de puertos

| Estado | Significado |
|--------|-------------|
| `open` | Puerto abierto, servicio aceptando conexiones |
| `closed` | Puerto cerrado, no hay servicio escuchando |
| `filtered` | Firewall bloquea (no se sabe si está abierto o cerrado) |
| `unfiltered` | Accesible (solo en ACK scan) pero no se sabe si abierto/cerrado |
| `open\|filtered` | No se puede determinar si está abierto o filtrado (común en UDP) |
| `closed\|filtered` | No se puede determinar si está cerrado o filtrado (IP ID idle) |

---

## Uno-liners imprescindibles

```bash
# Descubrir hosts en la red local
nmap -sn 192.168.1.0/24

# Escaneo rápido de puertos comunes
sudo nmap -sS --top-ports 1000 192.168.1.1

# Todos los puertos
sudo nmap -p- -sS 192.168.1.1

# Servicios y versiones
sudo nmap -sV 192.168.1.1

# OS detection
sudo nmap -O 192.168.1.1

# Full scan (OS + version + scripts)
sudo nmap -A 192.168.1.1

# Escaneo sigiloso (lento)
sudo nmap -T1 -sS 192.168.1.1

# Escaneo rápido
sudo nmap -T4 -sS 192.168.1.1

# UDP scan (puertos comunes)
sudo nmap -sU --top-ports 100 192.168.1.1

# Scripts por defecto
sudo nmap -sC 192.168.1.1

# Scripts de vulnerabilidades
sudo nmap --script vuln 192.168.1.1

# Firewall detection
sudo nmap -sA 192.168.1.1

# Fragmentación (evasión)
sudo nmap -f 192.168.1.1

# Señuelos
sudo nmap -D RND:10 192.168.1.1

# Escaneo con zombie
sudo nmap -sI zombie_ip 192.168.1.1

# Red completa con versiones
sudo nmap -sS -sV -T4 192.168.1.0/24

# Detectar Heartbleed
sudo nmap --script ssl-heartbleed -p 443 servidor

# HTTP enumeration
sudo nmap --script http-enum -p 80 192.168.1.1

# Salida grepable
nmap -oG - 192.168.1.1 | grep "Ports"

# Lista de IPs vivas (para scripts)
nmap -sn -n 192.168.1.0/24 | grep "Nmap scan" | awk '{print $5}' > hosts.txt
```
