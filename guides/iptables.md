# iptables — Guía completa

**Nivel:** 🔴 Avanzado
**Archivos de práctica:** `labs/firewall.log`
**Ver escenarios relacionados:** [`networking/03-port-scan`](../scenarios/networking/03-port-scan-detection.md), [`infrastructure/02-build-pyme`](../scenarios/infrastructure/02-build-pyme-infrastructure.md)

**Quick command:** `iptables -L -n`

## ⚡ Quick run

```bash
iptables -L -v -n | head -10
```

---

## Índice
1. [¿Qué es iptables?](#qué-es-iptables)
2. [Conceptos fundamentales](#conceptos-fundamentales)
3. [Tablas y cadenas](#tablas-y-cadenas)
4. [Reglas: estructura](#reglas-estructura)
5. [Políticas por defecto](#políticas-por-defecto)
6. [Objetivos (targets)](#objetivos-targets)
7. [Módulos de coincidencia](#módulos-de-coincidencia)
8. [Reglas básicas](#reglas-básicas)
9. [NAT (Network Address Translation)](#nat-network-address-translation)
10. [Persistencia](#persistencia)
11. [Escenarios reales](#escenarios-reales)
12. [Escenarios de ataque y mitigación](#escenarios-de-ataque-y-mitigación)
13. [Diagnóstico y depuración](#diagnóstico-y-depuración)
14. [Uno-liners imprescindibles](#uno-liners-imprescindibles)

---

## ¿Qué es iptables?

**iptables** es el firewall del kernel de Linux (Netfilter). Gestiona **reglas** que determinan qué hacer con los paquetes que entran, salen o pasan por el sistema. Cada regla coincide con paquetes según criterios (IP, puerto, protocolo, interfaz, etc.) y ejecuta una **acción** (aceptar, rechazar, registrar, etc.).

### nftables — el sucesor

En sistemas modernos (Debian 10+, Ubuntu 20.04+, RHEL 9+), `nftables` reemplaza a iptables. Sin embargo, iptables sigue siendo ampliamente usado y muchos comandos `iptables` se traducen automáticamente a nftables mediante una capa de compatibilidad.

```bash
# Verificar si iptables está disponible
iptables --version

# En sistemas con nftables, iptables puede ser un wrapper
ls -la $(which iptables)
```

---

## Conceptos fundamentales

### Flujo de un paquete

```
→[PREROUTING]→[INPUT]→[PROCESO LOCAL]
→[PREROUTING]→[FORWARD]→[POSTROUTING]→
→[PROCESO LOCAL]→[OUTPUT]→[POSTROUTING]→
```

| Cadena (chain) | Tráfico | Tabla |
|----------------|---------|-------|
| `INPUT` | Paquetes entrantes al sistema | filter |
| `FORWARD` | Paquetes que atraviesan el sistema (routing) | filter |
| `OUTPUT` | Paquetes salientes del sistema | filter |
| `PREROUTING` | Paquetes antes de decidir ruta (DNAT) | nat |
| `POSTROUTING` | Paquetes después de decidir ruta (SNAT, MASQUERADE) | nat |

---

## Tablas y cadenas

### Tablas

| Tabla | Función | Cadenas |
|-------|---------|---------|
| `filter` | Filtrar paquetes (permitir/bloquear) | INPUT, FORWARD, OUTPUT |
| `nat` | Traducción de direcciones | PREROUTING, POSTROUTING, OUTPUT |
| `mangle` | Modificar cabeceras de paquetes | PREROUTING, INPUT, FORWARD, OUTPUT, POSTROUTING |
| `raw` | Exenciones de seguimiento de conexión | PREROUTING, OUTPUT |
| `security` | Etiquetado SELinux | INPUT, FORWARD, OUTPUT |

### Cadenas por tabla

```
               ┌─────────────────────────────────┐
               │         mangle / raw             │
               │         PREROUTING               │
               └──────────────┬──────────────────┘
                              │
               ┌──────────────▼──────────────────┐
               │           mangle                 │
               │           INPUT                  │
               ├──────────────────────────────────┤
               │           filter                 │
               │           INPUT                  │
               └──────────────┬──────────────────┘
                              │
                    ┌─────────▼─────────┐
                    │   PROCESO LOCAL   │
                    └─────────┬─────────┘
                              │
               ┌──────────────▼──────────────────┐
               │           mangle                 │
               │           OUTPUT                 │
               ├──────────────────────────────────┤
               │           nat                    │
               │           OUTPUT                 │
               ├──────────────────────────────────┤
               │           filter                 │
               │           OUTPUT                 │
               ├──────────────────────────────────┤
               │           mangle                 │
               │           POSTROUTING            │
               ├──────────────────────────────────┤
               │           nat                    │
               │           POSTROUTING            │
               └──────────────────────────────────┘
```

---

## Reglas: estructura

```bash
iptables [tabla] comando [cadena] [condiciones] -j TARGET
```

### Comandos principales

| Comando | Descripción |
|---------|-------------|
| `-A chain` | Añadir regla al **final** de la cadena |
| `-I chain [N]` | Insertar regla al **inicio** (o en posición N) |
| `-D chain` | Eliminar regla |
| `-R chain N` | Reemplazar regla en posición N |
| `-F [chain]` | Flush (eliminar todas las reglas de la cadena) |
| `-L [chain]` | Listar reglas |
| `-S [chain]` | Mostrar reglas en formato de comandos |
| `-P chain target` | Establecer política por defecto |
| `-N chain` | Crear nueva cadena (user-defined) |
| `-X [chain]` | Eliminar cadena definida por usuario |
| `-E old new` | Renombrar cadena |
| `-Z [chain]` | Resetear contadores |
| `-C chain` | Verificar si una regla coincide |

### Condiciones comunes

| Opción | Descripción | Ejemplo |
|--------|-------------|---------|
| `-s IP/MASK` | IP origen | `-s 192.168.1.0/24` |
| `-d IP/MASK` | IP destino | `-d 8.8.8.8` |
| `-p proto` | Protocolo (tcp, udp, icmp, all) | `-p tcp` |
| `--sport port` | Puerto origen | `--sport 1024:65535` |
| `--dport port` | Puerto destino | `--dport 80` |
| `-i iface` | Interfaz de entrada | `-i eth0` |
| `-o iface` | Interfaz de salida | `-o eth0` |
| `-m state` | Módulo de estado | `-m state --state NEW` |
| `-m conntrack` | Módulo de seguimiento | `-m conntrack --ctstate ESTABLISHED` |
| `!` | Negación | `-s ! 192.168.1.1` |

### -L: listar reglas

```bash
# Listar todas las reglas de la tabla filter
iptables -L

# Con números de línea (útil para borrar)
iptables -L --line-numbers

# Con más detalle (interfaces, puertos)
iptables -L -v

# Sin resolver nombres (más rápido)
iptables -L -n

# Formato de comandos (exportable)
iptables -S

# Tabla específica
iptables -t nat -L -n -v
```

### -F: flush

```bash
# Eliminar todas las reglas de la tabla filter
iptables -F

# Eliminar reglas de cadena específica
iptables -F INPUT

# Eliminar reglas de otra tabla
iptables -t nat -F
```

---

## Políticas por defecto

Las políticas determinan qué hacer con un paquete que no coincide con ninguna regla.

```bash
# Política por defecto: DROP (bloquear todo lo no explícito)
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Política por defecto: ACCEPT (permitir todo lo no explícito)
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# Ver políticas actuales
iptables -L | grep "Chain"
```

> **IMPORTANTE**: si pones DROP en INPUT por defecto y no tienes una regla que permita SSH antes, te quedas fuera del servidor. Siempre tener una regla de ACCEPT antes de cambiar la política.

---

## Objetivos (targets)

| Target | Descripción |
|--------|-------------|
| `ACCEPT` | Permitir el paquete |
| `DROP` | Descartar el paquete (sin respuesta) |
| `REJECT` | Rechazar el paquete (con respuesta ICMP) |
| `LOG` | Registrar el paquete en log |
| `RETURN` | Volver a la cadena anterior |
| `DNAT` | Cambiar IP destino (nat) |
| `SNAT` | Cambiar IP origen (nat) |
| `MASQUERADE` | SNAT dinámico (para IPs dinámicas) |
| `REDIRECT` | Redirigir puerto local |
| `MARK` | Marcar paquete para procesamiento posterior |
| `NOTRACK` | No seguir la conexión |

### DROP vs REJECT

```bash
# DROP: descarta el paquete sin respuesta
iptables -A INPUT -s 10.0.0.1 -j DROP
# → El remitente ve timeout (espera hasta timeout)

# REJECT: descarta con respuesta ICMP
iptables -A INPUT -s 10.0.0.1 -j REJECT
# → El remitente recibe "Connection refused" inmediatamente
# → Con --reject-with se puede personalizar el mensaje
iptables -A INPUT -s 10.0.0.1 -j REJECT --reject-with icmp-host-unreachable
iptables -A INPUT -s 10.0.0.1 -j REJECT --reject-with icmp-port-unreachable

# REJECT con TCP reset
iptables -A INPUT -p tcp -j REJECT --reject-with tcp-reset
```

### LOG

```bash
# Registrar paquetes en log (/var/log/kern.log o /var/log/syslog)
iptables -A INPUT -s 10.0.0.0/24 -j LOG --log-prefix "iptables-INPUT: "

# Con límite para evitar llenar logs
iptables -A INPUT -s 10.0.0.0/24 -m limit --limit 5/min -j LOG --log-prefix "iptables: "
```

---

## Módulos de coincidencia (matches)

### -m conntrack (seguimiento de conexión)

```bash
# Solo conexiones nuevas
iptables -A INPUT -m conntrack --ctstate NEW -p tcp --dport 22 -j ACCEPT

# Conexiones establecidas y relacionadas (permitir respuestas)
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Todos los estados
iptables -A INPUT -m conntrack --ctstate NEW,ESTABLISHED,RELATED -j ACCEPT

# Invalid (descartar paquetes corruptos)
iptables -A INPUT -m conntrack --ctstate INVALID -j DROP
```

### -m state (obsoleto, usar conntrack)

```bash
iptables -A INPUT -m state --state NEW -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
```

> **Nota**: `-m state` es la versión antigua. `-m conntrack` es la moderna recomendada.

### -m limit

```bash
# Limitar LOGs a 5 por minuto
iptables -A INPUT -m limit --limit 5/min -j LOG

# Limitar conexiones nuevas a 10 por segundo
iptables -A INPUT -p tcp --dport 80 -m limit --limit 10/s -j ACCEPT

# Burst: permitir ráfagas de hasta 20 conexiones
iptables -A INPUT -p tcp --dport 80 -m limit --limit 10/s --limit-burst 20 -j ACCEPT
```

### -m connlimit (límite de conexiones simultáneas)

```bash
# Máximo 3 conexiones SSH simultáneas desde una misma IP
iptables -A INPUT -p tcp --dport 22 -m connlimit --connlimit-above 3 -j REJECT

# Mostrar mensaje al superar el límite
iptables -A INPUT -p tcp --dport 22 -m connlimit --connlimit-above 3 --connlimit-mask 32 -j REJECT --reject-with tcp-reset

# Máximo 10 conexiones por IP a un servicio web
iptables -A INPUT -p tcp --dport 80 -m connlimit --connlimit-above 10 -j REJECT
```

### -m recent (detección de actividad reciente)

```bash
# Actualizar lista de IPs que han hecho SSH en el último minuto
iptables -A INPUT -p tcp --dport 22 -m recent --set --name ssh

# Bloquear IPs con más de 3 intentos SSH en 1 minuto
iptables -A INPUT -p tcp --dport 22 -m recent --update --seconds 60 --hitcount 4 --name ssh -j DROP

# o más legible:
iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --set --name SSH
iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 60 --hitcount 4 --name SSH -j DROP
```

### -m mac

```bash
# Permitir solo tráfico desde una MAC específica en la LAN
iptables -A INPUT -i eth0 -m mac --mac-source 00:11:22:33:44:55 -j ACCEPT
```

### -m multiport

```bash
# Múltiples puertos en una sola regla
iptables -A INPUT -p tcp -m multiport --dports 22,80,443 -j ACCEPT

# Rangos
iptables -A INPUT -p tcp -m multiport --dports 8000:9000 -j ACCEPT

# Origen y destino
iptables -A INPUT -p tcp -m multiport --sports 1024:65535 --dports 80,443 -j ACCEPT
```

### -m time

```bash
# Bloquear acceso en horario laboral (ej: acceso web solo 9-18)
iptables -A OUTPUT -p tcp --dport 80 -m time --timestart 09:00 --timestop 18:00 --weekdays Mon,Tue,Wed,Thu,Fri -j ACCEPT
iptables -A OUTPUT -p tcp --dport 80 -j DROP

# Bloquear en fines de semana
iptables -A OUTPUT -p tcp --dport 80 -m time --weekdays Sat,Sun -j DROP
```

### -m string

```bash
# Bloquear paquetes que contengan "ejemplo.com" en el payload
iptables -A FORWARD -m string --string "ejemplo.com" --algo bm -j DROP

# Bloquear SQL injection en el payload
iptables -A INPUT -p tcp --dport 80 -m string --string "union select" --algo bm -j DROP
```

---

## Reglas básicas

### Primeros pasos seguros

```bash
# Limpiar todo
iptables -F
iptables -X
iptables -Z
iptables -t nat -F
iptables -t mangle -F

# Políticas por defecto
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Permitir loopback (localhost)
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Permitir conexiones establecidas y relacionadas (esencial)
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Permitir SSH (para no quedarte fuera)
iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -j ACCEPT

# Permitir HTTP y HTTPS
iptables -A INPUT -p tcp -m multiport --dports 80,443 -m conntrack --ctstate NEW -j ACCEPT

# Permitir ICMP (ping)
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT

# Permitir DNS saliente (si eres servidor DNS)
iptables -A INPUT -p udp --dport 53 -j ACCEPT
iptables -A INPUT -p tcp --dport 53 -j ACCEPT
```

### Reglas de salida (OUTPUT)

```bash
# Política restrictiva en OUTPUT
iptables -P OUTPUT DROP

# Permitir conexiones establecidas
iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Permitir DNS saliente
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT

# Permitir HTTP/HTTPS
iptables -A OUTPUT -p tcp -m multiport --dports 80,443 -m conntrack --ctstate NEW -j ACCEPT

# Permitir NTP
iptables -A OUTPUT -p udp --dport 123 -j ACCEPT

# Permitir ping saliente
iptables -A OUTPUT -p icmp --icmp-type echo-request -j ACCEPT
```

---

## NAT (Network Address Translation)

### SNAT (Source NAT) — cambiar IP origen

```bash
# NAT para salida a internet (LAN → WAN)
iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o eth0 -j SNAT --to-source 203.0.113.1

# O con MASQUERADE (cuando la IP WAN es dinámica)
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
```

### DNAT (Destination NAT) — cambiar IP destino

```bash
# Redirigir tráfico del puerto 8080 externo a un servidor interno:80
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 8080 -j DNAT --to-destination 10.0.0.10:80

# Redirigir puerto completo
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j DNAT --to-destination 10.0.0.10

# Con forwarding permitido
iptables -A FORWARD -p tcp -d 10.0.0.10 --dport 80 -m conntrack --ctstate NEW -j ACCEPT
```

### REDIRECT — redirección local

```bash
# Redirigir tráfico HTTP a un proxy local (puerto 3128)
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j REDIRECT --to-port 3128

# Redirigir tráfico DNS a resolver local (útil para Pi-hole)
iptables -t nat -A PREROUTING -i eth0 -p udp --dport 53 -j REDIRECT --to-port 5353
```

### Port Forwarding completo

```bash
# 1. DNAT: paquete externo → server interno
iptables -t nat -A PREROUTING -p tcp --dport 8080 -j DNAT --to-destination 10.0.0.10:80

# 2. SNAT: paquete de respuesta → cliente original
iptables -t nat -A POSTROUTING -d 10.0.0.10 -p tcp --dport 80 -j SNAT --to-source <IP_EXTERNA>

# 3. FORWARD: permitir tráfico hacia el servidor interno
iptables -A FORWARD -p tcp -d 10.0.0.10 --dport 80 -m conntrack --ctstate NEW -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
```

---

## Persistencia

Las reglas de iptables se pierden al reiniciar. Hay que guardarlas y restaurarlas.

### Debian/Ubuntu

```bash
# Guardar reglas
sudo iptables-save > /etc/iptables/rules.v4
sudo ip6tables-save > /etc/iptables/rules.v6

# Restaurar reglas
sudo iptables-restore < /etc/iptables/rules.v4

# Con iptables-persistent
sudo apt install iptables-persistent
sudo netfilter-persistent save
sudo netfilter-persistent reload
```

### RHEL/CentOS

```bash
# Guardar reglas
sudo service iptables save
# o
sudo iptables-save > /etc/sysconfig/iptables

# Restaurar
sudo service iptables restart
```

---

## Escenarios reales

### 1. Servidor web básico

```bash
# Políticas
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Loopback
iptables -A INPUT -i lo -j ACCEPT

# Conexiones establecidas
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# SSH (admin)
iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -j ACCEPT

# HTTP/HTTPS
iptables -A INPUT -p tcp -m multiport --dports 80,443 -m conntrack --ctstate NEW -j ACCEPT

# ICMP limitado
iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 10/s -j ACCEPT

# Log y drop del resto
iptables -A INPUT -j LOG --log-prefix "DROP: " --log-limit 5/min
iptables -A INPUT -j DROP
```

### 2. Firewall para red local (router/NAT)

```bash
# IPv4 forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# NAT
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# FORWARD: permitir tráfico de la LAN a WAN
iptables -A FORWARD -i eth1 -o eth0 -m conntrack --ctstate NEW -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# INPUT desde LAN (servicios internos)
iptables -A INPUT -i eth1 -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -i eth1 -p tcp --dport 80 -j ACCEPT

# Políticas
iptables -P FORWARD DROP
iptables -P INPUT DROP
iptables -P OUTPUT ACCEPT
```

### 3. Protección contra ataques básicos

```bash
# SYN flood protection
iptables -A INPUT -p tcp --syn -m limit --limit 100/s --limit-burst 200 -j ACCEPT
iptables -A INPUT -p tcp --syn -j DROP

# Descartar paquetes inválidos
iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

# Bloquear NULL packets
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP

# Bloquear Xmas packets (FIN+PSH+URG)
iptables -A INPUT -p tcp --tcp-flags ALL FIN,PSH,URG -j DROP

# Bloquear nmap Xmas scan
iptables -A INPUT -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP

# Bloquear paquetes con SYN y FIN (imposible en TCP normal)
iptables -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP

# Bloquear paquetes con SYN y RST
iptables -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP

# Bloquear ping de la muerte (ICMP fragmentado)
iptables -A INPUT -p icmp --icmp-type echo-request -m length --length 65535 -j DROP
```

### 4. Rate limiting por IP

```bash
# SSH brute force: máximo 4 intentos/minuto desde una IP
iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --set --name SSH
iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 4 --name SSH -j DROP

# HTTP: máximo 100 peticiones/minuto desde una IP
iptables -A INPUT -p tcp --dport 80 -m conntrack --ctstate NEW -m recent --set --name HTTP
iptables -A INPUT -p tcp --dport 80 -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 100 --name HTTP -j DROP
```

### 5. Bloquear rangos de IPs geográficos

```bash
# Bloquear IPs de un país (usando listas externas)
# Descargar lista de rangos de IPs de un país:
wget https://www.ipdeny.com/ipblocks/data/countries/cn.zone -O /tmp/cn.zone

# Bloquear todos esos rangos
for ip in $(cat /tmp/cn.zone); do
  iptables -A INPUT -s "$ip" -j DROP
done
```

### 6. Permitir solo una IP para SSH

```bash
# Solo permitir SSH desde la IP de la oficina
iptables -A INPUT -p tcp --dport 22 -s 203.0.113.0/24 -m conntrack --ctstate NEW -j ACCEPT

# Bloquear SSH desde cualquier otra IP
iptables -A INPUT -p tcp --dport 22 -j DROP
```

---

## Escenarios de ataque y mitigación

### 1. SYN Flood

**Síntoma**: muchas conexiones SYN-RECV en `ss -t state syn-recv`, CPU alto, servicio no responde.

```bash
# Mitigación en iptables
iptables -A INPUT -p tcp --syn -m limit --limit 100/s --limit-burst 200 -j ACCEPT
iptables -A INPUT -p tcp --syn -j DROP

# Reducir SYN-RECV en el kernel
sysctl -w net.ipv4.tcp_max_syn_backlog=4096
sysctl -w net.ipv4.tcp_syncookies=1
sysctl -w net.ipv4.tcp_syn_retries=2
```

### 2. Port Scan

**Síntoma**: logs llenos de conexiones a puertos aleatorios.

```bash
# Detectar escaneos (logging)
iptables -A INPUT -m conntrack --ctstate NEW -m recent --set --name PORTSCAN
iptables -A INPUT -m conntrack --ctstate NEW -m recent --update --seconds 10 --hitcount 20 --name PORTSCAN -j LOG --log-prefix "PORTSCAN: "

# Bloquear escáneres
iptables -A INPUT -m conntrack --ctstate NEW -m recent --update --seconds 10 --hitcount 20 --name PORTSCAN -j DROP
```

### 3. DDoS (Distributed Denial of Service)

```bash
# Mitigación básica de DDoS
# Limitar conexiones nuevas por IP
iptables -A INPUT -p tcp --syn -m connlimit --connlimit-above 50 -j DROP

# Limitar peticiones HTTP por IP
iptables -A INPUT -p tcp --dport 80 -m connlimit --connlimit-above 30 -j REJECT

# Proteger contra flood de paquetes pequeños
iptables -A INPUT -p tcp --tcp-flags ALL SYN -m length --length 40 -j DROP

# Limitar ICMP
iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/s -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-request -j DROP
```

### 4. ARP Spoofing

**Síntoma**: tráfico pasa por un atacante (MITM), IPs duplicadas.

```bash
# Mitigación: ARP estático (ya vimos en ip neigh)
iptables no puede prevenir ARP spoofing directamente,
# pero se puede bloquear tráfico con MAC no esperada:
iptables -A INPUT -i eth0 -m mac --mac-source ! 00:11:22:33:44:55 -j DROP
```

### 5. DNS Amplification

**Síntoma**: el servidor DNS envía tráfico masivo a una víctima.

```bash
# Limitar consultas DNS por IP (como servidor DNS)
iptables -A INPUT -p udp --dport 53 -m connlimit --connlimit-above 50 -j DROP

# Evitar que el servidor DNS participe en amplification
iptables -A INPUT -p udp --dport 53 -m length --length 1000:65535 -j DROP
```

### 6. Bloquear tráfico de bots conocidos

```bash
# Bloquear rangos de IPs de datacenters conocidos por hosting de bots
# (ejemplo: Hetzner, DigitalOcean, AWS - si no deberían estar)
iptables -A INPUT -s 5.9.0.0/16 -j DROP
# Nota: ajustar según tu caso de uso
```

---

## Diagnóstico y depuración

### Ver contadores de reglas

```bash
# -v: verbose, muestra contadores de paquetes y bytes
iptables -L -v -n

# Resetear contadores
iptables -Z

# Ver contadores en una cadena específica
iptables -L INPUT -v -n --line-numbers
```

### Guardar dump para análisis

```bash
# Dump completo de todas las tablas
iptables-save > /tmp/iptables-dump.txt
iptables -t nat -L -n -v >> /tmp/iptables-dump.txt
```

### Probar reglas (sin aplicarlas)

```bash
# No hay un dry-run en iptables, pero se puede simular con un script
# o usando iptables-apply (intenta y pregunta antes de confirmar)

# iptables-apply: prueba las reglas, si pierdes conexión las revierte
sudo iptables-apply /etc/iptables/rules.v4
```

### Ver tráfico que coincide con reglas

```bash
# Añadir logging temporal
iptables -A INPUT -s 10.0.0.0/24 -j LOG --log-prefix "TEST: "
tail -f /var/log/kern.log | grep "TEST:"

# Luego eliminar la regla de log
iptables -D INPUT -s 10.0.0.0/24 -j LOG --log-prefix "TEST: "
```

---

## Uno-liners imprescindibles

```bash
# Listar reglas
iptables -L -n -v --line-numbers

# Eliminar todos las reglas
iptables -F && iptables -X && iptables -Z

# Política por defecto
iptables -P INPUT DROP

# Permitir loopback
iptables -A INPUT -i lo -j ACCEPT

# Permitir conexiones establecidas
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Permitir SSH
iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -j ACCEPT

# Permitir HTTP/HTTPS
iptables -A INPUT -p tcp -m multiport --dports 80,443 -j ACCEPT

# Bloquear IP específica
iptables -A INPUT -s 10.0.0.1 -j DROP

# Bloquear puerto de entrada específico
iptables -A INPUT -p tcp --dport 3306 -j DROP

# NAT (compartir internet)
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Port forwarding
iptables -t nat -A PREROUTING -p tcp --dport 8080 -j DNAT --to-destination 10.0.0.10:80

# REDIRECT local
iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 3128

# Logging
iptables -A INPUT -j LOG --log-prefix "DROP: "

# Rate limit SSH
iptables -A INPUT -p tcp --dport 22 -m recent --update --seconds 60 --hitcount 4 --name SSH -j DROP
iptables -A INPUT -p tcp --dport 22 -m recent --set --name SSH -j ACCEPT

# Bloquear NULL scan
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP

# Bloquear Xmas scan
iptables -A INPUT -p tcp --tcp-flags ALL FIN,PSH,URG -j DROP

# Guardar reglas
iptables-save > /etc/iptables/rules.v4

# Restaurar reglas
iptables-restore < /etc/iptables/rules.v4

# Eliminar regla por número
iptables -D INPUT 3

# Insertar regla al inicio
iptables -I INPUT 1 -p tcp --dport 22 -j ACCEPT

# Limitar conexiones por IP
iptables -A INPUT -p tcp --dport 80 -m connlimit --connlimit-above 30 -j REJECT
```
