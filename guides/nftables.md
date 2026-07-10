# nftables — Guía completa

**Nivel:** 🔴 Avanzado
**Archivos de práctica:** `labs/firewall.log`
**Ver escenarios relacionados:** [`networking/03-port-scan`](../scenarios/networking/03-port-scan-detection.md), [`infrastructure/02-build-pyme`](../scenarios/infrastructure/02-build-pyme-infrastructure.md)

## ⚡ Quick command

`nft list ruleset`

## ⚡ Quick run

```bash
nft list ruleset | head -20
```

---

## 📑 Índice

1. [¿Qué es nftables?](#qué-es-nftables)
2. [Modelo mental](#modelo-mental)
3. [Sintaxis básica](#sintaxis-básica)
4. [Salida clave](#salida-clave)
5. [Opciones principales](#opciones-principales)
6. [Patrones de uso](#patrones-de-uso)
7. [Uso en troubleshooting](#uso-en-troubleshooting)
8. [Combinación con otras herramientas](#combinación-con-otras-herramientas)
9. [Uno-liners imprescindibles](#uno-liners-imprescindibles)
10. [Errores comunes](#errores-comunes)
11. [Buenas prácticas](#buenas-prácticas)
12. [Migración desde iptables](#migración-desde-iptables)
13. [Referencias internas](#referencias-internas)

---

## 🧠 ¿Qué es nftables?

**nftables** es el sucesor de iptables, ip6tables, arptables y ebtables. Unifica el framework de filtrado de paquetes en un solo componente del kernel Linux (desde kernel 3.13, 2014).

### ¿Por qué nftables?

- **Sintaxis unificada**: IPv4, IPv6, ARP y bridges en un solo lenguaje
- **Sets named**: listas de IPs/puertos eficientes (reemplaza ipset)
- **Mejor rendimiento**: máquina virtual de bytecode en el kernel
- **Configuración atómica**: aplica cambios completos o ninguno (rollback automático si falla)
- **Menos código**: reemplaza 4 herramientas (iptables, ip6tables, arptables, ebtables) con una

### ¿Dónde está disponible?

| Distro | Versión | Estado |
|--------|---------|--------|
| Debian 10+ | 10 (Buster) | iptables usa backend nftables por defecto |
| Debian 12+ | 12 (Bookworm) | nftables nativo recomendado |
| Ubuntu 20.04+ | 20.04 LTS | Backend nftables disponible |
| Ubuntu 22.04+ | 22.04 LTS | nftables nativo recomendado |
| RHEL 9+ | 9 | nftables nativo (firewalld usa nftables) |
| Alpine 3.15+ | 3.15 | nftables disponible |

```bash
# Verificar si nftables está disponible
nft --version

# Ver si iptables está usando backend nftables
ls -la $(which iptables)
# Si es symlink a iptables-nft → usa nftables como backend
```

---

## 🧠 Modelo mental

### Diferencias clave con iptables

| Concepto | iptables | nftables |
|----------|----------|----------|
| **Estructura** | Tablas → Cadenas → Reglas | Tables → Chains → Rules (similar pero más flexible) |
| **Familias** | Separado: iptables (IPv4), ip6tables (IPv6) | Unificado: `ip`, `ip6`, `inet` (ambos), `arp`, `bridge` |
| **Sets** | Requiere ipset externo | Sets nativos integrados |
| **Sintaxis** | Comandos separados por espacios | Lenguaje estructurado con llaves `{}` |
| **Atomicidad** | No atómico (regla por regla) | Atómico (aplica todo o nada) |
| **Comentarios** | No soportados nativamente | Soportados con `comment "texto"` |

### Familias de protocolos

nftables organiza las reglas por **familia** (dominio de red):

| Familia | Uso |
|---------|-----|
| `ip` | IPv4 |
| `ip6` | IPv6 |
| `inet` | IPv4 + IPv6 (dual-stack) |
| `arp` | ARP (Address Resolution Protocol) |
| `bridge` | Tráfico entre interfaces bridge |
| `netdev` | Ingress/egress en interfaces de red |

**Regla práctica**: usa `inet` para firewalls dual-stack (IPv4 + IPv6 simultáneamente).

---

## 📝 Sintaxis básica

### Estructura de una regla

```bash
nft add rule <familia> <tabla> <cadena> <expresión> <acción>
```

**Ejemplo**:

```bash
nft add rule inet filter input ip saddr 192.168.1.100 tcp dport 22 accept
```

**Desglose**:

- `nft add rule` → comando para agregar regla
- `inet` → familia (IPv4 + IPv6)
- `filter` → tabla
- `input` → cadena
- `ip saddr 192.168.1.100` → condición (IP origen)
- `tcp dport 22` → condición (puerto destino TCP)
- `accept` → acción (aceptar paquete)

### Crear tabla y cadena

```bash
# Crear tabla
nft add table inet filter

# Crear cadena con hook (punto de enganche al kernel)
nft add chain inet filter input { type filter hook input priority 0 \; }
```

**Componentes de una cadena**:

- `type filter` → tipo de cadena (filter, nat, route)
- `hook input` → punto de enganche (input, output, forward, prerouting, postrouting)
- `priority 0` → prioridad de ejecución (menor = primero)

---

## 🔑 Salida clave

### Listar reglas

```bash
# Listar todo el ruleset
nft list ruleset

# Listar una tabla específica
nft list table inet filter

# Listar una cadena específica
nft list chain inet filter input
```

**Salida típica**:

```text
table inet filter {
    chain input {
        type filter hook input priority 0; policy drop;
        ct state established,related accept
        iifname "lo" accept
        tcp dport 22 accept
        tcp dport 80 accept
        tcp dport 443 accept
        icmp type echo-request accept
    }
}
```

**Interpretación**:

- `type filter hook input priority 0` → cadena de filtrado en hook input
- `policy drop` → política por defecto: descartar todo lo que no coincida
- `ct state established,related accept` → aceptar conexiones establecidas
- `iifname "lo" accept` → aceptar tráfico de loopback
- `tcp dport 22 accept` → aceptar SSH
- `icmp type echo-request accept` → aceptar ping

---

## 🎛️ Opciones principales

### Comandos de gestión

| Comando | Descripción |
|---------|-------------|
| `nft list ruleset` | Listar todas las reglas |
| `nft list table <familia> <tabla>` | Listar una tabla |
| `nft list chain <familia> <tabla> <cadena>` | Listar una cadena |
| `nft add table <familia> <tabla>` | Crear tabla |
| `nft add chain <familia> <tabla> <cadena>` | Crear cadena |
| `nft add rule <familia> <tabla> <cadena> <regla>` | Agregar regla |
| `nft insert rule <familia> <tabla> <cadena> <regla>` | Insertar regla al inicio |
| `nft delete rule <familia> <tabla> <cadena> handle <N>` | Eliminar regla por handle |
| `nft flush chain <familia> <tabla> <cadena>` | Vaciar cadena (eliminar todas las reglas) |
| `nft flush ruleset` | Vaciar todo el ruleset |

### Expresiones comunes

| Expresión | Descripción |
|-----------|-------------|
| `ip saddr <IP>` | IP origen |
| `ip daddr <IP>` | IP destino |
| `tcp dport <puerto>` | Puerto destino TCP |
| `tcp sport <puerto>` | Puerto origen TCP |
| `udp dport <puerto>` | Puerto destino UDP |
| `ct state <estado>` | Estado de conexión (new, established, related, invalid) |
| `iifname <interfaz>` | Interfaz de entrada |
| `oifname <interfaz>` | Interfaz de salida |
| `meta l4proto <protocolo>` | Protocolo de capa 4 (tcp, udp, icmp) |

### Acciones (verbs)

| Acción | Descripción |
|--------|-------------|
| `accept` | Aceptar paquete |
| `drop` | Descartar paquete (sin respuesta) |
| `reject` | Rechazar paquete (envía ICMP/TCP RST) |
| `log` | Registrar en syslog |
| `counter` | Contar paquetes/bytes |
| `jump <cadena>` | Saltar a otra cadena |
| `return` | Retornar de cadena saltada |

---

## 📋 Patrones de uso

### Firewall básico para servidor

```bash
#!/bin/bash
# Firewall básico: permitir SSH, HTTP, HTTPS, ping

# Limpiar ruleset existente
nft flush ruleset

# Crear tabla y cadena
nft add table inet filter
nft add chain inet filter input { type filter hook input priority 0 \; policy drop \; }

# Permitir loopback
nft add rule inet filter input iifname "lo" accept

# Permitir conexiones establecidas
nft add rule inet filter input ct state established,related accept

# Permitir SSH (puerto 22)
nft add rule inet filter input tcp dport 22 accept

# Permitir HTTP (puerto 80)
nft add rule inet filter input tcp dport 80 accept

# Permitir HTTPS (puerto 443)
nft add rule inet filter input tcp dport 443 accept

# Permitir ping (ICMP echo-request)
nft add rule inet filter input icmp type echo-request accept

# Política por defecto: drop (ya configurada en la cadena)
```

### NAT para compartir internet

```bash
# Crear tabla NAT
nft add table ip nat
nft add chain ip nat postrouting { type nat hook postrouting priority 100 \; }

# Enmascarar tráfico saliente (SNAT dinámico)
nft add rule ip nat postrouting oifname "eth0" masquerade
```

### Rate limiting para SSH

```bash
# Limitar conexiones SSH a 4 por minuto por IP
nft add rule inet filter input tcp dport 22 ct state new \
    limit rate over 4/minute drop
```

### Set de IPs bloqueadas

```bash
# Crear set de IPs
nft add set inet filter blocklist { type ipv4_addr \; }

# Agregar IPs al set
nft add element inet filter blocklist { 192.168.1.100, 10.0.0.50 }

# Bloquear todo el set
nft add rule inet filter input ip saddr @blocklist drop
```

**Ventaja**: un set es más eficiente que múltiples reglas individuales. El kernel busca en O(1).

---

## 🔍 Uso en troubleshooting

### Ver contadores de reglas

```bash
# Listar reglas con contadores
nft list ruleset | grep -E "packets|bytes"

# Ver contadores de una cadena específica
nft list chain inet filter input
```

**Salida con contadores**:

```text
chain input {
    type filter hook input priority 0; policy drop;
    packets 1234 bytes 567890 ct state established,related accept
    packets 567 bytes 23456 iifname "lo" accept
    packets 89 bytes 4567 tcp dport 22 accept
}
```

**Interpretación**:

- `packets 1234 bytes 567890` → 1234 paquetes, 567890 bytes pasaron por esta regla
- Si una regla tiene 0 paquetes → no está coincidiendo con tráfico
- Si una regla tiene muchos paquetes → está siendo usada activamente

### Probar configuración antes de aplicar

```bash
# Verificar sintaxis sin aplicar
nft -c -f /etc/nftables.conf

# Si no hay errores, aplicar
nft -f /etc/nftables.conf
```

### Ver tráfico que coincide con reglas

```bash
# Agregar logging temporal
nft add rule inet filter input log prefix "TEST: "

# Ver logs en tiempo real
tail -f /var/log/syslog | grep "TEST:"

# Eliminar regla de log (buscar handle primero)
nft list chain inet filter input | grep "TEST:"
# Supongamos handle 5
nft delete rule inet filter input handle 5
```

---

## 🛠️ Combinación con otras herramientas

### nft + grep/awk (análisis de reglas)

```bash
# Contar reglas por tipo de acción
nft list ruleset | awk '/accept/{a++} /drop/{d++} /reject/{r++} END{print "accept:", a, "drop:", d, "reject:", r}'

# Extraer IPs bloqueadas
nft list ruleset | grep -oP 'ip saddr \K[0-9.]+' | sort -u

# Listar puertos abiertos
nft list ruleset | grep -E "tcp dport|udp dport" | awk '{print $3, $4}' | sort -u
```

### nft + ipset (migración desde iptables)

Si vienes de iptables con ipset, nftables tiene sets nativos:

```bash
# iptables + ipset (antiguo)
ipset create blocklist hash:ip
ipset add blocklist 192.168.1.100
iptables -A INPUT -m set --match-set blocklist src -j DROP

# nftables (nativo)
nft add set inet filter blocklist { type ipv4_addr \; }
nft add element inet filter blocklist { 192.168.1.100 }
nft add rule inet filter input ip saddr @blocklist drop
```

---

## 💡 Uno-liners imprescindibles

```bash
# Listar todo el ruleset
nft list ruleset

# Listar con contadores
nft list ruleset | grep -E "packets|bytes"

# Crear firewall básico en una línea
nft add table inet filter && nft add chain inet filter input { type filter hook input priority 0 \; policy drop \; } && nft add rule inet filter input ct state established,related accept && nft add rule inet filter input tcp dport 22 accept

# Bloquear IP específica
nft add rule inet filter input ip saddr 192.168.1.100 drop

# Permitir rango de puertos
nft add rule inet filter input tcp dport 8000-9000 accept

# Crear set y bloquear múltiples IPs
nft add set inet filter blocklist { type ipv4_addr \; } && nft add element inet filter blocklist { 192.168.1.100, 10.0.0.50, 172.16.0.25 } && nft add rule inet filter input ip saddr @blocklist drop

# Rate limiting SSH
nft add rule inet filter input tcp dport 22 ct state new limit rate over 4/minute drop

# NAT para compartir internet
nft add table ip nat && nft add chain ip nat postrouting { type nat hook postrouting priority 100 \; } && nft add rule ip nat postrouting oifname "eth0" masquerade

# Guardar ruleset a archivo
nft list ruleset > /etc/nftables.conf

# Cargar ruleset desde archivo
nft -f /etc/nftables.conf

# Vaciar ruleset completo
nft flush ruleset

# Eliminar regla por handle (primero listar para encontrar handle)
nft list chain inet filter input | grep "tcp dport 22"
# Supongamos handle 3
nft delete rule inet filter input handle 3
```

---

## ⚠️ Errores comunes

### 1. Olvidar escapes en shell

```bash
# ❌ Incorrecto (shell interpreta llaves)
nft add chain inet filter input { type filter hook input priority 0 ; }

# ✅ Correcto (escapar llaves y punto y coma)
nft add chain inet filter input { type filter hook input priority 0 \; }
```

### 2. No permitir conexiones establecidas

```bash
# ❌ Peligroso: bloquea respuestas a conexiones salientes
nft add rule inet filter input tcp dport 22 accept

# ✅ Correcto: permitir establecidas primero
nft add rule inet filter input ct state established,related accept
nft add rule inet filter input tcp dport 22 accept
```

### 3. Política drop sin permitir loopback

```bash
# ❌ Rompe comunicación local
nft add chain inet filter input { type filter hook input priority 0 \; policy drop \; }

# ✅ Permitir loopback inmediatamente
nft add chain inet filter input { type filter hook input priority 0 \; policy drop \; }
nft add rule inet filter input iifname "lo" accept
```

### 4. Confundir familias

```bash
# ❌ Usar ip para IPv6
nft add rule ip filter input ip6 saddr ::1 accept

# ✅ Usar inet para dual-stack o ip6 para IPv6
nft add rule inet filter input ip6 saddr ::1 accept
# o
nft add rule ip6 filter input ip6 saddr ::1 accept
```

### 5. No probar configuración antes de aplicar

```bash
# ❌ Aplicar directamente (puede bloquearte si hay error)
nft -f /etc/nftables.conf

# ✅ Probar sintaxis primero
nft -c -f /etc/nftables.conf && nft -f /etc/nftables.conf
```

---

## ✅ Buenas prácticas

### 1. Usar archivos de configuración

En vez de comandos sueltos, usa `/etc/nftables.conf`:

```bash
#!/usr/sbin/nft -f

flush ruleset

table inet filter {
    chain input {
        type filter hook input priority 0; policy drop;
        iifname "lo" accept
        ct state established,related accept
        tcp dport 22 accept
        tcp dport 80 accept
        tcp dport 443 accept
        icmp type echo-request accept
    }
}
```

**Ventajas**:

- Versionable (git)
- Revisable (diff)
- Atómico (aplica todo o nada)

### 2. Orden de reglas importa

nftables evalúa reglas en orden. Pon las más frecuentes primero:

```bash
# ✅ Orden óptimo
ct state established,related accept  # 90% del tráfico
iifname "lo" accept                   # loopback
tcp dport 22 accept                   # SSH
tcp dport 80 accept                   # HTTP
tcp dport 443 accept                  # HTTPS
icmp type echo-request accept         # ping
```

### 3. Usar comentarios

```bash
nft add rule inet filter input tcp dport 22 accept comment "SSH access"
```

Los comentarios aparecen en `nft list ruleset` y facilitan el mantenimiento.

### 4. Sets para listas grandes

Si necesitas bloquear/permitir más de 10 IPs o puertos, usa sets:

```bash
# ❌ Ineficiente: 100 reglas
nft add rule inet filter input ip saddr 192.168.1.1 drop
nft add rule inet filter input ip saddr 192.168.1.2 drop
# ... 98 más

# ✅ Eficiente: 1 set + 1 regla
nft add set inet filter blocklist { type ipv4_addr \; }
nft add element inet filter blocklist { 192.168.1.1, 192.168.1.2, ... }
nft add rule inet filter input ip saddr @blocklist drop
```

### 5. Persistencia

```bash
# Debian/Ubuntu
sudo apt install nftables
sudo systemctl enable nftables
sudo systemctl start nftables

# Guardar configuración
sudo nft list ruleset > /etc/nftables.conf

# La configuración se carga automáticamente al arrancar
```

---

## 🔄 Migración desde iptables

### Tabla de conversión

| iptables | nftables |
|----------|----------|
| `iptables -A INPUT -p tcp --dport 22 -j ACCEPT` | `nft add rule inet filter input tcp dport 22 accept` |
| `iptables -A INPUT -s 192.168.1.100 -j DROP` | `nft add rule inet filter input ip saddr 192.168.1.100 drop` |
| `iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT` | `nft add rule inet filter input ct state established,related accept` |
| `iptables -A INPUT -i lo -j ACCEPT` | `nft add rule inet filter input iifname "lo" accept` |
| `iptables -P INPUT DROP` | `nft add chain inet filter input { type filter hook input priority 0 \; policy drop \; }` |
| `iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE` | `nft add rule ip nat postrouting oifname "eth0" masquerade` |
| `iptables -A INPUT -m limit --limit 4/minute -j DROP` | `nft add rule inet filter input ct state new limit rate over 4/minute drop` |
| `iptables-save > rules.txt` | `nft list ruleset > rules.nft` |
| `iptables-restore < rules.txt` | `nft -f rules.nft` |

### Herramienta de conversión automática

```bash
# Convertir archivo iptables-save a nftables
iptables-restore-translate -f /etc/iptables/rules.v4 > /etc/nftables.conf

# Verificar sintaxis
nft -c -f /etc/nftables.conf

# Aplicar
nft -f /etc/nftables.conf
```

**Limitaciones**:

- No convierte ipset (usa sets nativos de nftables)
- No convierte algunos módulos complejos
- Requiere revisión manual

---

## 🔗 Referencias internas

- [`iptables`](iptables.md) — firewall legacy (aún ampliamente usado)
- [`network_segmentation`](network_segmentation.md) — VLANs y segmentación de red
- [`scenarios/infrastructure/02-build-pyme`](../scenarios/infrastructure/02-build-pyme-infrastructure.md) — firewall para PYME
- [`scenarios/networking/03-port-scan`](../scenarios/networking/03-port-scan-detection.md) — detección de escaneos
