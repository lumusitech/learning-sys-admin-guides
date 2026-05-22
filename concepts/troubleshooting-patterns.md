TROUBLESHOOTING PATTERNS
=========================

Problema → qué herramienta usar (no cómo)

LOGS
----
Buscar eventos     → grep, journalctl
Agrupar por tipo   → sort | uniq -c | sort -rn
Extraer campo      → awk, cut
Filtrar por tiempo  → sed (rangos), journalctl -S
Errores críticos   → dmesg, journalctl -p err
Seguir en vivo     → tail -f | grep

RED
---
Puertos abiertos   → ss -tuln, nmap
Conectividad       → ping, traceroute, mtr
Ancho de banda     → vnstat, iftop, bmon
Capturar tráfico   → tcpdump, wireshark (tshark)
DNS                → dig, nslookup, host
Firewall           → iptables -L -n, ufw status
Latencia vs pérdida → mtr (muestra ambos por salto)

PROCESOS
--------
CPU alto           → ps aux --sort=-%cpu, top, htop
Memoria alta       → ps aux --sort=-%mem, free -h
Disco lento        → iostat -x, iotop, dstat
Archivos abiertos  → lsof, /proc/PID/fd
Zombies            → ps aux | awk '$8 ~ /Z/'
Hilos              → ps -eLf, /proc/PID/task

SISTEMA
-------
Espacio disco      → df -h, du -sh /*
Inodos             → df -i
Swap               → swapon --show, free -h
Kernel             → uname -a, sysctl -a
Arranque            → systemd-analyze blame, dmesg
OOM killer         → dmesg | grep -i oom
Actualizaciones    → apt list --upgradable

ERRORES COMUNES
--------------
Connection refused    → servicio no corre / puerto equivocado
Connection timed out → firewall DROP / host caído
No route to host     → ruta incorrecta / gateway caído
Disk full            → df -h, du -sh /*
Too many open files  → ulimit -n, /proc/sys/fs/file-max
Out of memory        → dmesg | grep oom, free -h
Segfault             → dmesg, journalctl -p err
Permission denied    → permisos / dueño incorrecto

PASO RÁPIDO
-----------
1. ¿Qué cambió? (último deploy, config, reboot)
2. ¿El servicio corre? (systemctl status)
3. ¿Escucha? (ss -tuln)
4. ¿Firewall? (iptables -L)
5. ¿Red? (ping, traceroute)
6. ¿Logs? (journalctl -xe)
