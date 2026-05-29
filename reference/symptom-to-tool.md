# Síntoma → Herramienta — Mapa rápido de diagnóstico

Cuándo el problema es claro pero no sabés qué comando usar.

---

## 🔥 CPU

| Síntoma | Qué puede ser | Comando |
|---------|--------------|---------|
| Servidor lento, CPU al 100% | Proceso runaway o loop infinito | `top` → identificar PID, `ps aux --sort=-%cpu \| head -10` |
| CPU alta sostenida pero ningún proceso la consume | I/O wait malinterpretado o interrupciones de hardware | `vmstat 1` (columna `wa`), `mpstat -P ALL` |
| Load alto, CPU bajo | Cuello de botella de disco o I/O | `vmstat 1` (columna `b`), `iostat -x 1` |
| CPU de sistema (kernel) alta | Driver problemático, hardware, DDoS | `mpstat -P ALL`, `watch -n 1 'cat /proc/interrupts'` |
| Context switches altísimos | Threads excesivos, lock contention | `vmstat 1` (columna `cs`), `pidstat -w` |

---

## 💾 Memoria

| Síntoma | Qué puede ser | Comando |
|---------|--------------|---------|
| OOM killer matando procesos | Memoria agotada | `dmesg \| grep -i oom`, `free -h`, `ps aux --sort=-%mem` |
| Swap usado y creciendo | Presión real de memoria | `free -h`, `vmstat 1` (columnas `si`/`so`) |
| Memoria disponible baja pero sin swap | Uso normal de caché de disco | `free -h` (columna `available`) |
| Proceso individual crece sin límite | Memory leak | `watch -n 5 'ps -p <PID> -o rss,vsz,cmd'` |
| `Cannot allocate memory` pero hay RAM libre | Límite de cgroups o ulimit alcanzado | `ulimit -a`, `cat /proc/<PID>/limits` |

---

## 💽 Disco

| Síntoma | Qué puede ser | Comando |
|---------|--------------|---------|
| `No space left on device` | Disco lleno | `df -h`, `du -sh /* 2>/dev/null \| sort -rh \| head -10` |
| Disco con espacio pero no se puede escribir | Inodos agotados | `df -i`, `find . -type f \| wc -l` |
| Servidor lento, comandos básicos tardan | I/O saturado | `iostat -x 1`, `vmstat 1` (columna `wa`) |
| Archivos no se borran aunque `rm` | Filesystem montado como read-only | `mount \| grep ro`, `dmesg \| tail` (errores de disco) |
| `Device or resource busy` | Filesystem montado o proceso usando el recurso | `lsof <ruta>`, `fuser <ruta>` |

---

## 🌐 Red

| Síntoma | Qué puede ser | Comando |
|---------|--------------|---------|
| No se puede conectar a un servicio | Puerto cerrado o firewall | `ss -tuln \| grep <puerto>`, `nc -zv <host> <puerto>` |
| Timeout de conexión | Firewall DROP, host caído | `ping <host>`, `mtr <host>`, `traceroute <host>` |
| Conexión rechazada | Servicio no corriendo o firewall REJECT | `systemctl status <svc>`, `ss -tuln` |
| Latencia alta intermitente | Congestión de red, pérdida de paquetes | `mtr <host>`, `ping -c 100 <host>` |
| DNS no resuelve | DNS caído o mal configurado | `dig <dominio>`, `nslookup <dominio>`, `cat /etc/resolv.conf` |
| Conexiones en CLOSE_WAIT | App no cierra sockets (memory leak de FDs) | `ss -tan \| grep CLOSE_WAIT \| wc -l` |
| Conexiones en TIME_WAIT excesivas | Alta rotación de conexiones | `ss -tan \| grep TIME_WAIT \| wc -l` |

---

## 🔒 Seguridad

| Síntoma | Qué puede ser | Comando |
|---------|--------------|---------|
| IP remota hace muchas conexiones fallidas | Fuerza bruta SSH | `journalctl -u ssh -n 1000 \| awk '/Failed/ {print $(NF-3)}' \| sort \| uniq -c \| sort -rn` |
| Puerto abierto que no debería estar | Servicio no autorizado o backdoor | `ss -tuln`, `nmap -sV localhost` |
| Proceso con nombre sospechoso | Malware o crypto miner | `ps aux --sort=-%cpu \| head -10`, inspeccionar binary con `file` y `strings` |
| Archivos modificados sin autorización | Intrusión o malware | `find /etc -type f -mtime -1 -ls` (archivos recientes en /etc) |
| Usuarios desconocidos en el sistema | Backdoor de acceso | `cat /etc/passwd \| awk -F: '$3 > 1000'`, `lastlog` |

---

## 👁️ Logs

| Síntoma | Qué puede ser | Comando |
|---------|--------------|---------|
| App reporta error pero no hay logs | Permisos de escritura de logs | `ls -la <logdir>`, `touch <logfile>` como el usuario del servicio |
| Logs crecen sin control | Log rotation mal configurado | `ls -lh /var/log/`, `logrotate -d /etc/logrotate.conf` |
| No se ven logs de systemd | Servicio no usa journald | `journalctl -u <svc> -n 50 --no-pager`, revisar `StandardOutput=` en unit |
| Logs con timestamps incorrectos | Zona horaria mal configurada | `timedatectl`, `date`, `date -u` |
| Demasiados errores en poco tiempo | Ataque, bug, config mal escrita | `journalctl -p err --since "5 min ago"` |

---

## 🔁 Servicios

| Síntoma | Qué puede ser | Comando |
|---------|--------------|---------|
| Servicio no arranca | Config inválida, dependencia faltante, puerto ocupado | `systemctl status <svc>`, `journalctl -u <svc> -n 50` |
| Servicio arranca pero muere al instante | Error de configuración crítica | `systemctl status <svc>` (ver `Main PID` y exit code) |
| Servicio lento después de restart | Caché fría, conexiones estableciéndose | `systemctl status`, `uptime`, revisar load inmediatamente después |
| Servicio no responde a kill | Estado D (uninterruptible sleep) | `ps -p <PID> -o stat,pid,wchan`, si es D hay que esperar I/O o reiniciar |

---

## 🔗 Ver también

- [`troubleshooting-patterns`](troubleshooting-patterns.md) — Problema → herramienta
- [`top`](../guides/top.md) — visión general del sistema
- [`vmstat`](../guides/vmstat.md) — CPU, memoria, I/O
- [`iostat`](../guides/iostat.md) — métricas de disco
- [`ip_ss`](../guides/ip_ss.md) — red y puertos
