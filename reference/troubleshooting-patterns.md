# Troubleshooting Patterns — Referencia rápida

Problema → qué herramienta usar (no cómo)

## 👁️ Logs

Buscar eventos     → grep, journalctl
Agrupar por tipo   → sort | uniq -c | sort -rn
Extraer campo      → awk, cut
Filtrar por tiempo  → sed (rangos), journalctl -S
Errores críticos   → dmesg, journalctl -p err
Seguir en vivo     → tail -f | grep

## 🌐 Red

Puertos abiertos   → ss -tuln, nmap
Conectividad       → ping, traceroute, mtr
Ancho de banda     → vnstat, iftop, bmon
Capturar tráfico   → tcpdump, wireshark (tshark)
DNS                → dig, nslookup, host
Firewall           → iptables -L -n, ufw status
Latencia vs pérdida → mtr (muestra ambos por salto)

## 🔥 Procesos

CPU alto           → ps aux --sort=-%cpu, top, htop
Memoria alta       → ps aux --sort=-%mem, free -h
Disco lento        → iostat -x, iotop, dstat
Archivos abiertos  → lsof, /proc/PID/fd
Zombies            → ps aux | awk '$8 ~ /Z/'
Hilos              → ps -eLf, /proc/PID/task

## 💾 Sistema

Espacio disco      → df -h, du -sh /*
Inodos             → df -i
Swap               → swapon --show, free -h
Kernel             → uname -a, sysctl -a
Arranque            → systemd-analyze blame, dmesg
OOM killer         → dmesg | grep -i oom
Actualizaciones    → apt list --upgradable

## ⚠️ Errores comunes

Connection refused    → servicio no corre / puerto equivocado
Connection timed out → firewall DROP / host caído
No route to host     → ruta incorrecta / gateway caído
Disk full            → df -h, du -sh /*
Too many open files  → ulimit -n, /proc/sys/fs/file-max
Out of memory        → dmesg | grep oom, free -h
Segfault             → dmesg, journalctl -p err
Permission denied    → permisos / dueño incorrecto

## 🧠 Patrones de diagnóstico

### Zombie processes

Detectar    → `ps axo stat,ppid,pid,comm | awk '$1 ~ /^Z/'`
Qué indica  → el padre no ejecutó wait()/waitpid()
Qué hacer   → identificar PPID, revisar el proceso padre
No sirve    → matar el zombie directamente (ya está terminado)

### OOM Killer

Detectar       → `dmesg | grep -i oom` o `journalctl -k | grep -i oom`
Señales        → proceso terminado con SIGKILL sin explicación, `dmesg` muestra "Out of memory"
Contraindicación → OOM killer NO se desactiva. La solución es reducir presión de memoria
Pasos          → `free -h` (¿swap activo?), `ps aux --sort=-%mem` (top consumidores), ajustar límites

### High load vs High CPU

Load alto + CPU alto    → proceso consumiendo CPU real (runaway, loop, batch legítimo)
Load alto + CPU bajo    → esperando I/O (disco, red, locks). Revisar `%wa` en `vmstat` o `top`
Load alto + CPU medio   → mixto: varios procesos entre CPU e I/O
Load alto sin proceso visible → I/O en montura NFS/disco externo (procesos en D)

### Swap vs Cache pressure

Swap usado creciendo (+ `si`/`so` activos) → presión real de memoria, falta RAM
Swap usado pero estable                   → puede ser normal si se usó en pico anterior
Caché de disco baja + swap entrando       → sistema en memoria ajustada (prioriza liberar caché)
Caché de disco alta + swap en 0          → saludable: RAM alcanza, disco usa caché
Comando clave → `free -h` (columna `available`), `vmstat 1` (columnas `si`, `so`)

## ⚡ Paso rápido

1. ¿Qué cambió? (último deploy, config, reboot)
2. ¿El servicio corre? (systemctl status)
3. ¿Escucha? (ss -tuln)
4. ¿Firewall? (iptables -L)
5. ¿Red? (ping, traceroute)
6. ¿Logs? (journalctl -xe)

---

## 🔗 Ver también

- [`symptom-to-tool`](symptom-to-tool.md) — mapa síntoma → herramienta
- [`signals-table`](signals-table.md) — señales de Linux para gestión de procesos
- [`tcp-connection-states`](tcp-connection-states.md) — estados TCP y su significado
- [`http-status-codes`](http-status-codes.md) — códigos HTTP en troubleshooting
