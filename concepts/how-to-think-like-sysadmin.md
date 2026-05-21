# Cómo pensar como un sysadmin — Patrones de diagnóstico

## Índice
1. [Introducción](#introducción)
2. [Patrones normales vs anómalos](#patrones)
3. [Lectura de logs](#lectura-logs)
4. [Latencia vs pérdida de paquetes](#latencia-vs-perdida)
5. [Errores comunes y su interpretación](#errores-comunes)
6. [El orden del diagnóstico](#orden-diagnostico)
7. [Checklist mental ante un incidente](#checklist-mental)

---

## Introducción

La diferencia entre un sysadmin novato y uno experimentado no es cuántos comandos conoce, sino **cómo piensa cuando algo falla**. Este documento cubre los patrones mentales que aplican los administradores de sistemas para diagnosticar problemas rápidamente.

> Regla de oro: **"Primero verifica lo obvio"**. La causa más probable suele ser la más simple.

---

## Patrones normales vs anómalos

### CPU

| Patrón | Normal | Anómalo |
|--------|--------|---------|
| Uso sostenido | 10-40% (servidor web), 20-60% (base de datos) | 90-100% por más de 5 minutos |
| Variación | Sube y baja con el tráfico | Plano al 100% (bucle infinito) |
| Procesos | Muchos procesos en S (sleeping) | Un proceso en R (running) permanentemente |

### Memoria

| Patrón | Normal | Anómalo |
|--------|--------|---------|
| RAM usada | 60-80% (Linux usa RAM libre para cache) | 95-100% con swap activo |
| Swap | 0 KB usado | Swap creciendo = falta de RAM |
| Crecimiento | Estable tras el arranque | Un proceso que crece sin parar = memory leak |

### Disco

| Patrón | Normal | Anómalo |
|--------|--------|---------|
| Espacio | <80% usado | >90% = riesgo, >95% = crítico |
| I/O wait | <5% | >20% = disco cuello de botella |
| Inodos | Muchos libres | 100% inodos usados (aunque haya espacio) |

### Red

| Patrón | Normal | Anómalo |
|--------|--------|---------|
| Latencia local | <1ms (misma red) | >10ms (switch saturado) |
| Latencia internet | 10-100ms (según distancia) | >300ms o timeouts |
| Paquetes perdidos | 0% | >1% sostenido = problema |
| Conexiones TIME_WAIT | Cientos (normal en web servers) | Miles sin bajar = fuga de sockets |

---

## Lectura de logs

### Formato syslog estándar

```
<Ene 15 14:30:22> <hostname> <servicio>[<PID>]: <mensaje>
```

Ejemplo:
```
Jan 15 14:30:22 server1 sshd[1234]: Failed password for root from 10.0.0.5 port 54321 ssh2
```

**Campos clave:**
1. Fecha/hora → cuándo ocurrió
2. Hostname → qué servidor
3. Servicio[PID] → qué proceso (sshd, nginx, kernel)
4. Mensaje → qué pasó

### Niveles de severidad (syslog)

| Código | Nivel | Significado |
|--------|-------|-------------|
| 0 | emerg | Sistema inusable |
| 1 | alert | Acción inmediata requerida |
| 2 | crit | Condición crítica |
| 3 | err | Error |
| 4 | warning | Advertencia |
| 5 | notice | Normal pero importante |
| 6 | info | Informativo |
| 7 | debug | Depuración |

> En producción: enfocate en `emerg`, `alert`, `crit`, `err`. Warning puede esperar. Info y debug son ruido.

### Cómo leer un log de ataque

```
# Intento de fuerza bruta SSH
Jan 15 14:30:22 server1 sshd[1234]: Failed password for root from 10.0.0.5 port 54321 ssh2
Jan 15 14:30:23 server1 sshd[1235]: Failed password for root from 10.0.0.5 port 54322 ssh2
Jan 15 14:30:24 server1 sshd[1236]: Failed password for admin from 10.0.0.5 port 54323 ssh2
```

**Patrón:** misma IP, múltiples puertos origen, distintos usuarios, cada segundo → fuerza bruta.

```
# Escaneo de puertos
Jan 15 14:30:22 server1 kernel: [IPTABLES] IN=eth0 SRC=10.0.0.5 DPT=22 SYN
Jan 15 14:30:22 server1 kernel: [IPTABLES] IN=eth0 SRC=10.0.0.5 DPT=80 SYN
Jan 15 14:30:22 server1 kernel: [IPTABLES] IN=eth0 SRC=10.0.0.5 DPT=443 SYN
```

**Patrón:** misma IP, múltiples puertos en el mismo segundo → escaneo automatizado.

---

## Latencia vs pérdida de paquetes

Dos problemas que parecen iguales pero se diagnostican distinto.

### Latencia alta (RTT alto)

**Síntoma:** `ping` responde pero tarda 300ms+. Las conexiones TCP abren lento.

**Causas típicas:**
- Distancia geográfica (Europa → Australia: ~200ms)
- Enlace saturado (bufferbloat)
- Routing subóptimo
- ISP con congestión

**Diagnóstico:**
```bash
# mtr muestra la latencia por salto
mtr google.com

# La latencia sube gradualmente → distancia
# La latencia sube de golpe en un salto → ese router está lento
```

### Pérdida de paquetes

**Síntoma:** `ping` muestra `Request timeout` intermitente. Las conexiones TCP se cortan.

**Causas típicas:**
- Enlace físico defectuoso (cable, fibra)
- Switch/buffer saturado
- Interferencia WiFi
- ISP con sobresuscripción

**Diagnóstico:**
```bash
# ping con conteo de pérdida
ping -c 100 google.com | grep loss

# tcpdump muestra retransmisiones
tcpdump -i any -c 100 | grep "retransmission"
```

| Medida | Latencia | Pérdida |
|--------|----------|---------|
| `ping` | Responde lento | No responde a veces |
| `mtr` | Saltos lentos | Saltos con pérdida |
| TCP | Slow start, ventana pequeña | Retransmisiones constantes |
| Causa común | Distancia/saturación | Físico/saturación extrema |

---

## Errores comunes y su interpretación

### Conexión rechazada (Connection refused)

```bash
$ curl localhost:8080
curl: (7) Failed to connect to localhost port 8080: Connection refused
```

**Significa:** el puerto está cerrado. No hay ningún proceso escuchando ahí.

**Causas:**
- El servicio no está corriendo: `systemctl status <servicio>`
- El servicio escucha en otro puerto: `ss -tuln | grep 8080`
- Firewall bloqueando (en realidad firewall da "no route to host", no "connection refused")

### Conexión timed out

```bash
$ ping 10.0.0.50
Request timeout for icmp_seq 0
```

**Significa:** el host no responde en absoluto.

**Causas:**
- El host está apagado
- Firewall intermedio bloqueando (DROP)
- Ruta incorrecta
- Switch apagado o puerto deshabilitado

### No route to host

```bash
$ ssh 10.0.0.100
ssh: connect to host 10.0.0.100 port 22: No route to host
```

**Significa:** el kernel no tiene ruta al destino.

**Causas:**
- No hay ruta en la tabla de enrutamiento: `ip route show`
- Gateway incorrecto
- Red destino no accesible

### Disk full

```bash
$ touch /tmp/test
touch: cannot touch '/tmp/test': No space left on device
```

**Causas:**
- Disco lleno: `df -h`
- Inodos agotados: `df -i`
- Archivo grande abierto pero borrado (ocupa espacio): `lsof | grep deleted`

### Out of Memory (OOM)

```bash
$ dmesg | grep -i oom
[12345.678] oom-killer: [...]
```

**Significa:** el kernel mató un proceso para liberar memoria.

**Causas:**
- Aplicación con memory leak
- Más procesos de los que la RAM puede soportar
- Swap insuficiente o desactivado

### Too many open files

```bash
$ ulimit -n
1024
$ some_app
(Error: too many open files)
```

**Significa:** el proceso alcanzó el límite de archivos abiertos del sistema.

**Solución:** aumentar el ulimit:
```bash
ulimit -n 65536
# O en /etc/security/limits.conf
```

---

## El orden del diagnóstico

Cuando algo falla, este orden evita pérdidas de tiempo:

```
1. ¿Está el servicio corriendo?           → systemctl status
2. ¿Está escuchando en el puerto correcto? → ss -tuln
3. ¿El firewall lo permite?                → iptables -L -n / ufw status
4. ¿Hay conectividad de red?               → ping, traceroute
5. ¿Resuelve DNS?                          → dig, nslookup
6. ¿Hay recursos suficientes?              → free -h, df -h, top
7. ¿Los logs muestran errores?             → journalctl -xe, tail log
```

> **No saltees pasos.** Cada paso descarta una causa completa.

---

## Checklist mental ante un incidente

```bash
# 1. ¿Qué cambió?
# Antes de buscar causas complejas, preguntate:
# - ¿Se actualizó algo? (apt history, yum history)
# - ¿Se cambió una config? (git diff, backup diff)
# - ¿Se agregó un usuario? (cat /etc/passwd)
# - ¿Se reinició algo? (last reboot, uptime)

# 2. ¿Es reproducible?
# Si el error es intermitente, es más difícil.
# Si es constante, es más fácil.

# 3. ¿Afecta a todo o a una parte?
# Todo el sitio caído = infraestructura (red, DNS, load balancer)
# Una ruta específica = aplicación (código, base de datos)

# 4. ¿Hay monitoreo que lo haya visto?
# - netdata / grafana / prometheus
# - Logs anteriores

# 5. ¿Hay un backup / rollback disponible?
# Si no estás seguro de lo que estás haciendo, NO CAMBIES NADA.
# Hacé backup primero, aplicá el cambio, probá, si falla: rollback.

# 6. Documentá
# - Qué hiciste
# - Por qué lo hiciste
# - Qué resultado obtuviste
# - Si no funcionó, qué probarías después
```

---

## 🔗 Referencias

- [`guides/systemd_journalctl.md`](../guides/systemd_journalctl.md) — análisis de logs
- [`guides/ip_ss.md`](../guides/ip_ss.md) — diagnóstico de red
- [`guides/ping_traceroute.md`](../guides/ping_traceroute.md) — latencia y pérdida
- [`guides/tcpdump.md`](../guides/tcpdump.md) — captura de paquetes
- [`guides/production_server.md`](../guides/production_server.md) — monitoreo y recursos
- [`scenarios/system/01-top-processes-and-resources.md`](../scenarios/system/01-top-processes-and-resources.md) — diagnóstico de procesos
- [`scenarios/networking/02-analyze-web-traffic-patterns.md`](../scenarios/networking/02-analyze-web-traffic-patterns.md) — patrones de tráfico
