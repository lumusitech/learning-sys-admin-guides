# ip y ss — Guía completa de redes

**Nivel:** 🟢 Básico
**Archivos de práctica:** Sistema en vivo
**Ver escenarios relacionados:** [`networking/03-port-scan`](../scenarios/networking/03-port-scan-detection.md), [`infrastructure/02-build-pyme`](../scenarios/infrastructure/02-build-pyme-infrastructure.md)

## ⚡ Quick command

`ip addr show`

## ⚡ Quick run

```bash
ip addr show && ss -tuln
```

---

## 📑 Índice

1. [¿Qué son ip y ss?](#qué-son-ip-y-ss)
2. [ip link — Interfaces de red](#ip-link--interfaces-de-red)
3. [ip addr — Direcciones IP](#ip-addr--direcciones-ip)
4. [ip route — Tabla de rutas](#ip-route--tabla-de-rutas)
5. [ip neigh — Tabla ARP](#ip-neigh--tabla-arp)
6. [ip netns — Namespaces de red](#ip-netns--namespaces-de-red)
7. [ip maddr — Multicast](#ip-maddr--multicast)
8. [ss — Socket statistics](#ss--socket-statistics)
9. [Escenarios: diagnóstico conectividad](#escenarios-diagnóstico-conectividad)
10. [Escenarios: seguridad y ataques](#escenarios-seguridad-y-ataques)
11. [Comparación: comandos antiguos vs modernos](#comparación-comandos-antiguos-vs-modernos)
12. [Uno-liners imprescindibles](#uno-liners-imprescindibles)

---

## ¿Qué son ip y ss?

**ip** (iproute2) es la herramienta moderna para configurar y mostrar interfaces de red, direcciones IP, rutas, vecinos ARP, y mucho más. Reemplaza a `ifconfig`, `route`, `arp`, `netstat -r`, etc.

**ss** (socket statistics) muestra información sobre sockets del sistema. Reemplaza a `netstat` y es mucho más rápido y detallado.

```bash
# Verificar que iproute2 está instalado
ip -V
ss -V
```

---

## ip link — Interfaces de red

El comando `ip link` gestiona las **interfaces de red** (la capa de enlace).

### Mostrar interfaces

```bash
# Todas las interfaces
ip link show

# Resumen
ip -br link show

# Interfaz específica
ip link show eth0

# Solo interfaces UP (activas)
ip link show up

# Interfaces en detalle (estadísticas, colas, etc.)
ip -s link show eth0
ip -s -s link show eth0  # aún más detalle
```

### Columnas de `ip link show`

```text
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP mode DEFAULT group default qlen 1000
    link/ether 08:00:27:ab:cd:ef brd ff:ff:ff:ff:ff:ff
```

| Columna | Significado |
|---------|-------------|
| `1:` | Número de interfaz |
| `lo` | Nombre de la interfaz |
| `LOOPBACK,UP,LOWER_UP` | Flags: `UP`=activa, `LOWER_UP`=cable conectado, `BROADCAST`=soporta broadcast, `MULTICAST`=soporta multicast |
| `mtu 1500` | Maximum Transmission Unit (bytes) |
| `qdisc pfifo_fast` | Disciplina de cola (algoritmo de gestión de tráfico) |
| `state UP` | Estado operativo: `UP`, `DOWN`, `UNKNOWN` |
| `qlen 1000` | Longitud de la cola de transmisión |
| `link/ether` | Dirección MAC |
| `brd` | Dirección broadcast de la capa de enlace |

### Errores y estadísticas (-s)

```bash
# Ver errores de transmisión/recepción
ip -s link show eth0

# Enfoque en errores (para monitoreo)
ip -s -s link show eth0 | grep -E "error|drop|overrun|TX|RX"
```

| Estadística | Significado |
|-------------|-------------|
| `RX errors` | Errores al recibir (CRC, frame, length) |
| `RX dropped` | Paquetes recibidos pero no procesados (falta de buffers) |
| `RX overruns` | Paquetes perdidos por falta de espacio en el buffer |
| `TX errors` | Errores al transmitir (carrier, collisions) |
| `TX dropped` | Paquetes no transmitidos (cola llena) |
| `TX collisions` | Colisiones en la red (importante en half-duplex) |
| `carrier` | Pérdidas de señal/portadora |
| `missed` | Paquetes perdidos por hardware |

---

## Diagnóstico de link físico y PoE

### Verificar estado del enlace con ethtool

```bash
# Ver velocidad, duplex y estado del link
ethtool eth0 | grep -E "Speed|Duplex|Link"

# Salida esperada:
# Speed: 1000Mb/s
# Duplex: Full
# Link detected: yes

# Ver información completa
ethtool eth0

# Ver capacidades del enlace
ethtool eth0 | grep -A 10 "Supported link modes"
```

### Diagnóstico de PoE (Power over Ethernet)

```bash
# Verificar si la interfaz recibe energía PoE
# (requiere switch managed con SNMP o CLI)

# Con ethtool (si el switch lo soporta)
ethtool --show-eee eth0

# Con SNMP (si el switch lo soporta)
snmpwalk -v2c -c public switch_ip 1.3.6.1.2.1.105.1.3.1

# Ver consumo de energía por puerto (switch Ubiquiti)
ssh admin@switch "show poe detail"

# Ver consumo de energía por puerto (switch Cisco)
ssh admin@switch "show power inline"
```

### Diagnóstico de cables

```bash
# Ver errores de TX/RX (posible cable defectuoso)
ip -s link show eth0 | grep -A 5 "RX:\|TX:"

# Si hay errores crescentes, el cable puede estar defectuoso
watch -n 5 'ip -s link show eth0 | grep -E "errors|drop"'

# Ver mensajes del kernel sobre la interfaz
dmesg | grep eth0 | tail -20

# Verificar auto-negotiation
ethtool eth0 | grep -A 5 "Auto-negotiation"
```

### Problemas comunes de link

| Síntoma | Causa probable | Solución |
|---------|----------------|----------|
| Link down | Cable desconectado | Reconectar cable |
| Link up pero sin tráfico | Cable defectuoso | Reemplazar cable |
| Velocidad baja (100Mbps en vez de 1Gbps) | Cable Cat5 o inferior | Usar cable Cat5e o superior |
| Errores de CRC crescentes | Interferencia o cable dañado | Reemplazar cable, alejar de fuentes EMI |
| PoE no detectado | Injector defectuoso o cable largo | Verificar injector, cable <100m |

---

#### Interpretación de errores

| Síntoma | Posible causa |
|---------|---------------|
| `RX errors` altos en eth0 | Cable defectuoso, duplex mismatch, interferencia |
| `RX dropped` alto | Falta de memoria, valor de `rmem_max` bajo |
| `TX errors` altos | Problemas de cable, tarjeta de red defectuosa |
| `collisions` | En half-duplex: red congestionada |
| `carrier` | Cable desconectado, switch apagado |

### Modificar interfaces

```bash
# Activar/desactivar
ip link set eth0 up
ip link set eth0 down

# Cambiar MTU (ej: para Jumbo Frames 9000)
ip link set eth0 mtu 9000

# Cambiar dirección MAC (atención: puede ser spoofing)
ip link set eth0 address 00:11:22:33:44:55

# Cambiar nombre de interfaz (la interfaz debe estar DOWN)
ip link set eth0 down
ip link set eth0 name net0
ip link set net0 up

# Activar modo promiscuo (para capturar tráfico, como tcpdump)
ip link set eth0 promisc on

# Desactivar modo promiscuo
ip link set eth0 promisc off

# Activar/desactivar multicast
ip link set eth0 multicast on

# Activar/desactivar ARP
ip link set eth0 arp on
```

### Estadísticas de tráfico en tiempo real

```bash
# Watch de estadísticas
watch -n 2 'ip -s link show eth0'

# TX/RX en formato legible
ip -s -h link show eth0
```

---

## ip addr — Direcciones IP

### Mostrar direcciones

```bash
# Todas las direcciones
ip addr show

# Resumen (solo IP e interfaz)
ip -br addr show

# Solo IPv4
ip -4 addr show

# Solo IPv6
ip -6 addr show

# Interfaz específica
ip addr show eth0

# Direcciones IP de un tipo específico
ip addr show eth0 up
```

### Columnas de `ip addr show`

```text
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:ab:cd:ef brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.100/24 brd 192.168.1.255 scope global dynamic eth0
       valid_lft 86394sec preferred_lft 86394sec
    inet6 fe80::a00:27ff:feab:cdef/64 scope link
       valid_lft forever preferred_lft forever
```

| Columna | Significado |
|---------|-------------|
| `inet 192.168.1.100/24` | Dirección IPv4 + prefijo (CIDR) |
| `brd 192.168.1.255` | Dirección broadcast de la subred |
| `scope global` | Ámbito: `global` (accesible desde fuera), `host` (solo local), `link` (solo mismo enlace) |
| `dynamic` | Asignada por DHCP |
| `valid_lft` | Tiempo de vida válido de la concesión DHCP |
| `preferred_lft` | Tiempo de vida preferido (después, la IP sigue siendo válida pero no se usa para nuevas conexiones) |
| `inet6 fe80::...` | Dirección IPv6 link-local |
| `scope link` | IPv6 solo accesible en el mismo enlace físico |

### Añadir/Eliminar direcciones

```bash
# Añadir IP estática
ip addr add 192.168.1.50/24 dev eth0

# Añadir IP con broadcast explícito
ip addr add 192.168.1.50/24 brd 192.168.1.255 dev eth0

# Añadir IP secundaria (múltiples IPs en misma interfaz)
ip addr add 192.168.1.51/24 dev eth0

# Añadir IPv6
ip addr add 2001:db8::1/64 dev eth0

# Eliminar IP
ip addr del 192.168.1.50/24 dev eth0

# Flush (eliminar todas las IPs de una interfaz)
ip addr flush dev eth0
```

### Escenarios

```bash
# ¿Qué IP tengo?
ip -4 addr show | grep inet | awk '{print $2}'

# IP principal
hostname -I

# Verificar si una IP está configurada
ip addr show | grep -q "192.168.1.100" && echo "Configurada"
```

---

## ip route — Tabla de rutas

### Mostrar rutas

```bash
# Tabla de rutas completa
ip route show

# Solo la ruta por defecto (gateway)
ip route show default

# Rutas hacia una subred específica
ip route show 192.168.1.0/24

# Rutas por dispositivo
ip route show dev eth0

# En formato resumido
ip -br route show
```

### Columnas de `ip route show`

```text
default via 192.168.1.1 dev eth0 proto static metric 100
10.0.0.0/8 via 10.1.1.1 dev eth1 proto static metric 200
192.168.1.0/24 dev eth0 proto kernel scope link src 192.168.1.100 metric 100
```

| Columna | Significado |
|---------|-------------|
| `default` | Ruta por defecto (0.0.0.0/0) |
| `via 192.168.1.1` | Next-hop (gateway) |
| `dev eth0` | Interfaz de salida |
| `proto static` | Protocolo que añadió la ruta: `static` (manual), `kernel` (automática), `dhcp` |
| `metric 100` | Coste (menor = preferida) |
| `scope link` | Alcance: enlace directo, sin gateway |
| `src 192.168.1.100` | IP fuente preferida para tráfico hacia esta ruta |

### Añadir/Eliminar rutas

```bash
# Añadir ruta por defecto (gateway)
ip route add default via 192.168.1.1

# Añadir a un dispositivo específico
ip route add default via 192.168.1.1 dev eth0

# Añadir ruta estática
ip route add 10.0.0.0/8 via 10.1.1.1 dev eth1

# Añadir ruta con métrica
ip route add 10.0.0.0/8 via 10.1.1.1 metric 100

# Añadir ruta para un host específico (/32)
ip route add 8.8.8.8 via 192.168.1.1

# Eliminar ruta por defecto
ip route del default

# Eliminar ruta específica
ip route del 10.0.0.0/8

# Reemplazar ruta (atómico: añade o actualiza)
ip route replace default via 192.168.1.254
```

### Diagnóstico de routing

```bash
# Preguntar al kernel: ¿por dónde saldría el tráfico hacia X?
ip route get 8.8.8.8

# Respuesta típica:
# 8.8.8.8 via 192.168.1.1 dev eth0 src 192.168.1.100 uid 1000

# Con interfaz de origen específica
ip route get 8.8.8.8 from 192.168.1.100 iif eth0

# ¿Qué ruta se usa para llegar a una IP concreta?
ip route get 10.0.0.5
```

### Tablas de rutas múltiples (policy routing)

```bash
# Ver tablas de rutas disponibles
cat /etc/iproute2/rt_tables

# Mostrar tabla específica
ip route show table 100

# Añadir ruta en tabla específica
ip route add 10.0.0.0/8 via 10.1.1.1 table 100
```

---

## ip neigh — Tabla ARP/NDP

### Mostrar vecinos (ARP/NDP)

```bash
# Tabla ARP completa
ip neigh show

# Solo vecinos IPv4
ip -4 neigh show

# Solo IPv6 (NDP)
ip -6 neigh show

# Solo interfaz específica
ip neigh show dev eth0

# Solo vecinos reachables
ip neigh show nud reachable
```

### Columnas de `ip neigh show`

```text
192.168.1.1 dev eth0 lladdr 00:11:22:33:44:55 REACHABLE
192.168.1.2 dev eth0 lladdr aa:bb:cc:dd:ee:ff STALE
192.168.1.3 dev eth0 FAILED
```

| Columna | Significado |
|---------|-------------|
| `lladdr` | Dirección MAC (link-layer address) |
| `REACHABLE` | Confirmado alcanzable |
| `STALE` | No confirmado recientemente, pero probablemente válido |
| `DELAY` | Esperando confirmación |
| `PROBE` | Sondeando con unicast ARP |
| `FAILED` | No hubo respuesta, no alcanzable |
| `INCOMPLETE` | ARP enviado, esperando respuesta |
| `PERMANENT` | Entrada estática, nunca expira |

### Interpretación de estados ARP

| Estado | Escenario |
|--------|-----------|
| `REACHABLE` | Comunicación activa, todo normal |
| `STALE` | Hace >30s que no se confirma — el primer paquete hará transición a DELAY |
| `FAILED` | Host no responde — caída lógica, fuera de red, firewall bloquea |
| `INCOMPLETE` | Se envió ARP request pero no hay respuesta — IP no existe o host apagado |
| `PERMANENT` | Entrada manual — evita ARP spoofing (se usa para seguridad) |

### Modificar tabla ARP

```bash
# Añadir entrada ARP estática (protege contra ARP spoofing)
ip neigh add 192.168.1.1 lladdr 00:11:22:33:44:55 dev eth0 nud permanent

# Eliminar entrada ARP
ip neigh del 192.168.1.1 dev eth0

# Flush (vaciar) tabla ARP de una interfaz
ip neigh flush dev eth0

# Flush de todas las entradas
ip neigh flush all
```

---

## ip netns — Namespaces de red

Los namespaces permiten tener **pilas de red aisladas** en el mismo kernel. Cada namespace tiene sus propias interfaces, IPs, rutas, y reglas de firewall.

```bash
# Listar namespaces
ip netns list

# Crear namespace
ip netns add ns_servidor

# Ejecutar comando dentro de un namespace
ip netns exec ns_servidor ip addr show
ip netns exec ns_servidor ping 10.0.0.1

# Mover interfaz a un namespace
ip link set eth1 netns ns_servidor

# Conectar namespaces con veth pair
ip link add veth0 type veth peer name veth1
ip link set veth1 netns ns_servidor
ip addr add 10.0.0.1/24 dev veth0
ip netns exec ns_servidor ip addr add 10.0.0.2/24 dev veth1
ip link set veth0 up
ip netns exec ns_servidor ip link set veth1 up

# Eliminar namespace
ip netns delete ns_servidor
```

---

## ss — Socket Statistics

**ss** muestra información sobre sockets. Es el reemplazo moderno de `netstat` y es **mucho más rápido** porque lee directamente de las tablas del kernel.

### Uso básico

```bash
# Todos los sockets (TCP, UDP, UNIX, RAW)
ss

# Todos los puertos abiertos en escucha
ss -tuln

# Solo conexiones TCP establecidas
ss -t state established

# Conexiones con resolución de nombres
ss -r

# Compacto (solo PID, socket, estado)
ss -tlnp
```

### Opciones principales

| Opción | Significado |
|--------|-------------|
| `-t` | Solo TCP |
| `-u` | Solo UDP |
| `-w` | Solo RAW |
| `-x` | Solo UNIX sockets |
| `-a` | Todos (escucha + establecidos) |
| `-l` | Solo en escucha |
| `-n` | Sin resolución de nombres (IPs numéricas) |
| `-p` | Mostrar proceso (PID/Programa) |
| `-e` | Información extendida |
| `-o` | Información de temporizadores |
| `-m` | Información de memoria del socket |
| `-s` | Resumen estadístico |
| `-i` | Información detallada de TCP interna |
| `-4` | Solo IPv4 |
| `-6` | Solo IPv6 |
| `-D archivo` | Guardar en archivo (dump) |
| `-r` | Resolver nombres de host |
| `-A` | Familias de sockets a mostrar |

### ss -tuln (el más usado)

```bash
ss -tuln
# -t: TCP, -u: UDP, -l: listening (escucha), -n: numérico
```

Salida típica:

```text
Netid  State   Recv-Q  Send-Q  Local Address:Port   Peer Address:Port
tcp    LISTEN  0       128     0.0.0.0:22           0.0.0.0:*
tcp    LISTEN  0       128     127.0.0.1:3306       0.0.0.0:*
udp    LISTEN  0       128     0.0.0.0:5353         0.0.0.0:*
```

| Columna | Significado |
|---------|-------------|
| `Netid` | Protocolo (tcp, udp, raw, unix) |
| `State` | Estado del socket (LISTEN, ESTAB, TIME-WAIT, etc.) |
| `Recv-Q` | Bytes recibidos en cola (no leídos por la app) |
| `Send-Q` | Bytes enviados en cola (no confirmados por el peer) |
| `Local Address:Port` | IP y puerto local (`*` = todas las interfaces, `0.0.0.0` = todas las IPv4, `::` = todas las IPv6) |
| `Peer Address:Port` | IP y puerto remoto (`*` = cualquier) |

### ss -tulpn (con procesos)

```bash
# Qué proceso está escuchando en cada puerto
ss -tulpn

# Respuesta añade: users:(("sshd",pid=1234,fd=3))
```

### ss -s (resumen)

```bash
ss -s
# Total: 345 (kernel 442)
# TCP:   12 (estab 6, closed 0, orphaned 0, synrecv 0, timewait 0/0), ports 0
#
# Transport Total     IP        IPv6
# *   0        -         -
# RAW   0         0         0
# UDP   5         3         2
# TCP   12        8         4
# INET   17        11        6
# FRAG   0         0         0
```

### Estados TCP

ss permite filtrar por estado TCP:

```bash
# Conexiones establecidas
ss -t state established

# Conexiones en TIME_WAIT
ss -t state time-wait

# Conexiones en CLOSE_WAIT (el famoso "leak" de conexiones)
ss -t state close-wait

# Conexiones en SYN-SENT (intentos de conexión saliente)
ss -t state syn-sent

# Múltiples estados
ss -t state fin-wait-1 state fin-wait-2

# Conexiones en todos los estados excepto LISTEN y TIME_WAIT
ss -t state all

# Socket en estado específico con puerto
ss -t state time-wait sport = 443
ss -t state established dport = 80
```

| Estado TCP | Significado | Escenario |
|------------|-------------|-----------|
| `LISTEN` | Esperando conexiones entrantes | Servicio funcionando |
| `SYN-SENT` | Envió SYN, esperando SYN-ACK | Cliente intentando conectar (timeout si no hay respuesta) |
| `SYN-RECV` | Recibió SYN, respondió SYN-ACK, esperando ACK | Mitad de handshake |
| `ESTAB` | Conexión establecida | Comunicación activa |
| `FIN-WAIT-1` | Socket cerrado localmente, esperando ACK o FIN | Cierre de conexión |
| `FIN-WAIT-2` | Recibió ACK a su FIN, esperando FIN remoto | Esperando que el otro cierre |
| `TIME-WAIT` | Esperando paquetes tardíos (2MSL) | Socket cerrado, limpiando |
| `CLOSE-WAIT` | Recibió FIN remoto, esperando que la app local cierre | App no cierra el socket (leak) |
| `LAST-ACK` | Esperando ACK a su FIN | Última etapa de cierre |
| `CLOSING` | Cierre simultáneo | Ambos lados cerraron a la vez |
| `CLOSED` | Cerrado | Sin conexión |

#### El problema de CLOSE_WAIT

Un número alto de sockets en `CLOSE_WAIT` indica que la **aplicación no está cerrando los sockets** después de que el peer cierra la conexión. Es un bug de la aplicación que puede agotar los descriptores de archivo.

```bash
# Contar sockets CLOSE_WAIT
ss -t state close-wait | wc -l

# Detalles de los sockets en CLOSE_WAIT
ss -t state close-wait -p
```

### Filtrar por puerto e IP

```bash
# Puertos específicos
ss -t sport = :22
ss -t dport = :80 or dport = :443

# Rangos de puertos
ss -t sport = :http or sport = :https
ss -t dport :1024-65535

# IP de origen/destino
ss -t src 192.168.1.100
ss -t dst 10.0.0.1

# IP y puerto combinados
ss -t src 192.168.1.100 sport = :22
ss -t dst 10.0.0.1 dport = :80

# Conexiones a un rango de IPs
ss -t dst 10.0.0.0/24
```

### ss + watch (monitoreo en tiempo real)

```bash
# Conexiones activas cada 2 segundos
watch -n 2 'ss -t state established'

# Conexiones por estado en tiempo real
watch -n 1 'ss -s | head -5'

# Nuevas conexiones entrantes
watch -n 1 'ss -t state syn-recv'

# Conexiones TIME_WAIT (si suben mucho, hay problema)
watch -n 2 'ss -t state time-wait | wc -l'
```

### ss + grep para análisis

```bash
# Conexiones desde/hacia IP específica
ss -t | grep "192.168.1"

# Puertos no estándar en escucha
ss -tuln | grep -E '(:[0-9]+)' | awk '{print $5}' | sort -u

# Procesos que escuchan en puertos
ss -tulpn | grep -v "127.0.0.1" | grep LISTEN
```

---

## Escenarios: diagnóstico conectividad

### 1. Verificar que un servicio está escuchando

```bash
# ¿SSH está corriendo?
ss -tlnp | grep :22

# ¿Apache? (80/tcp)
ss -tlnp | grep :80

# ¿Base de datos? (mysql: 3306, postgres: 5432)
ss -tlnp | grep -E ':3306|:5432'

# R: Si no aparece, el servicio no está corriendo o escucha en otra interfaz/IP
```

### 2. Verificar conectividad básica

```bash
# ¿La interfaz está UP?
ip link show eth0 | grep "state UP"

# ¿Tiene IP?
ip addr show eth0 | grep "inet "

# ¿Tiene gateway?
ip route show default

# ¿Responde el gateway?
ping -c 1 $(ip route show default | awk '{print $3}')

# ¿Hay resolución DNS?
nslookup google.com  # o dig
```

### 3. Diagnóstico de latencia y pérdida de paquetes

```bash
# Estadísticas detalladas de interfaz
ip -s link show eth0

# Si "errors" > 0: posible problema físico
# Si "dropped" > 0: posible congestión/recursos

# Conexiones TCP con problemas (retransmisiones)
ss -i | grep -E "retrans|rtt|cwnd"
```

### 4. Detectar caída de servicio por puerto ocupado

```bash
# Error: "Address already in use"
ss -tlnp | grep :8080
# R: Proceso previo no liberó el puerto. Usar -p para ver el PID.

# Matar proceso que ocupa el puerto
ss -tlnp | grep ":8080" | awk -F',' '{print $2}' | tr -d 'pid='
kill -9 PID
```

### 5. Detectar servidor caído (desde otro nodo)

```bash
# No hay ruta al destino
ip route get 192.168.2.100
# R: El kernel no tiene ruta (o se cae la red)

# ARP incompleto: la IP no responde
ip neigh show 192.168.1.100 | grep -q INCOMPLETE && echo "No responde"
```

### 6. Diagnóstico de MTU problemas

```bash
# Ping con DF bit y tamaño creciente para detectar MTU
ping -M do -s 1472 8.8.8.8
# Si falla: hay un MTU menor en el camino (PMTUD)

# Ver MTU de interfaz
ip link show eth0 | grep mtu

# Ver MTU de la ruta efectiva
tracepath 8.8.8.8
```

---

## Escenarios: seguridad y ataques

### 1. Detectar puertos abiertos no autorizados

```bash
# Puertos en escucha (comparar con los servicios conocidos)
ss -tulnp

# Puertos no estándar (>1024) en escucha
ss -tuln | awk '$5 ~ /:[0-9]+/ && $5 !~ /:(22|80|443|53|25|3306|5432|6379|11211)$/'

# Backdoors típicos en altos puertos
ss -tuln | grep -E ':(4444|4445|1337|31337|6666|6667|6668|6669) '
```

### 2. Detectar escaneos de puertos

```bash
# Múltiples conexiones SYN-RECV desde misma IP (mitad de handshake)
ss -t state syn-recv | awk '{print $5}' | sort | uniq -c | sort -rn

# Múltiples conexiones TIME-WAIT desde misma IP
ss -t state time-wait | awk '{print $5}' | sort | uniq -c | sort -rn

# Conexiones a muchos puertos DIFERENTES desde la misma IP
ss -t dst :1-65535 | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn
```

### 3. Detectar ataques DDoS / flooding

```bash
# Conexiones simultáneas por IP (posible DDoS)
ss -t state established | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn | head -10

# SYN flood: muchas conexiones SYN-RECV
watch -n 1 'ss -t state syn-recv | wc -l'

# Conexiones en TIME-WAIT excesivas
watch -n 1 'ss -t state time-wait | wc -l'

# Muchas conexiones desde una sola IP
ss -t state established | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn | head -5

# Conexiones con puertos efímeros locales (>32768)
ss -t state established | awk '{print $4}' | cut -d: -f2 | awk '$1 > 32768' | wc -l
```

### 4. Detectar ARP spoofing / MITM

```bash
# Ver MAC duplicadas (ARP spoofing: dos IPs diferentes con misma MAC)
ip neigh show | awk '{print $3}' | sort | uniq -d

# Comparar ARP con la MAC real esperada
ip neigh show 192.168.1.1
# Verificar con la MAC física del router

# Entradas ARP estáticas (protección contra spoofing)
ip neigh add 192.168.1.1 lladdr 00:11:22:33:44:55 dev eth0 nud permanent
```

### 5. Detectar interfaces en modo promiscuo

```bash
# Interfaces en modo promiscuo (potencial sniffing)
ip link show | grep PROMISC

# Ver el flag PROMISC en la interfaz
ip -br link show | grep PROMISC
```

### 6. Detectar configuraciones inseguras

```bash
# IPs públicas en interfaces privadas
ip -4 addr show | grep -v -E '(127\.|10\.|172\.1[6-9]\.|172\.2[0-9]\.|172\.3[0-1]\.|192\.168\.|169\.254\.)'

# Interfaces sin IP que deberían tenerla
ip -br addr show | grep "DOWN"

# Rutas por defecto múltiples (posible tráfico asimétrico)
ip route show default | wc -l | awk '$1 > 1'
```

---

## Comparación: comandos antiguos vs modernos

| Antiguo (deprecated) | Moderno (iproute2) |
|----------------------|---------------------|
| `ifconfig` | `ip addr show`, `ip link show` |
| `ifconfig eth0 up` | `ip link set eth0 up` |
| `route -n` | `ip route show` |
| `netstat -r` | `ip route show` |
| `arp -a` | `ip neigh show` |
| `arp -d 192.168.1.1` | `ip neigh del 192.168.1.1 dev eth0` |
| `arp -s 192.168.1.1 MAC` | `ip neigh add 192.168.1.1 lladdr MAC dev eth0 nud permanent` |
| `nameif` | `ip link set eth0 name net0` |
| `iptunnel` | `ip tunnel` |
| `ipmaddr` | `ip maddr` |
| `netstat -i` | `ip -s link show` |
| `netstat -s` | `ss -s` |
| `netstat -tulpn` | `ss -tulpn` |

---

## 💡 Uno-liners imprescindibles

```bash
# Interfaces activas
ip -br link show | grep UP

# IPs configuradas
ip -br addr show | grep UP

# Gateway por defecto
ip route show default

# Ruta hacia una IP específica
ip route get 8.8.8.8

# Puertos en escucha
ss -tulpn

# Conexiones establecidas
ss -t state established

# Conexiones por IP (contar)
ss -t | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn

# Resumen de sockets
ss -s

# Ver errores de interfaz
ip -s link show eth0

# MACs de la red local
ip neigh show | grep REACHABLE

# Tabla ARP completa
ip neigh show

# Matar proceso por puerto
ss -tlnp | grep ":8080"
kill -9 $(ss -tlnp | grep ":8080" | grep -oP 'pid=\K[0-9]+')

# Watch de conexiones
watch -n 2 'ss -t state established | wc -l'

# Cuántas conexiones por puerto local
ss -t state established | awk '{print $4}' | cut -d: -f2 | sort | uniq -c | sort -rn

# Conexiones en CLOSE_WAIT (potencial leak)
ss -t state close-wait -p

# Detectar IPs con más conexiones
ss -t state established | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn | head -10

# Ver interfaces y sus IPs
for iface in $(ip -br link | awk '{print $1}'); do
  echo "$iface: $(ip -4 addr show $iface | grep inet | awk '{print $2}')"
done
```
