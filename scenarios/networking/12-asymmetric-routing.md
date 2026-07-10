# 🧩 Escenario: Ruta asimétrica — tráfico que va pero no vuelve

**Dominio:** networking
**Nivel:** 🔴 Avanzado
**Herramientas:** `ip`, `traceroute`, `tcpdump`, `ping`, `ss`
**Archivos:** `labs/docker-compose.network.yml`

---

## 🎯 Problema

Desde el servidor A, el ping al servidor B funciona, pero las conexiones TCP nunca se establecen. `ss` muestra paquetes SYN enviados pero nunca SYN-ACK recibidos. `tcpdump` confirma que los paquetes salen del servidor A pero no llegan respuesta. No hay firewall bloqueando explícitamente. El problema es una **ruta asimétrica**: el tráfico de ida toma un camino y el de vuelta otro, y el camino de vuelta no está configurado en B.

---

## ⚡ Quick command (SRE)

```bash
ip route get <IP_destino> && traceroute <IP_destino> | head -10
```

---

## ✅ Salida esperada

```text
# En servidor A:
$ ip route get 10.20.30.40
10.20.30.40 via 192.168.1.1 dev eth0 src 192.168.1.10

$ traceroute 10.20.30.40
 1  192.168.1.1 (192.168.1.1)  0.5ms
 2  10.0.0.1 (10.0.0.1)  1.2ms
 3  * * *                         ← pérdida de ruta de vuelta
```

Interpretación:

- `ip route get` muestra que la ruta de ida pasa por gateway 192.168.1.1
- Los primeros hops responden → la ruta de ida funciona
- `* * *` constante en un hop intermedio → el paquete llega pero la respuesta toma otra ruta que no existe
- Si ping ICMP funciona pero TCP no, la ruta asimétrica podría estar filtrando TCP específicamente

---

## 🧠 Diagnóstico

Ruta asimétrica ocurre cuando:

- Hay múltiples gateways y cada uno tiene tablas de ruteo diferentes
- Una interfaz de red secundaria tiene métrica incorrecta
- El kernel hace source-based routing (respuesta por interfaz incorrecta)
- VPN o túnel crea una ruta que el tráfico de retorno no conoce

Patrón clave: ping funciona porque ICMP es bidireccional por ruta default, pero TCP usa la IP de origen de la interfaz por donde salió. Si la respuesta intenta volver por otra interfaz con IP diferente, el destino rechaza el paquete.

---

## 🛠️ Procedimiento (runbook)

### 1. Confirmar que el tráfico sale

```bash
tcpdump -i eth0 host <IP_destino> -c 5 &
ping -c 3 <IP_destino>
```

### 2. Verificar tabla de rutas local

```bash
ip route show
ip route show table all | grep default
```

### 3. Verificar routing simétrico (rp_filter)

```bash
cat /proc/sys/net/ipv4/conf/eth0/rp_filter
cat /proc/sys/net/ipv4/conf/all/rp_filter
```

Si `rp_filter=1`, el kernel descarta paquetes cuya ruta de retorno no coincide con la interfaz de llegada.

### 4. Verificar múltiples gateways

```bash
ip route show | grep default
```

Si hay 2 o más default gateways con métricas diferentes, la ruta de retorno puede elegir cualquiera.

### 5. Solución: forzar ruta simétrica

```bash
# Opción A: política de ruteo por IP de origen
ip rule add from <IP_local> table 100
ip route add default via <gateway_correcto> table 100

# Opción B: desactivar rp_filter (solo si es seguro)
sysctl -w net.ipv4.conf.all.rp_filter=0
```

### 6. Verificar que la conexión TCP funciona

```bash
echo | nc -zv <IP_destino> 22
```

---

## 🧯 Mitigación

Verificar:

```bash
ip route show | grep default
sysctl net.ipv4.conf.all.rp_filter
```

Acción: Si hay múltiples gateways, agregar regla de ruteo por IP de origen. Si rp_filter bloquea tráfico legítimo, ajustar.

Rollback: `ip rule del`, restaurar valor de `rp_filter` original.

---

## ✅ Interpretación

La ruta asimétrica es uno de los problemas de red más difíciles de diagnosticar porque desde el servidor A todo parece funcionar (la ruta de ida está bien). La clave es verificar **qué ruta tomaría la respuesta** desde el servidor B, no solo la ruta desde A.

`tcpdump` en ambos lados muestra la verdad: SYN sale de A, llega a B, SYN-ACK sale de B pero nunca llega a A. En algún punto del camino de vuelta, el paquete se pierde o es descartado.

---

## 🔗 Referencias

- [`ip_ss`](../../guides/ip_ss.md) — rutas, interfaces, rp_filter
- [`tcpdump`](../../guides/tcpdump.md) — confirmar tráfico en ambos extremos
- [`ping_traceroute`](../../guides/ping_traceroute.md) — diagnóstico de ruta
- [`nc`](../../guides/nc.md) — test rápido de conectividad TCP
- [`scenario`](../networking/08-firewall-blocked-port.md) — diagnóstico similar, causa diferente
- [`scenario`](../networking/05-network-packet-loss-latency.md) — pérdida de paquetes
