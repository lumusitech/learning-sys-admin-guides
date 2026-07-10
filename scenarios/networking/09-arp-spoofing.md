# 🧩 Escenario: ARP poisoning — suplantación de identidad en red local

**Dominio:** networking
**Nivel:** 🔴 Avanzado
**Herramientas:** `arp`, `ip neigh`, `tcpdump`, `arptables`, `ip route`
**Archivos:** Sistema en vivo / red local

---

## 🎯 Problema

Un atacante en la misma red local envía paquetes ARP falsos para asociar su MAC con la IP del gateway (o de otro dispositivo). Esto permite interceptar, modificar o bloquear el tráfico de las víctimas (Man-in-the-Middle). Los usuarios reportan intermitencias, páginas que no cargan o certificados SSL inválidos sin razón aparente.

---

## ⚡ Quick command (SRE)

```bash
arp -a | sort -t'(' -k2 -u
```

---

## ✅ Salida esperada

- múltiples IPs asociadas a la misma MAC address → ARP poisoning confirmado
- la MAC del gateway aparece diferente a la esperada → suplantación de gateway
- `tcpdump` muestra ARP replies no solicitados (unsolicited) → ataque activo
- tráfico HTTP/HTTPS redirigido a IP del atacante → Man-in-the-Middle

Interpretación:

- dos IPs con la misma MAC → el atacante está respondiendo por ambas IPs
- MAC del gateway diferente a la conocida → el atacante se está haciendo pasar por el gateway
- ARP replies frecuentes sin request previo → el atacante está enviando ARP broadcasts activos

---

## 🧠 Diagnóstico

ARP poisoning ocurre cuando un dispositivo en la red local envía respuestas ARP falsas. El protocolo ARP no tiene autenticación — cualquier dispositivo puede decir "yo soy el gateway" y la red le cree.

Patrones clave:

- misma MAC para múltiples IPs → ARP poisoning activo
- MAC del gateway no coincide con la documentada → suplantación de gateway
- `tcpdump` muestra ARP replies sin requests → el atacante está haciendo broadcast activo
- certificados SSL inválidos al navegar → el atacante está haciendo HTTPS interception
- latencia alta o intermitencias → el tráfico está pasando por el atacante

👉 Si dos IPs tienen la misma MAC y una de ellas es el gateway, hay ARP poisoning.

---

## 🛠️ Procedimiento (runbook)

### 1. Ver tabla ARP actual

```bash
arp -a
ip neigh show
```

### 2. Buscar MACs duplicadas

```bash
arp -a | awk '{print $4}' | sort | uniq -c | sort -rn
```

### 3. Verificar la MAC real del gateway

```bash
# Desde otro dispositivo conocido o documentación
ip route show default
arp -a | grep <gateway_ip>
```

### 4. Capturar tráfico ARP sospechoso

```bash
tcpdump -i eth0 arp -n -c 50
```

### 5. Verificar si hay ARP replies no solicitados

```bash
tcpdump -i eth0 arp and arp[6:2] == 2 -n
```

---

## 🧯 Mitigación

Si se confirma ARP poisoning:

Verificar:

```bash
arp -a | awk '{print $4}' | sort | uniq -c | sort -rn
```

Acción:

```bash
# Agregar entrada estática para el gateway (mitigación inmediata)
ip neigh replace <gateway_ip> lladdr <mac_real> dev eth0 nud permanent

# Verificar que la entrada estática se aplicó
ip neigh show <gateway_ip>
```

Mitigación adicional:

```bash
# Bloquear tráfico ARP del atacante con arptables
arptables -A INPUT --source-mac <mac_atacante> -j DROP

# En switches gestionados: habilitar Dynamic ARP Inspection (DAI)
# En Linux: usar ebtables para filtrar ARP
ebtables -A INPUT --source-mac <mac_atacante> -j DROP
```

Rollback:

```bash
# Eliminar entrada estática si causa problemas
ip neigh del <gateway_ip> dev eth0

# Eliminar regla arptables
arptables -D INPUT --source-mac <mac_atacante> -j DROP
```

Casos comunes:

- atacante con herramientas como arpspoof, ettercap, bettercap → ARP poisoning activo
- dispositivo con IP duplicada → ARP poisoning pasivo (no intencional)
- switch sin port security → permite que cualquier puerto envíe ARP por otras IPs

---

## ✅ Interpretación

- la MAC del gateway vuelve a la normalidad tras entrada estática → el atacante sigue activo pero la víctima ya no le cree
- las ARP replies falsas desaparecen → el atacante dejó de enviarlas o fue desconectado
- el tráfico se normaliza tras mitigación → el problema era efectivamente ARP poisoning
- persisten problemas de red → el atacante puede estar usando otra técnica (DNS poisoning, DHCP spoofing)

---

## 🐧 Variante Alpine (OpenRC)

> Este escenario no usa `systemctl`, `journalctl`, `apt` ni `ufw`. No requiere variante Alpine.

---

## 🧑‍🏫 Modo docente

**Preguntas:** ¿Qué indicación de ataque es que dos IPs tengan la misma MAC en la tabla ARP? ¿Cómo capturás paquetes ARP con tcpdump? ¿Cómo mitigás un ataque ARP activo?

**Ejercicio:** Detectar una entrada ARP duplicada, capturar tráfico ARP con tcpdump, aplicar mitigación con arptables.

**Evaluación:** detección correcta de anomalía ARP, captura e interpretación de paquetes, mitigación sin perder conectividad.

---

## 🔗 Referencias

- [`ip_ss`](../../guides/ip_ss.md) — redes y sockets
- [`tcpdump`](../../guides/tcpdump.md) — captura de tráfico
- [`iptables`](../../guides/iptables.md) — filtrado de paquetes
- [`scenarios/networking/03-port-scan-detection.md`](03-port-scan-detection.md) — detección de port scanning
- [`scenarios/networking/08-firewall-blocked-port.md`](08-firewall-blocked-port.md) — firewall troubleshooting
