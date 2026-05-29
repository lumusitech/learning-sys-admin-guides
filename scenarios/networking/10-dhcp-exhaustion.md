# 🧩 Escenario: DHCP exhaustion — pool de direcciones agotado

**Dominio:** networking
**Nivel:** 🟡 Intermedio
**Herramientas:** `dhcp-lease-list`, `arp`, `ip neigh`, `tcpdump`
**Archivos:** Sistema en vivo / red local

---

## 🎯 Problema

Los dispositivos nuevos no pueden obtener IP por DHCP. Los usuarios reportan que sus dispositivos muestran "Sin acceso a Internet" o tienen IP 169.254.x.x (APIPA). El servidor DHCP puede estar agotado por exceso de dispositivos, un ataque de DHCP starvation, o una configuración incorrecta del pool.

---

## ⚡ Quick command (SRE)

```bash
ip neigh show nud reachable | wc -l && arp -a | wc -l
```

---

## ✅ Salida esperada

- muchos dispositivos con IPs en la misma subred → pool posiblemente lleno
- IPs 169.254.x.x → los dispositivos no pudieron obtener IP por DHCP
- `tcpdump` muestra muchos DHCP Discover → los clientes están pidiendo IP sin respuesta
- el servidor DHCP muestra "pool exhausted" o "no addresses available" → pool agotado

Interpretación:

- IPs 169.254.x.x → el cliente DHCP no recibió respuesta (pool lleno o servidor caído)
- muchos DHCP Discover sin DHCP Offer → el servidor no tiene IPs para ofrecer
- un solo dispositivo con muchas IPs MAC diferentes → DHCP starvation attack
- el pool tiene pocos leases disponibles → se necesita ampliar el rango

---

## 🧠 Diagnóstico

DHCP exhaustion ocurre cuando el pool de direcciones IP del servidor DHCP se agota. Esto puede ser por exceso legítimo de dispositivos o por un ataque de DHCP starvation donde un atacante solicita IPs con MACs falsas para agotar el pool.

Patrones clave:

- IPs 169.254.x.x → los clientes no recibieron IP del servidor DHCP
- muchos DHCP Discover desde la misma MAC → ataque de DHCP starvation
- pool con pocos leases → configuración insuficiente para la cantidad de dispositivos
- servidor DHCP caído → ningún dispositivo puede obtener IP
- leases muy largos → las IPs no se liberan aunque los dispositivos se desconecten

👉 Si los clientes tienen IP 169.254.x.x, el problema es DHCP (servidor caído o pool agotado).

---

## 🛠️ Procedimiento (runbook)

### 1. Verificar si los clientes tienen IP válida

```bash
ip addr show
```

Si la IP es 169.254.x.x, el cliente no recibió IP del DHCP.

### 2. Verificar el estado del servidor DHCP

```bash
systemctl status dhcpd
# o en ISC DHCP:
cat /var/lib/dhcp/dhcpd.leases | tail -20
```

### 3. Contar leases activos vs pool disponible

```bash
# En ISC DHCP Server:
grep -c "lease" /var/lib/dhcp/dhcpd.leases
# Comparar con el rango configurado en /etc/dhcp/dhcpd.conf
```

### 4. Capturar tráfico DHCP para ver si hay starvation

```bash
tcpdump -i eth0 port 67 or port 68 -n -c 100
```

### 5. Buscar MACs que solicitan muchas IPs

```bash
tcpdump -i eth0 port 67 or port 68 -n | awk '/DHCP-Message.*Discover/ {print $2}' | sort | uniq -c | sort -rn
```

---

## 🧯 Mitigación

Si se confirma DHCP exhaustion:

Verificar:

```bash
systemctl status dhcpd
cat /var/lib/dhcp/dhcpd.leases | grep -c "lease"
```

Acción:

```bash
# Ampliar el rango del pool DHCP
# En /etc/dhcp/dhcpd.conf:
# subnet 192.168.1.0 netmask 255.255.255.0 {
#   range 192.168.1.100 192.168.1.250;
#   option routers 192.168.1.1;
# }

# Reiniciar el servicio DHCP
systemctl restart dhcpd
```

Mitigación adicional:

```bash
# Reducir el tiempo de lease para liberar IPs más rápido
# En /etc/dhcp/dhcpd.conf:
# default-lease-time 3600;    # 1 hora
# max-lease-time 7200;        # 2 horas

# Habilitar DHCP snooping en switches gestionados
# Esto bloquea DHCP servers no autorizados y limita requests por puerto
```

Rollback:

```bash
# Restaurar configuración original del pool
# Restaurar tiempos de lease
systemctl restart dhcpd
```

Casos comunes:

- red con muchos dispositivos IoT → pool insuficiente para la cantidad de dispositivos
- ataque de DHCP starvation → un atacante agota el pool con MACs falsas
- leases muy largos → las IPs no se liberan aunque los dispositivos se desconecten
- servidor DHCP caído → ningún dispositivo puede obtener IP

---

## ✅ Interpretación

- los clientes obtienen IP tras ampliar el pool → el problema era pool insuficiente
- los clientes obtienen IP tras reducir lease time → las IPs se estaban acumulando
- el ataque de starvation se detiene con DHCP snooping → el atacante estaba agotando el pool
- los clientes siguen sin IP → el servidor DHCP puede estar caído o mal configurado

---

## 🐧 Variante Alpine (OpenRC)

> Este escenario usa `systemctl` en mitigación.

### Variante A — solo systemctl

```bash
# Debian:                          # Alpine:
systemctl restart dhcpd            rc-service dhcpd restart
```

En Alpine, el servicio DHCP se llama `dhcpd` o `kea-dhcp4` según la distribución.

---

## 🔗 Referencias

- [`ip_ss`](../../guides/ip_ss.md) — redes y sockets
- [`tcpdump`](../../guides/tcpdump.md) — captura de tráfico
- [`scenarios/networking/04-dns-resolution-failure.md`](04-dns-resolution-failure.md) — fallos de DNS (problema de red relacionado)
- [`scenarios/networking/01-detect-ssh-brute-force.md`](01-detect-ssh-brute-force.md) — detección de fuerza bruta
