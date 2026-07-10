
# Linux FHS — Mapa del sistema de archivos para sysadmin

## 🧠 ¿Qué es?

El Filesystem Hierarchy Standard (FHS) define la estructura de directorios en Linux. No es solo una convención: es un mapa que todo sysadmin debe conocer para saber dónde mirar cuando algo falla.

Cada directorio tiene un propósito específico:

- `/proc` — sistema de archivos virtual del kernel y procesos
- `/sys` — jerarquía del kernel orientada a dispositivos
- `/etc` — configuración del sistema
- `/var/log` — registros de eventos del sistema

---

## 🎯 ¿Por qué importa?

Un sysadmin que no conoce el FHS pierde tiempo buscando donde no debe:

- no sabe que `/proc/meminfo` tiene métricas de memoria más detalladas que `free`
- no sabe que los parámetros de red en `/proc/sys/net/` se pueden modificar en caliente
- no sabe que `/etc/` contiene configuraciones, no binarios
- no sabe que `/var/log/` puede llenar el disco si no se rota

Cada uno de estos directorios es una fuente de diagnóstico. Ignorarlos es intentar diagnosticar sin acceder a los instrumentos.

---

## 📁 `/proc` — El sistema de archivos de procesos

### ¿Qué contiene?

`/proc` es un pseudo-sistema de archivos que el kernel genera en memoria. No ocupa espacio en disco. Cada archivo es una ventana al estado interno del kernel y los procesos.

### Archivos clave para diagnóstico

| Archivo | Qué muestra | Equivalente en comando |
|---------|-------------|------------------------|
| `/proc/cpuinfo` | Información de CPU (modelo, núcleos, flags) | `lscpu` |
| `/proc/meminfo` | Memoria total, usada, buffers, caché | `free -v` |
| `/proc/loadavg` | Load average del sistema | `uptime`, `top` |
| `/proc/uptime` | Tiempo encendido + tiempo idle | `uptime` |
| `/proc/stat` | Estadísticas de CPU, contexto, procesos | `vmstat`, `mpstat` |
| `/proc/diskstats` | I/O de disco por dispositivo | `iostat` |
| `/proc/net/dev` | Tráfico de red por interfaz | `ifconfig`, `ip -s` |
| `/proc/net/tcp` | Conexiones TCP activas | `ss -t` |
| `/proc/partitions` | Particiones detectadas | `fdisk -l` |
| `/proc/mounts` | Sistemas de archivos montados | `mount` |
| `/proc/swaps` | Swap en uso | `swapon --show` |
| `/proc/version` | Versión del kernel | `uname -a` |
| `/proc/sys/` | Parámetros del kernel modificables | `sysctl` |

### Directorios de procesos

Cada proceso en ejecución tiene un directorio `/proc/<PID>/`:

| Archivo | Qué contiene |
|---------|-------------|
| `fd/` | Archivos abiertos (file descriptors) |
| `environ` | Variables de entorno |
| `cmdline` | Línea de comando |
| `status` | Estado, memoria, privilegios |
| `cwd` | Enlace al directorio de trabajo |
| `exe` | Enlace al binario ejecutado |
| `limits` | Límites de recursos (ulimit) |
| `maps` | Regiones de memoria mapeada |
| `io` | Estadísticas de I/O del proceso |
| `net/` | Conexiones de red del proceso |

### ⚠️ Lo que NO hacer

- No escribir directamente en `/proc/<PID>/` a menos que sepas lo que haces
- No borrar archivos de `/proc/` — no existen realmente
- No modificar `/proc/sys/` sin entender la implicación — es persistencia en caliente, se pierde al reiniciar

### Relación con herramientas

Muchos comandos de diagnóstico leen de `/proc`:

- `ps` → `/proc/<PID>/status`, `/proc/<PID>/cmdline`
- `top` → `/proc/stat`, `/proc/meminfo`, `/proc/<PID>/`
- `free` → `/proc/meminfo`
- `vmstat` → `/proc/stat`, `/proc/meminfo`
- `iostat` → `/proc/diskstats`
- `lsof` → `/proc/<PID>/fd/`
- `ss` → `/proc/net/tcp`, `/proc/net/udp`
- `uptime` → `/proc/uptime`, `/proc/loadavg`

---

## 📁 `/sys` — El sistema de archivos de dispositivos

### ¿Qué contiene?

`/sys` expone dispositivos, drivers y jerarquía de buses del kernel. Mientras que `/proc` muestra procesos y estado general del kernel, `/sys` se enfoca en la topología del hardware.

### Arquitectura

```text
/sys/
├── block/       → dispositivos de bloque (discos, particiones)
├── bus/         → buses del sistema (pci, usb, i2c, spi)
├── class/       → clasificación funcional (net, input, sound, video)
├── dev/         → dispositivos con número major:minor
├── devices/     → árbol completo de dispositivos físicos
├── firmware/    → firmware cargado por el kernel
├── fs/          → sistemas de archivos soportados
├── hypervisor/  → información de virtualización
├── kernel/      → parámetros y configuraciones del kernel
├── module/      → módulos del kernel cargados
├── power/       → estados de energía
└── slab/        → información del slab allocator
```

### Archivos clave para diagnóstico

| Ruta | Qué muestra |
|------|-------------|
| `/sys/class/net/<if>/` | Estado y estadísticas de interfaz de red |
| `/sys/class/net/<if>/statistics/` | Paquetes, errores, drops por interfaz |
| `/sys/block/<disk>/` | Parámetros del disco (tamaño, modelo, cola) |
| `/sys/block/<disk>/queue/` | Scheduler de I/O, tamaño de cola, merges |
| `/sys/devices/system/cpu/` | CPUs, frecuencias, gobernadores |
| `/sys/devices/system/cpu/cpu<N>/cpufreq/` | Frecuencia actual y escalado |
| `/sys/power/state` | Estados de suspensión disponibles |

### ⚠️ Lo que NO hacer

- Modificar `/sys/` sin verificar permisos — algunos archivos controlan hardware físicamente
- Escribir en `/sys/block/<disk>/device/delete` sin querer — desconecta el disco en caliente

### Relación con herramientas

- `ip link` → `/sys/class/net/<if>/`
- `lscpu` → `/sys/devices/system/cpu/`
- `lsblk` → `/sys/block/`
- `lspci` → `/sys/bus/pci/devices/`
- `cpupower` → `/sys/devices/system/cpu/cpu<N>/cpufreq/`
- `ethtool -S` → `/sys/class/net/<if>/statistics/`

---

## 📁 `/etc` — Configuración del sistema

### ¿Qué contiene?

`/etc` almacena archivos de configuración estática del sistema y servicios. Es el primer lugar donde mirar cuando un servicio no arranca o se comporta de forma inesperada.

### Archivos clave

| Archivo | Qué configura |
|---------|--------------|
| `/etc/ssh/sshd_config` | Servidor SSH |
| `/etc/nginx/nginx.conf` | Nginx |
| `/etc/apache2/apache2.conf` | Apache |
| `/etc/network/interfaces` | Red en Debian/Ubuntu |
| `/etc/sysconfig/network-scripts/` | Red en RHEL/CentOS |
| `/etc/resolv.conf` | DNS nameservers |
| `/etc/hosts` | Resolución local de nombres |
| `/etc/hostname` | Nombre del servidor |
| `/etc/fstab` | Sistemas de archivos al arranque |
| `/etc/crontab` | Tareas programadas globales |
| `/etc/rsyslog.conf` | Configuración de syslog |
| `/etc/ntp.conf` | Sincronización de hora |
| `/etc/security/limits.conf` | Límites de recursos por usuario |
| `/etc/sudoers` | Privilegios sudo |
| `/etc/passwd` | Usuarios del sistema |
| `/etc/shadow` | Contraseñas con hash |
| `/etc/group` | Grupos de usuarios |
| `/etc/issue` | Mensaje de login |
| `/etc/motd` | Mensaje del día |
| `/etc/shells` | Shells válidos |
| `/etc/environment` | Variables de entorno globales |

### ⚠️ Lo que NO hacer

- Editar `/etc/passwd` o `/etc/shadow` directamente — usar `vipw`, `useradd`, `usermod`
- Editar `/etc/sudoers` sin `visudo` — un error de sintaxis bloquea sudo
- No confundir configs en `/etc/` con binarios — para reinstalar un servicio no toques `/etc/`, reinstalá el paquete

### Patrón de diagnóstico

Cuando un servicio falla:

1. Verificar que el archivo de configuración existe en `/etc/<servicio>/`
2. Verificar sintaxis con la herramienta del servicio (nginx -t, sshd -t, named-checkconf)
3. Verificar permisos y propietario del archivo
4. Buscar cambios recientes con `ls -lth /etc/<servicio>/` o `git log` si está versionado

---

## 📁 `/var/log` — Registros del sistema

### ¿Qué contiene?

`/var/log` almacena logs del sistema y aplicaciones. Es la grabadora de vuelo: contiene el historial de eventos, errores y advertencias.

### Archivos clave

| Archivo | Registra |
|---------|----------|
| `/var/log/syslog` | Mensajes del sistema (Debian/Ubuntu) |
| `/var/log/messages` | Mensajes del sistema (RHEL) |
| `/var/log/auth.log` | Intentos de autenticación (Debian/Ubuntu) |
| `/var/log/secure` | Intentos de autenticación (RHEL) |
| `/var/log/kern.log` | Mensajes del kernel |
| `/var/log/dmesg` | Buffer de anillo del kernel |
| `/var/log/nginx/access.log` | Peticiones HTTP (Nginx) |
| `/var/log/nginx/error.log` | Errores de Nginx |
| `/var/log/mysql/error.log` | Errores de MySQL/MariaDB |
| `/var/log/apache2/access.log` | Peticiones HTTP (Apache) |
| `/var/log/apache2/error.log` | Errores de Apache |
| `/var/log/faillog` | Intentos de login fallidos |
| `/var/log/lastlog` | Último login de cada usuario |
| `/var/log/wtmp` | Historial de logins exitosos |
| `/var/log/btmp` | Historial de logins fallidos |
| `/var/log/cron` | Ejecución de tareas cron |
| `/var/log/boot.log` | Mensajes de arranque |

### Rotación de logs

Los logs rotan automáticamente mediante `logrotate`:

```text
/var/log/syslog
              → /var/log/syslog.1         (rotación semanal)
              → /var/log/syslog.2.gz      (comprimido)
              → /var/log/syslog.3.gz
              ...
```

Configuración en `/etc/logrotate.conf` o `/etc/logrotate.d/`.

### ⚠️ Lo que NO hacer

- No borrar `/var/log/` indiscriminadamente — algunos procesos mantienen file descriptors abiertos, el espacio no se libera hasta reiniciar el servicio
- No ignorar `/var/log/` lleno — si el disco de logs se llena, los procesos pueden dejar de escribir o fallar
- No leer logs sin contexto — la hora del evento es tan importante como el mensaje

### Patrón de diagnóstico

Cuando ocurre algo inesperado:

1. Revisar la línea de tiempo con `journalctl --since "1 hour ago"`
2. Si usa syslog clásico, revisar `/var/log/syslog` o `/var/log/messages`
3. Si es un servicio específico, ir a `/var/log/<servicio>/`
4. Filtrar por severidad: `grep -i "error|fail|panic|oom" /var/log/syslog`
5. Correlacionar temporalmente con otros eventos del sistema

---

## 🧠 Modelo mental

Pensá en estos directorios como los paneles de instrumentos de un servidor:

- `/proc` es el **monitor de signos vitales** — te dice en tiempo real qué está pasando con cada proceso y el kernel
- `/sys` es el **panel de control del hardware** — te muestra los dispositivos conectados y permite ajustar parámetros físicos
- `/etc` es la **caja de fusibles y el manual de configuración** — define cómo arranca y se comporta cada servicio
- `/var/log` es la **grabadora de vuelo** — guarda el historial de eventos para que puedas reconstruir qué pasó

Un sysadmin que conoce el FHS no necesita adivinar: sabe exactamente dónde mirar según el tipo de problema.

---

## 🔗 Ver también

- [`ps`](../guides/ps.md) — lectura de procesos desde `/proc`
- [`top`](../guides/top.md) — monitoreo interactivo desde `/proc` y `/sys`
- [`free`](../guides/free.md) — memoria desde `/proc/meminfo`
- [`vmstat`](../guides/vmstat.md) — estadísticas del sistema desde `/proc`
- [`iostat`](../guides/iostat.md) — I/O de disco desde `/proc/diskstats`
- [`lsof`](../guides/lsof.md) — archivos abiertos desde `/proc/<PID>/fd`
- [`systemd_journalctl`](../guides/systemd_journalctl.md) — logs del sistema con systemd
- [`ip_ss`](../guides/ip_ss.md) — redes desde `/proc/net/` y `/sys/class/net/`
- [`tcpdump`](../guides/tcpdump.md) — captura de tráfico
- [`scenario`](../scenarios/system/01-top-processes-and-resources.md) — diagnóstico inicial con herramientas que leen de `/proc`
- [`scenario`](../scenarios/system/06-disk-full-inodes.md) — troubleshooting de disco lleno por inodos y logs en `/var/log/`
- [`how-to-think-like-sysadmin`](how-to-think-like-sysadmin.md) — modelo mental de diagnóstico
- [`baseline-and-anomalies`](baseline-and-anomalies.md) — establecimiento de baseline con métricas de `/proc` y `/sys`
