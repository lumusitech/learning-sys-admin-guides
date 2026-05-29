# 🧩 Escenario: MTU mismatch — paquetes descartados por fragmentación

**Dominio:** networking
**Nivel:** 🟡 Intermedio
**Herramientas:** `ping -M do`, `ip link`, `tcpdump`, `tracepath`
**Archivos:** Sistema en vivo / red con VPN o túneles

---

## 🎯 Problema

Las conexiones de red funcionan para tráfico pequeño pero fallan para transferencias grandes. Las páginas web cargan parcialmente, las transferencias de archivos se cuelgan, o las conexiones SSH se cortan al enviar datos grandes. El problema es típico en rutas que pasan por VPN, túneles GRE/IPsec, o redes con MTU diferente a 1500.

---

## ⚡ Quick command (SRE)

```bash
ping -M do -s 1472 -c 3 <destino>
```

---

## ✅ Salida esperada

- `ping` con tamaño 1472 funciona → MTU 1500 está OK en toda la ruta
- `ping` con tamaño 1472 falla con "Message too long" → MTU mismatch detectado
- `ping` con tamaño menor (ej: 1400) funciona → la MTU real es menor a 1500
- `tcpdump` muestra paquetes ICMP "Destination Unreachable (Fragmentation Needed)" → hay un router en la ruta que necesita fragmentar pero el paquete tiene DF (Don't Fragment) set

Interpretación:

- `ping` falla con `-M do` y tamaño grande → hay un tramo en la ruta con MTU menor a 1500
- el fallo ocurre solo para ciertos tamaños → se puede calcular la MTU real
- `tcpdump` muestra ICMP Fragmentation Needed → el router intermedio informa del problema
- transferencias grandes fallan pero ping funciona → las transferencias usan paquetes más grandes que ping

---

## 🧠 Diagnóstico

MTU mismatch ocurre cuando dos extremos de una ruta tienen configuraciones de MTU diferentes. Si un router intermedio tiene MTU menor (ej: 1400 para una VPN) y el paquete tiene el flag DF (Don't Fragment) set, el paquete se descarta y se envía un ICMP "Fragmentation Needed" de vuelta.

Patrones clave:

- `ping -M do -s 1472` falla → MTU 1500 no funciona en toda la ruta
- `ping -M do -s 1400` funciona → la MTU real está entre 1400 y 1472
- transferencias grandes fallan pero ping funciona → los paquetes grandes se descartan por MTU
- `tcpdump` muestra ICMP Fragmentation Needed → hay un router con MTU menor en la ruta
- el problema ocurre solo a través de VPN o túnel → la VPN reduce la MTU disponible

👉 Si `ping -M do` falla para tamaños grandes, la MTU de la ruta es menor a 1500.

---

## 🛠️ Procedimiento (runbook)

### 1. Verificar la MTU de la interfaz local

```bash
ip link show eth0 | grep mtu
```

### 2. Probar MTU con ping (decrementando tamaño)

```bash
ping -M do -s 1472 -c 3 <destino>
ping -M do -s 1400 -c 3 <destino>
ping -M do -s 1300 -c 3 <destino>
```

### 3. Encontrar la MTU real de la ruta (tracepath)

```bash
tracepath <destino>
```

### 4. Capturar ICMP Fragmentation Needed

```bash
tcpdump -i eth0 icmp and icmp[0] == 3 and icmp[1] == 4 -n
```

### 5. Verificar si hay túneles o VPN en la ruta

```bash
ip route show
traceroute <destino>
```

---

## 🧯 Mitigación

Si se confirma MTU mismatch:

Verificar:

```bash
ping -M do -s 1472 -c 3 <destino>
ip link show
```

Acción:

```bash
# Reducir la MTU de la interfaz al valor real encontrado
ip link set eth0 mtu 1400

# Verificar que se aplicó
ip link show eth0 | grep mtu
```

Mitigación adicional:

```bash
# Habilitar Path MTU Discovery (PMTUD) para que el sistema ajuste automáticamente
sysctl net.ipv4.ip_no_pmtu_disc=0

# O configurar MSS clamping en iptables (para TCP)
iptables -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
```

Rollback:

```bash
# Restaurar MTU original
ip link set eth0 mtu 1500

# Restaurar PMTUD
sysctl net.ipv4.ip_no_pmtu_disc=1
```

Casos comunes:

- VPN con overhead reduce MTU disponible → la VPN encapsula los paquetes, reduciendo el espacio útil
- túnel GRE/IPsec reduce MTU → similar a VPN, la encapsulación consume bytes de la MTU
- PPPoE reduce MTU a 1492 → ISP con PPPoE tiene MTU menor a 1500
- router intermedio con MTU reducida → algún equipo en la ruta tiene MTU configurada menor

---

## ✅ Interpretación

- la transferencia funciona tras reducir MTU → el problema era MTU mismatch
- `tracepath` muestra la MTU real en algún salto → se puede identificar dónde está el problema
- el problema ocurre solo a través de VPN → la VPN está reduciendo la MTU disponible
- ICMP Fragmentation Needed desaparece tras ajustar MTU → el router intermedio ya puede pasar los paquetes

---

## 🐧 Variante Alpine (OpenRC)

> Este escenario no usa `systemctl`, `journalctl`, `apt` ni `ufw`. No requiere variante Alpine.

---

## 🔗 Referencias

- [`ping_traceroute`](../../guides/ping_traceroute.md) — ping, traceroute y mtr
- [`ip_ss`](../../guides/ip_ss.md) — redes y sockets
- [`tcpdump`](../../guides/tcpdump.md) — captura de tráfico
- [`scenarios/networking/05-network-packet-loss-latency.md`](05-network-packet-loss-latency.md) — pérdida de paquetes (problema relacionado)
- [`scenarios/networking/07-intermittent-timeouts.md`](07-intermittent-timeouts.md) — timeouts intermitentes
