
# TCP/IP — Modelo en capas para diagnóstico de red

## 🧠 ¿Qué es?

TCP/IP es el modelo que describe cómo se comunican los dispositivos en una red. Define **4 capas** que encapsulan datos progresivamente: cada capa agrega metadata (headers) antes de pasar los datos a la capa inferior.

Las 4 capas, de arriba hacia abajo:

| Capa | Responsabilidad | Ejemplo de problema detectable |
|------|----------------|-------------------------------|
| **Aplicación** (HTTP, DNS, SSH) | Datos del usuario, protocolos de app | 404, 502, timeout DNS |
| **Transporte** (TCP, UDP) | Conexión confiable, puertos, control de flujo | RST, CLOSE_WAIT, retransmisiones |
| **Internet** (IP, ICMP, ARP) | Enrutamiento, direccionamiento | TTL expirado, fragmentación, unreachable |
| **Acceso al medio** (Ethernet, WiFi, fibra) | Señal física, MAC, frames | CRC errors, colisiones, cable roto |

Saber en qué capa está el problema reduce drásticamente el tiempo de diagnóstico: no buscás un error HTTP si el cable está desconectado.

---

## 🎯 ¿Por qué importa?

Sin modelo mental de capas, diagnosticás a ciegas. Con él, descartás sistemáticamente:

- Ping responde → capas 1-3 funcionan, el problema está en transporte o aplicación
- DNS no resuelve → problema en capa de aplicación (DNS) que impide que la capa de transporte (TCP) pueda establecer conexión
- Paquetes retransmitidos → capa de transporte (TCP) detecta pérdida en capa de acceso al medio

El embudo diagnóstico TCP/IP es la herramienta más poderosa para troubleshooting de red: empezás por la capa más baja y subís hasta encontrar la falla.

---

## 🔍 Diagnóstico por capa

### Capa 1: Acceso al medio (física + enlace)

| Pregunta | Herramienta |
|----------|-------------|
| ¿El cable está conectado? | Indicador LED del switch, `ip link` |
| ¿El enlace está up? | `ip link show eth0` (state UP/DOWN) |
| ¿Hay errores de transmisión? | `ip -s link`, `ethtool -S eth0` |

### Capa 2: Internet (IP)

| Pregunta | Herramienta |
|----------|-------------|
| ¿Hay IP asignada? | `ip addr show` |
| ¿Responde el gateway? | `ping <gateway>` |
| ¿Llega al destino? | `ping <IP destino>`, `traceroute <IP>` |
| ¿Hay fragmentación? | `ping -M do -s 1500 <IP>` (MTU path discovery) |

### Capa 3: Transporte (TCP/UDP)

| Pregunta | Herramienta |
|----------|-------------|
| ¿El puerto está abierto? | `ss -tuln`, `nc -zv <host> <puerto>` |
| ¿Hay conexiones en mal estado? | `ss -tan` (SYN_SENT, CLOSE_WAIT, TIME_WAIT) |
| ¿Hay retransmisiones? | `ss -ti` (retrans, retrans_total) |
| ¿Hay pérdida de paquetes? | `ping -c 100` (% loss) |

### Capa 4: Aplicación

| Pregunta | Herramienta |
|----------|-------------|
| ¿El servicio responde? | `curl -I`, `dig`, `systemctl status` |
| ¿Qué error devuelve? | HTTP status, DNS response code |
| ¿Los logs muestran errores? | `journalctl -u <svc>`, `/var/log/` |

---

## 🧠 Modelo mental

Pensá en TCP/IP como una torre de oficinas con 4 pisos: la planta baja es el cableado eléctrico (acceso al medio), el primer piso son las direcciones postales (IP), el segundo piso controla que los paquetes lleguen completos (TCP), y el tercer piso es donde trabaja la gente (aplicaciones).

Cuando algo falla, empezás desde la planta baja y subís preguntando "¿esto funciona?". Si el cable está bien, es IP. Si IP tiene ruta, es TCP. Si TCP conecta, es la aplicación.

Nunca debuguees la aplicación si el cable está desconectado.

---

## 🔗 Ver también

- [`ping_traceroute`](../guides/ping_traceroute.md) — diagnóstico capa 2-3 (IP, ICMP)
- [`ip_ss`](../guides/ip_ss.md) — diagnóstico capa 1-3 (enlace, IP, transporte)
- [`tcpdump`](../guides/tcpdump.md) — captura de tráfico en todas las capas
- [`dig_curl`](../guides/dig_curl.md) — diagnóstico capa 4 (DNS, HTTP)
- [`ssh`](../guides/ssh.md) — diagnóstico capa 4 (acceso remoto)
- [`scenario`](../scenarios/networking/04-dns-resolution-failure.md) — falla en capa de aplicación
- [`scenario`](../scenarios/networking/05-network-packet-loss-latency.md) — falla en capa de acceso + transporte
- [`scenario`](../scenarios/web/05-502-bad-gateway.md) — falla en capa de aplicación con proxy
