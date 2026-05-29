⬅️ [Volver al README principal](../README.md)

---

## 🧭 Navegación

- 🧠 [concepts/](../concepts/) — pensar como sysadmin
- 🧪 [labs/](../labs/) — práctica
- 🚨 [scenarios/](../scenarios/) — casos reales

---

# 🐧 sys-admin-guides

Colección completa de guías de referencia para administración de servidores Linux y redes. **37 guías** que cubren cada herramienta desde lo más básico hasta escenarios profesionales, explicando cada opción y la interpretación de salidas en contextos de éxito, falla y ataque.

---

## 🎯 Cuándo usar esta sección

Usá guides/ cuando:

- necesitás aprender una herramienta específica
- querés entender opciones y flags
- necesitás referencia rápida para ejecutar comandos
- querés interpretar salidas correctamente

👉 Esto es tu caja de herramientas

---

## 🔄 Flujo recomendado

```text
concepts → guides → labs → scenarios
entender → aprender → practicar → aplicar
```

---

## 📚 Guías incluidas

### Procesamiento de texto y datos

| Guía | Nivel | Descripción |
|------|-------|-------------|
| [`awk.md`](awk.md) | 🟡 Intermedio | Lenguaje de procesamiento por campos. Patrones, arrays, funciones, getline, combinaciones |
| [`sed.md`](sed.md) | 🟡 Intermedio | Editor de flujo. Sustituciones, rangos, hold space, branching, edición in-place |
| [`grep.md`](grep.md) | 🟢 Básico | Búsqueda con expresiones regulares. PCRE, contexto, recursividad, escenarios de seguridad |
| [`cut.md`](cut.md) | 🟢 Básico | Extracción de columnas por caracteres, campos y bytes |
| [`sort.md`](sort.md) | 🟢 Básico | Ordenamiento alfabético, numérico, por campos, versiones, humano |
| [`uniq.md`](uniq.md) | 🟢 Básico | Filtrado y conteo de duplicados |
| [`wc.md`](wc.md) | 🟢 Básico | Conteo de líneas, palabras, caracteres y bytes |
| [`find.md`](find.md) | 🟡 Intermedio | Búsqueda de archivos por nombre, tipo, tamaño, fecha, permisos, contenido |
| [`xargs.md`](xargs.md) | 🟡 Intermedio | Construcción de comandos desde stdin. Paralelismo, seguridad con `-0` |

### Redes y conectividad

| Guía | Nivel | Descripción |
|------|-------|-------------|
| [`curl.md`](curl.md) | 🟡 Intermedio | Cliente HTTP. Requests, headers, autenticación, APIs, debugging |
| [`dig_curl.md`](dig_curl.md) | 🟡 Intermedio | DNS (dig) y transferencias HTTP/API (curl). Autenticación, SSL, medición de tiempos |
| [`ip_ss.md`](ip_ss.md) | 🟢 Básico | Configuración de red (ip) y sockets (ss). Interfaces, rutas, ARP, estados TCP |
| [`tcpdump.md`](tcpdump.md) | 🔴 Avanzado | Captura de paquetes. Filtros BPF, análisis de ataques, resolución de problemas |
| [`ping_traceroute.md`](ping_traceroute.md) | 🟢 Básico | Diagnóstico ICMP. ping, traceroute, mtr, interpretación de TTL y latencia |
| [`nmap.md`](nmap.md) | 🔴 Avanzado | Escaneo de puertos y servicios. NSE, detección de SO, evasión de firewalls |
| [`iptables.md`](iptables.md) | 🔴 Avanzado | Firewall Netfilter. Reglas, NAT, mitigación de ataques, rate limiting |
| [`network_segmentation.md`](network_segmentation.md) | 🔴 Avanzado | VLANs, subnetting, router Linux, ACLs con iptables, DHCP por segmento, bridges |

### Sistema y monitoreo

| Guía | Nivel | Descripción |
|------|-------|-------------|
| [`ps.md`](ps.md) | 🟢 Básico | Listado de procesos. Formatos, filtros, árboles, ordenamiento por CPU/memoria |
| [`top.md`](top.md) | 🟡 Intermedio | Monitoreo interactivo de procesos y recursos. Ordenamiento, filtros, batch mode |
| [`htop.md`](htop.md) | 🟡 Intermedio | Visor interactivo de procesos. Árbol, búsqueda, filtros, atajos de teclado |
| [`free.md`](free.md) | 🟢 Básico | Memoria RAM y swap. buffers/cache, disponible vs libre, interpretación |
| [`df.md`](df.md) | 🟢 Básico | Espacio en disco por filesystem. Tipos, montajes, inodos |
| [`du.md`](du.md) | 🟡 Intermedio | Uso de disco por directorio. Sumarizar, excluir, ordenar por tamaño |
| [`vmstat.md`](vmstat.md) | 🟡 Intermedio | Estadísticas de sistema: procesos, memoria, swap, I/O, CPU |
| [`iostat.md`](iostat.md) | 🔴 Avanzado | Estadísticas de I/O de dispositivos y CPU. Latencia, throughput, await, svctm |
| [`dmesg.md`](dmesg.md) | 🟡 Intermedio | Ring buffer del kernel. Hardware, drivers, errores de dispositivo, OOM |
| [`watch.md`](watch.md) | 🟢 Básico | Ejecución periódica de comandos. Monitoreo en tiempo real, diff, precisión |
| [`lsof.md`](lsof.md) | 🔴 Avanzado | Archivos abiertos por procesos. Puertos, conexiones, usuarios, directorios |
| [`strace.md`](strace.md) | 🔴 Avanzado | Trazado de llamadas al sistema. Syscalls, señales, errores, seguimiento de procesos |
| [`systemd_journalctl.md`](systemd_journalctl.md) | 🟡 Intermedio | Gestión de servicios (systemctl) y logs (journalctl). Análisis de arranque, filtros |
| [`ssh.md`](ssh.md) | 🟡 Intermedio | Administración remota, hardening, claves, túneles, ProxyJump, automatización |

### Infraestructura y producción

| Guía | Nivel | Descripción |
|------|-------|-------------|
| [`nginx.md`](nginx.md) | 🟡 Intermedio | Servidor web. Virtual hosts, proxy reverso, SSL, rate limiting, geo, load balancing, caché |
| [`storage_backup.md`](storage_backup.md) | 🟡 Intermedio | NFS, Samba, rsync, rclone, restic, 3-2-1, rotación, monitoreo |
| [`production_server.md`](production_server.md) | 🔴 Avanzado | Sysctl, ulimits, swap, logrotate, systemd resource control, Docker en producción, fail2ban |

### Alpine Linux

| Guía | Nivel | Descripción |
|------|-------|-------------|
| [`apk.md`](apk.md) | 🟢 Básico | Gestor de paquetes de Alpine. Búsqueda, instalación, repositorios, actualización |
| [`openrc.md`](openrc.md) | 🟡 Intermedio | Sistema de inicio y servicios de Alpine. rc-service, rc-update, runlevels |
| [`busybox.md`](busybox.md) | 🟢 Básico | Toolchain mínima de Alpine. Comandos integrados, detección de linked binaries |

---

## 🎯 Enfoque

Cada guía está estructurada para servir como **referencia rápida** y como **material de estudio**:

- **Cada opción explicada**: no solo se muestra `-d`, se explica qué hace
- **Salidas interpretadas**: qué significa cada columna, cada flag, cada código de error
- **Escenarios reales**: ejemplos de logs, configuraciones, monitoreo
- **Escenarios de ataque**: cómo detectar SYN flood, ARP spoofing, port scans, DDoS
- **Escenarios de falla**: qué significa un timeout, un RST, un CLOSE_WAIT, un NXDOMAIN
- **Combinaciones**: cómo se conectan las herramientas (awk+sort, find+xargs, grep+sed, etc.)
- **Uno-liners**: comandos listos para copiar y pegar

---

## 🚀 Cómo usar

```bash
git clone git@github.com:lumusitech/learning-sys-admin-guides.git
cd learning-sys-admin-guides
```

⬅️ [Volver al README principal](../README.md)
