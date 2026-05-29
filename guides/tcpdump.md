# tcpdump — Guía completa

**Nivel:** 🔴 Avanzado
**Archivos de práctica:** `labs/tcpdump.txt`
**Ver escenarios relacionados:** [`networking/03-port-scan`](../scenarios/networking/03-port-scan-detection.md)

## ⚡ Quick command

`tcpdump -c 10 -i any`

## ⚡ Quick run

```bash
sudo tcpdump -i any -c 10 port 80
```

---

## 📑 Índice

1. [¿Qué es tcpdump?](#qué-es-tcpdump)
2. [Sintaxis básica](#sintaxis-básica)
3. [Opciones principales](#opciones-principales)
4. [Expresiones de filtro (BPF)](#expresiones-de-filtro-bpf)
5. [Salida y formato](#salida-y-formato)
6. [Capturar tráfico](#capturar-tráfico)
7. [Leer archivos de captura](#leer-archivos-de-captura)
8. [Escenarios normales](#escenarios-normales)
9. [Escenarios de ataque](#escenarios-de-ataque)
10. [Escenarios de falla](#escenarios-de-falla)
11. [Análisis avanzado](#análisis-avanzado)
12. [Combinación con otras herramientas](#combinación-con-otras-herramientas)
13. [Uno-liners imprescindibles](#uno-liners-imprescindibles)

---

## 🧠 ¿Qué es tcpdump?

**tcpdump** captura y analiza paquetes de red en la línea de comandos. Imprime el contenido de los paquetes que coinciden con una expresión (filtro BPF). Es la herramienta fundamental para diagnóstico de red, análisis de protocolos, y resolución de problemas de conectividad.

### Requisitos

```bash
# Ejecutar como root o con sudo (necesita permisos para capturar)
sudo tcpdump

# Verificar que está instalado
tcpdump --version
```

---

## 📝 Sintaxis básica

```bash
tcpdump [opciones] [expresión_filtro]
```

```bash
# Capturar todo en la interfaz por defecto
sudo tcpdump

# Capturar en interfaz específica
sudo tcpdump -i eth0

# Con filtro: solo tráfico HTTP
sudo tcpdump -i eth0 port 80

# Capturar N paquetes y salir
sudo tcpdump -c 10 -i eth0
```

---

## 🎛️ Opciones principales

### Opciones de captura

| Opción | Descripción |
|--------|-------------|
| `-i interfaz` | Interfaz a capturar (ej: `eth0`, `any` para todas) |
| `-c N` | Capturar N paquetes y salir |
| `-s N` | Capturar N bytes por paquete (snaplen). `0` = paquete completo (65535) |
| `-e` | Mostrar cabeceras de capa de enlace (MACs) |
| `-n` | No resolver nombres IP (solo números) |
| `-nn` | No resolver IPs NI puertos |
| `-v` | Verboso (más detalles de protocolo) |
| `-vv` | Muy verboso |
| `-vvv` | Extremadamente verboso |
| `-X` | Mostrar contenido en hex y ASCII |
| `-A` | Mostrar contenido en ASCII |
| `-xx` | Mostrar paquete completo en hex (incluyendo cabeceras) |
| `-q` | Modo silencioso (menos info) |

### Opciones de archivo

| Opción | Descripción |
|--------|-------------|
| `-w archivo.pcap` | Guardar captura en archivo (para análisis posterior) |
| `-r archivo.pcap` | Leer captura desde archivo |
| `-F archivo` | Leer filtro BPF desde archivo |
| `-C N` | Rotar archivos cada N megabytes (con -w) |
| `-W N` | Número máximo de archivos rotados |
| `-G N` | Rotar cada N segundos |

### Opciones de control

| Opción | Descripción |
|--------|-------------|
| `-p` | No poner interfaz en modo promiscuo |
| `-B N` | Tamaño del buffer de captura en KB |
| `-D` | Listar interfaces disponibles |
| `-L` | Mostrar tipos de enlace soportados |
| `-S` | Mostrar números de secuencia TCP absolutos |
| `-t` | No mostrar timestamp (tiempo) |
| `-tttt` | Timestamp con fecha completa |
| `-z cmd` | Comprimir archivos rotados con `-z gzip` |

### -D: listar interfaces

```bash
sudo tcpdump -D
# 1.eth0 [Up, Running]
# 2.lo [Up, Running, Loopback]
# 3.any (Pseudo-device that captures on all interfaces)
```

### -s: snaplen

```bash
# Capturar todo el paquete (recomendado para análisis completo)
sudo tcpdump -i eth0 -s 0

# Solo primeros 128 bytes (no verás payload completo)
sudo tcpdump -i eth0 -s 128
```

---

## Expresiones de filtro (BPF)

tcpdump usa el lenguaje de filtros **BPF** (Berkeley Packet Filter). Puedes filtrar por protocolo, dirección IP, puerto, flags TCP, etc.

### Filtros por protocolo

```bash
# Solo tráfico TCP
sudo tcpdump tcp

# Solo UDP
sudo tcpdump udp

# Solo ICMP
sudo tcpdump icmp

# Solo ARP
sudo tcpdump arp

# Solo IPv4
sudo tcpdump ip

# Solo IPv6
sudo tcpdump ip6
```

### Filtros por host/IP

```bash
# Tráfico desde/hacia una IP específica
sudo tcpdump host 192.168.1.1

# Solo tráfico DESDE una IP
sudo tcpdump src host 192.168.1.100

# Solo tráfico HACIA una IP
sudo tcpdump dst host 192.168.1.100

# Tráfico desde/hacia una red
sudo tcpdump net 192.168.1.0/24

# Tráfico que NO sea de una IP
sudo tcpdump not host 192.168.1.1
```

### Filtros por puerto

```bash
# Tráfico en un puerto específico
sudo tcpdump port 80

# Solo tráfico DESDE puerto fuente
sudo tcpdump src port 22

# Solo tráfico HACIA puerto destino
sudo tcpdump dst port 443

# Múltiples puertos
sudo tcpdump port 80 or port 443

# Rango de puertos
sudo tcpdump portrange 8000-9000

# Puertos de servicio por nombre (/etc/services)
sudo tcpdump port http   # 80
sudo tcpdump port ssh    # 22
```

### Filtros por flags TCP

```bash
# Paquetes SYN (inicio de conexión)
sudo tcpdump 'tcp[tcpflags] & tcp-syn != 0'

# Paquetes SYN-ACK
sudo tcpdump 'tcp[tcpflags] & tcp-syn != 0 and tcp[tcpflags] & tcp-ack != 0'

# Paquetes RST (reset, conexión rechazada)
sudo tcpdump 'tcp[tcpflags] & tcp-rst != 0'

# Paquetes FIN (cierre de conexión)
sudo tcpdump 'tcp[tcpflags] & tcp-fin != 0'

# Paquetes con flags SYN y RST (escaneo sospechoso)
sudo tcpdump 'tcp[tcpflags] & (tcp-syn|tcp-rst) != 0'

# Paquetes ACK
sudo tcpdump 'tcp[tcpflags] & tcp-ack != 0'

# Paquetes con URG flag
sudo tcpdump 'tcp[tcpflags] & tcp-urg != 0'

# Paquetes PSH (push data inmediatamente)
sudo tcpdump 'tcp[tcpflags] & tcp-push != 0'
```

### Filtros combinados (lógicos)

```bash
# AND: tráfico hacia 192.168.1.1 Y puerto 80
sudo tcpdump dst host 192.168.1.1 and port 80

# OR: tráfico en puerto 80 o 443
sudo tcpdump port 80 or port 443

# NOT: tráfico que NO sea SSH
sudo tcpdump not port 22

# Combinación compleja
sudo tcpdump -i eth0 'host 192.168.1.100 and (port 80 or port 443) and not arp'

# Tráfico entre dos IPs
sudo tcpdump 'host 192.168.1.1 and host 192.168.1.100'

# Tráfico excluyendo broadcast y multicast
sudo tcpdump 'not broadcast and not multicast'
```

### Filtros avanzados (BPF raw)

```bash
# Paquetes TCP con tamaño de ventana 0 (posible zero-window probe)
sudo tcpdump 'tcp[14:2] = 0'

# Paquetes SYN a puertos específicos
sudo tcpdump 'tcp[13] & 2 != 0 and dst port 22'

# Paquetes ICMP de tipo ECHO (ping request)
sudo tcpdump 'icmp[icmptype] = icmp-echo'

# Paquetes ICMP de tipo ECHO REPLY (ping response)
sudo tcpdump 'icmp[icmptype] = icmp-echoreply'

# ICMP unreachable
sudo tcpdump 'icmp[icmptype] = icmp-unreach'

# Paquetes con opciones IP (raro, potencial ataque)
sudo tcpdump 'ip[7] != 0'

# Detectar tráfico con payload vacío (SYN flood)
sudo tcpdump 'tcp[13] & 2 != 0 and tcp[13] & 16 == 0 and tcp[((tcp[12:1] & 0xf0) >> 2):4] = 0'
```

### Filtros por tamaño de paquete

```bash
# Paquetes pequeños (< 64 bytes, potencial ataque)
sudo tcpdump 'len < 64'

# Paquetes grandes (> 1000 bytes)
sudo tcpdump 'len > 1000'

# Paquetes menores de 68 bytes (cabecera IP mínima + TCP = 40 + 14)
sudo tcpdump 'less 68'

# Paquetes mayores a 100 bytes
sudo tcpdump 'greater 100'
```

---

## Salida y formato

### Formato básico TCP

```text
14:30:22.123456 IP 192.168.1.100.54321 > 93.184.216.34.80: Flags [S], seq 1234567890, win 65535, options [mss 1460], length 0
```

| Campo | Significado |
|-------|-------------|
| `14:30:22.123456` | Timestamp (hora:min:seg.microseg) |
| `IP` | Protocolo (IP, IP6, ARP, etc.) |
| `192.168.1.100.54321` | Origen: IP.puerto |
| `>` | Dirección del flujo |
| `93.184.216.34.80` | Destino: IP.puerto |
| `Flags [S]` | Flags TCP: `S`=SYN, `.`=ACK, `F`=FIN, `R`=RST, `P`=PSH, `U`=URG |
| `seq 1234567890` | Número de secuencia (relativo, o absoluto con -S) |
| `ack 1234567891` | Número de acuse de recibo |
| `win 65535` | Ventana de recepción (bytes) |
| `length 0` | Longitud del payload |

### Flags TCP en tcpdump

| Flag | Símbolo en tcpdump | Significado |
|------|---------------------|-------------|
| SYN | `S` | Inicio de conexión |
| ACK | `.` | Acuse de recibo |
| FIN | `F` | Fin de conexión |
| RST | `R` | Reset (rechazo/error) |
| PSH | `P` | Push (datos inmediatos) |
| URG | `U` | Urgente |
| SYN-ACK | `S.` | Sincronización + Acuse |
| FIN-ACK | `F.` | Cierre + Acuse |
| RST-ACK | `R.` | Reset + Acuse |

### Formato ARP

```text
14:30:22.123456 ARP, Request who-has 192.168.1.1 tell 192.168.1.100, length 46
14:30:22.123456 ARP, Reply 192.168.1.1 is-at 00:11:22:33:44:55, length 28
```

### Formato ICMP

```text
14:30:22.123456 IP 192.168.1.100 > 8.8.8.8: ICMP echo request, id 12345, seq 1, length 64
14:30:22.123456 IP 8.8.8.8 > 192.168.1.100: ICMP echo reply, id 12345, seq 1, length 64
```

### -X: contenido hex+ASCII

```text
0x0000:  4500 0054 1234 4000 4001 5678 c0a8 0164  E..T.4@.@.Vx...d
0x0010:  58b8 d822 0800 4a3f 0123 4567 4865 6c6c  X.."...J?#.EgHell
0x0020:  6f20 576f 726c 6421                      o.World!
```

---

## Capturar tráfico

### Captura básica

```bash
# Capturar todo en interfaz eth0, 5 paquetes
sudo tcpdump -c 5 -i eth0

# Capturar con más detalle (-v)
sudo tcpdump -c 5 -i eth0 -v

# Capturar con MACs (-e)
sudo tcpdump -c 5 -i eth0 -e

# Capturar con nombres de host resueltos (por defecto)
sudo tcpdump -c 5 -i eth0 -N
```

### Guardar capturas en archivo

```bash
# Guardar para análisis posterior (formato pcap)
sudo tcpdump -w captura.pcap -i eth0

# Capturar con rotación cada 100MB
sudo tcpdump -w captura.pcap -C 100 -i eth0

# Capturar con rotación cada hora
sudo tcpdump -w captura_%Y-%m-%d_%H:%M:%S.pcap -G 3600 -i eth0

# Capturar N paquetes y guardar
sudo tcpdump -c 1000 -w captura.pcap -i eth0
```

### Captura con buffer grande

```bash
# Aumentar buffer de captura (evita pérdidas en tráfico alto)
sudo tcpdump -B 4096 -i eth0 -w captura.pcap
```

---

## Leer archivos de captura

```bash
# Leer archivo pcap
sudo tcpdump -r captura.pcap

# Leer con filtro (los filtros se aplican sobre los datos guardados)
sudo tcpdump -r captura.pcap port 80

# Leer con formato detallado
sudo tcpdump -r captura.pcap -nnvvv

# Leer y extraer contenido ASCII
sudo tcpdump -r captura.pcap -A

# Leer solo cabeceras (rápido)
sudo tcpdump -r captura.pcap -q
```

---

## Escenarios normales

### 1. Verificar conectividad HTTP

```bash
# Capturar petición web completa
sudo tcpdump -i eth0 -c 20 -nn port 80 -A

# Ver el three-way handshake TCP
sudo tcpdump -i eth0 -c 3 -nn 'host 93.184.216.34 and port 80'
# 1. SYN (S)
# 2. SYN-ACK (S.)
# 3. ACK (.)
```

### 2. Verificar resolución DNS

```bash
# Capturar consulta DNS
sudo tcpdump -i eth0 -c 4 -nn port 53

# Salida típica exitosa:
# 14:30:22.123456 IP 192.168.1.100.54321 > 8.8.8.8.53: 12345+ A? google.com. (28)
# 14:30:22.123456 IP 8.8.8.8.53 > 192.168.1.100.54321: 12345 1/0/0 A 142.250.80.46 (44)
```

### 3. Verificar respuesta de ping (ICMP)

```bash
# Capturar ping
sudo tcpdump -i eth0 -c 4 -nn icmp
# En otra terminal: ping 8.8.8.8

# Salida típica exitosa:
# ICMP echo request, id 12345, seq 1, length 64
# ICMP echo reply, id 12345, seq 1, length 64
```

### 4. Monitorear intentos de conexión SSH

```bash
# Ver intentos de conexión SSH
sudo tcpdump -i eth0 -nn 'port 22 and tcp[tcpflags] & (tcp-syn) != 0'
```

### 5. Verificar que un servicio responde en un puerto

```bash
# Capturar tráfico hacia un servidor web
sudo tcpdump -i eth0 -nn 'host servidor-web and port 80'

# Con -A para ver el contenido de la respuesta HTTP
sudo tcpdump -i eth0 -nn -A 'host servidor-web and port 80'
```

---

## Escenarios de ataque

### 1. SYN Flood (DoS)

```bash
# Muchos SYN sin completar el handshake
sudo tcpdump -i eth0 -nn 'tcp[tcpflags] & tcp-syn != 0 and tcp[tcpflags] & tcp-ack == 0'

# Características:
# - Múltiples SYN de una IP (o varias IPs spoofeadas)
# - Sin ACK posterior
# - Puertos origen aleatorios
# - Dirección IP destino única (la víctima)

# Contar SYNs por IP
sudo tcpdump -i eth0 -nn -c 1000 'tcp[tcpflags] & (tcp-syn) != 0 and tcp[tcpflags] & tcp-ack == 0' 2>/dev/null | awk '{print $3}' | cut -d. -f1-4 | sort | uniq -c | sort -rn | head -10
```

### 2. Port Scan (nmap)

```bash
# SYN scan: paquetes SYN a múltiples puertos
sudo tcpdump -i eth0 -nn 'tcp[tcpflags] & tcp-syn != 0 and tcp[tcpflags] & tcp-ack == 0'

# Características:
# - Misma IP origen
# - Múltiples puertos destino diferentes
# - Sin tráfico de aplicación posterior
# - Conexiones en orden secuencial o aleatorio

# Detectar scan: misma IP preguntando por muchos puertos
sudo tcpdump -i eth0 -nn -c 1000 'tcp[tcpflags] & tcp-syn != 0' 2>/dev/null | awk '{print $3}' | cut -d. -f1-4 | sort | uniq -c | sort -rn

# NULL scan (flags = 0)
sudo tcpdump -i eth0 -nn 'tcp[13] == 0'

# FIN scan
sudo tcpdump -i eth0 -nn 'tcp[tcpflags] & tcp-fin != 0 and tcp[tcpflags] & tcp-syn == 0 and tcp[tcpflags] & tcp-rst == 0 and tcp[tcpflags] & tcp-psh == 0 and tcp[tcpflags] & tcp-ack == 0 and tcp[tcpflags] & tcp-urg == 0'

# Xmas scan (flags FIN + PSH + URG)
sudo tcpdump -i eth0 -nn 'tcp[13] & (tcp-fin|tcp-psh|tcp-urg) != 0 and tcp[13] & (tcp-syn|tcp-rst|tcp-ack) == 0'
```

### 3. ARP Spoofing (MITM)

```bash
# Detectar ARP reply no solicitados (gratuitous ARP)
sudo tcpdump -i eth0 -ne 'arp'

# Características:
# - Múltiples ARP reply de una misma MAC pero con IPs diferentes
# - Una misma IP aparece con diferentes MACs

# Detectar duplicados: misma IP, diferentes MACs
sudo tcpdump -i eth0 -ne -c 100 arp 2>/dev/null | grep -oP 'Is-at \K[0-9a-f:]+' | sort -u
# Si ves varias MACs para una misma IP, hay spoofing.

# Detectar si una MAC está mintiendo sobre su IP
sudo tcpdump -i eth0 -ne 'arp'
# Busca: "who-has 192.168.1.1 tell 192.168.1.100" — ¿192.168.1.100 es realmente el router?
```

### 4. DNS Spoofing / DDoS

```bash
# Respuestas DNS sospechosas (muchas respuestas de un servidor que no es el DNS)
sudo tcpdump -i eth0 -nn 'udp port 53'

# Respuestas DNS con IP interna para dominio externo (posible spoofing)
sudo tcpdump -i eth0 -nn -A 'udp port 53' | grep -E "Answers|10\.|192\.168"

# DNS amplification attack: respuestas muy grandes desde puerto 53
sudo tcpdump -i eth0 -nn 'len > 500 and udp port 53'
```

### 5. ICMP flood (Smurf attack)

```bash
# Muchos paquetes ICMP
sudo tcpdump -i eth0 -nn 'icmp'

# Ping of Death: ICMP fragmentado muy grande (>65535 bytes)
sudo tcpdump -i eth0 -nn 'icmp and len > 1400'
```

### 6. Detectar tráfico de comando y control (C2)

```bash
# Conexiones regulares a IPs sospechosas (puertos no estándar)
sudo tcpdump -i eth0 -nn 'not port 80 and not port 443 and not port 53 and not port 22'

# Tráfico en horarios inusuales (esto lo haces con un script)
sudo tcpdump -i eth0 -tttt -c 1000 | awk '{print $1}' | sort | uniq -c

# Conexiones a IPs en países no habituales (necesitas GeoIP)
```

---

## Escenarios de falla

### 1. Timeout de conexión (SYN sin respuesta)

```bash
# Ver SYNs no respondidos
sudo tcpdump -i eth0 -nn 'tcp[tcpflags] & tcp-syn != 0 and tcp[tcpflags] & tcp-ack == 0'

# Si ves el SYN salir PERO no hay SYN-ACK de vuelta:
# - Firewall bloqueando el puerto
# - Servicio caído
# - Ruta de retorno rota
# - ICMP administratively prohibited
```

### 2. Conexión rechazada (RST)

```bash
# Ver RST en respuesta (conexión rechazada)
sudo tcpdump -i eth0 -nn 'tcp[tcpflags] & tcp-rst != 0'

# Si ves RST inmediatamente después del SYN:
# - Puerto cerrado (servicio no corriendo)
# - Firewall rechazando activamente (iptables REJECT)
# - IP bloqueada en blacklist

# Si ves RST durante una conexión establecida:
# - Aplicación crash
# - Timeout
# - Peer cerró abruptamente
```

### 3. Problemas de MTU/fragmentación

```bash
# Ver paquetes fragmentados (flags [FP] o fragment offset != 0)
sudo tcpdump -i eth0 -nn 'ip[6] != 0 or ip[6:2] & 0x1fff != 0'

# PMTUD: ver ICMP "fragmentation needed" (type 3, code 4)
sudo tcpdump -i eth0 -nn 'icmp[icmptype] = 3 and icmp[icmpcode] = 4'

# Esto suele salir en enrutadores intermedios cuando hay un MTU menor
```

### 4. Pérdida de paquetes / retransmisiones

```bash
# Ver retransmisiones TCP (mismo SEQ visto más de una vez)
sudo tcpdump -i eth0 -nn 'tcp[tcpflags] & tcp-ack == 0 and tcp[tcpflags] & tcp-syn == 0'

# Duplicate ACK (el receptor pide retransmisión)
sudo tcpdump -i eth0 -nn 'tcp[tcpflags] & tcp-ack != 0 and tcp[tcpflags] & tcp-syn == 0'

# Si ves muchas retransmisiones:
# - Congestión de red
# - Enlace con errores (alta tasa de error)
# - Buffer overflow en switch/router
```

### 5. DNS no resuelve

```bash
# Capturar consulta DNS (sin respuesta)
sudo tcpdump -i eth0 -nn -c 5 'udp port 53'

# Si ves la consulta salir pero NO la respuesta:
# - DNS server caído o inalcanzable
# - Firewall bloqueando puerto 53
# - Respuesta demasiado grande (EDNS0 truncado)
# - Timeout de resolución

# Ver si hay respuesta con código de error (NOERROR pero sin respuesta)
sudo tcpdump -i eth0 -nn -A 'udp port 53' | grep -E "NXDOMAIN|SERVFAIL|REFUSED"
```

### 6. Broadcast storm (tormenta de broadcast)

```bash
# Ver muchos paquetes broadcast
sudo tcpdump -i eth0 -nn 'broadcast'

# Ver muchos ARP (posible loop)
sudo tcpdump -i eth0 -nn -c 100 'arp' | wc -l

# STP (Spanning Tree) loops
sudo tcpdump -i eth0 'stp'
```

### 7. DHCP falla

```bash
# Capturar negociación DHCP completa (4 pasos)
sudo tcpdump -i eth0 -nn 'udp port 67 or udp port 68'

# Flujo normal:
# 1. DISCOVER (cliente → broadcast)
# 2. OFFER (servidor → cliente)  
# 3. REQUEST (cliente → broadcast pidiendo la IP ofrecida)
# 4. ACK (servidor → cliente confirmando)

# Si ves DISCOVER pero no OFFER: servidor DHCP caído
# Si ves OFFER pero no REQUEST: otro servidor respondió primero
# Si ves REQUEST pero no ACK: servidor no puede asignar o NAK
```

### 8. Conexión lenta (TCP análisis de velocidad)

```bash
# Ver ventana TCP (window size) pequeña → receptor saturado
sudo tcpdump -i eth0 -nn 'tcp[tcpflags] & tcp-ack != 0' | grep -E 'win [0-9]+' | awk '{print $NF}' | sort -n | head

# Ver RTT (Round Trip Time) con seguimiento de números de secuencia
# Ventanas de 0 → zero-window probe (receiver buffer lleno)

# Ver SACK (Selective ACK) — segmentos perdidos
sudo tcpdump -i eth0 -nn -v 'tcp[tcpflags] & tcp-ack != 0' | grep -E 'sack|SACK'
```

---

## Análisis avanzado

### Captura con script para análisis posterior

```bash
# Capturar por tiempo y rotar
sudo tcpdump -G 3600 -w 'captura_%Y%m%d_%H%M%S.pcap' -i eth0 'port 80'

# Capturar solo cabeceras (sin payload) para ahorrar espacio
sudo tcpdump -s 96 -w cabeceras.pcap -i eth0
```

### Extraer payload de captura

```bash
# Extraer datos HTTP de una captura
sudo tcpdump -r captura.pcap -A port 80 | grep -E "GET|POST|HTTP/|Host:"

# Extraer consultas DNS
sudo tcpdump -r captura.pcap -nn port 53 | grep -oP 'A\? \K[^ ]+'

# Extraer direcciones IP únicas de una captura
sudo tcpdump -r captura.pcap -nn | grep -oP '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | sort -u

# Extraer flujos TCP (conversaciones)
sudo tcpdump -r captura.pcap -nn | awk '{print $3, $5}' | sort | uniq -c | sort -rn | head -20
```

### Estadísticas de captura

```bash
# Protocolos en la captura
sudo tcpdump -r captura.pcap -nn | awk '{print $2}' | sort | uniq -c | sort -rn

# Puertos destino más usados
sudo tcpdump -r captura.pcap -nn | awk '{print $5}' | grep -oP '\.\K[0-9]+$' | sort | uniq -c | sort -rn | head -10

# Conexiones SYN (intentos)
sudo tcpdump -r captura.pcap -nn 'tcp[tcpflags] & tcp-syn != 0 and tcp[tcpflags] & tcp-ack == 0' | wc -l
```

---

## 🛠️ Combinación con otras herramientas

### tcpdump + grep

```bash
# Filtrar salida de tcpdump con grep (capa adicional de filtro)
sudo tcpdump -i eth0 -A | grep -E "GET|POST|Host:"

# Buscar contenido específico en payload
sudo tcpdump -i eth0 -A | grep -i "password\|login\|admin"
```

### tcpdump + awk

```bash
# Contar tráfico por IP
sudo tcpdump -i eth0 -nn -c 1000 -t 2>/dev/null | awk '{print $3}' | cut -d. -f1-4 | sort | uniq -c | sort -rn | head -10

# Tráfico por puerto
sudo tcpdump -i eth0 -nn -c 1000 -t 2>/dev/null | awk '{print $5}' | cut -d: -f2 | sort | uniq -c | sort -rn | head -10
```

### tcpdump + tshark (Wireshark CLI)

```bash
# tshark tiene mejor soporte de decodificación de protocolos
sudo tcpdump -w captura.pcap -i eth0
tshark -r captura.pcap -Y "http.request" -T fields -e http.host -e http.request.uri
```

### tcpdump + ngrep (grep de red)

```bash
# ngrep busca patrones en el payload de paquetes
sudo ngrep "password" port 80
```

---

## 💡 Uno-liners imprescindibles

```bash
# Puertos en uso (escucha)
sudo tcpdump -i any 'tcp[tcpflags] & tcp-syn != 0 and tcp[tcpflags] & tcp-ack == 0'

# SYN flood detect
sudo tcpdump -i eth0 -nn -c 1000 'tcp[tcpflags] & tcp-syn != 0' | awk '{print $3}' | sort | uniq -c | sort -rn | head -10

# HTTP requests
sudo tcpdump -i eth0 -A port 80 | grep "GET\|POST\|Host:"

# HTTP responses
sudo tcpdump -i eth0 -A port 80 | grep "HTTP/"

# DNS queries
sudo tcpdump -i eth0 -nn port 53

# Errores de red
sudo tcpdump -i eth0 'icmp[icmptype] = 3'

# Tráfico entre dos hosts
sudo tcpdump -i eth0 'host 192.168.1.1 and host 192.168.1.100'

# Tráfico excluyendo una IP
sudo tcpdump -i eth0 not host 192.168.1.1

# Resumen de protocolos
sudo tcpdump -i eth0 -nn | awk '{print $2}' | sort | uniq -c | sort -rn

# Puertos destino
sudo tcpdump -i eth0 -nn | awk '{print $5}' | cut -d. -f5 | sort | uniq -c | sort -rn

# Capturar y guardar
sudo tcpdump -w captura.pcap -i eth0 -s 0

# Leer captura con filtro HTTP
sudo tcpdump -r captura.pcap -A port 80

# Ver timestamps con fecha
sudo tcpdump -tttt -r captura.pcap

# Ver MACs (-e)
sudo tcpdump -e -r captura.pcap

# Solo paquetes de broadcast
sudo tcpdump -i eth0 broadcast

# Solo tráfico no TCP/UDP/ICMP (raro)
sudo tcpdump -i eth0 'not tcp and not udp and not icmp'

# Ver resumen con conteo de paquetes
sudo tcpdump -i eth0 -c 100 -q | wc -l

# Watch de tráfico por minuto
watch -n 60 'sudo tcpdump -i eth0 -c 100 -t 2>/dev/null | wc -l'
```
