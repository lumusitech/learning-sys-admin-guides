# TODO — Plan de mejoras

Plan basado en la revisión externa del repositorio. Organizado en fases atómicas, priorizadas por impacto y esfuerzo.

---

## Fase 0 — Links rotos y correcciones urgentes

> Esfuerzo: ~30 min | Prioridad: 🔴 Crítica

### 0.1 — Links con `../` incorrecto en guías hermanas

35 links en 10 guías usan `../filename.md` para referenciar guías en el mismo directorio (`guides/`). El `../` resuelve a la raíz del repo, no a `guides/`. Corregir a `./filename.md` o simplemente `filename.md`.

| Archivo | Links rotos |
|---------|-------------|
| `guides/apk.md` | `../busybox.md`, `../openrc.md`, `../production_server.md` |
| `guides/busybox.md` | `../apk.md`, `../openrc.md`, `../systemd_journalctl.md` |
| `guides/df.md` | `../du.md`, `../find.md`, `../storage_backup.md` |
| `guides/du.md` | `../df.md`, `../find.md`, `../storage_backup.md` |
| `guides/free.md` | `../ps.md`, `../systemd_journalctl.md`, `../top.md`, `../vmstat.md` |
| `guides/iostat.md` | `../production_server.md`, `../ps.md`, `../top.md`, `../vmstat.md` |
| `guides/lsof.md` | `../fuser.md`, `../ip_ss.md`, `../ps.md` |
| `guides/openrc.md` | `../apk.md`, `../busybox.md`, `../systemd_journalctl.md` |
| `guides/ps.md` | `../awk.md`, `../grep.md`, `../kill.md`, `../sort.md`, `../systemd_journalctl.md`, `../top.md` |
| `guides/vmstat.md` | `../free.md`, `../iostat.md`, `../ps.md`, `../top.md` |

### 0.2 — Links a archivos inexistentes

| Archivo | Link roto | Reemplazo |
|---------|-----------|-----------|
| `guides/lsof.md` | `../fuser.md` | Eliminar o crear `fuser.md` |
| `guides/ps.md` | `../kill.md` | Eliminar o crear `kill.md` |
| `guides/tmux.md` | `../scenarios/infrastructure/03-new-server-provisioning.md` | Corregir a `01-migrate-to-production.md` |

### 0.3 — `guides/README.md` desactualizado

- Dice "37 guías" pero hay 39 (sin contar README).
- Faltan `tmux.md` y `redirections.md` en las tablas de índice.

---

## Fase 1 — Quick wins en guías existentes

> Esfuerzo: ~2 hrs | Prioridad: 🟡 Alta

### 1.1 — `guides/awk.md`

- Añadir sección sobre `gawk --sandbox` para entornos restringidos.
- Añadir ejemplo de `PROCINFO` para detectar la implementación (gawk vs mawk vs nawk) en runtime.

### 1.2 — `guides/grep.md`

- Añadir opción `-T` (tab alignment con `--with-filename`).
- Reforzar énfasis en `LANG=C` para acelerar búsquedas (ya se menciona en rendimiento, subir de perfil).
- Añadir ejemplo de `--exclude-dir=node_modules` en uno-liners.

### 1.3 — `guides/tcpdump.md`

- Añadir opción `-z` (compresión de archivos rotados con gzip).
- Añadir ejemplo de filtro BPF por VLAN: `vlan 100`.
- Añadir referencia a `tshark` para decodificación de protocolos compleja.

### 1.4 — `guides/nmap.md`

- Añadir `-sV --version-intensity <0-9>` para controlar agresividad en detección de versiones.
- Añadir ejemplo combinado estándar de auditoría: `nmap -sV -sC -O <target>`.
- Añadir nota sobre `--reason` (por qué nmap clasificó un puerto en ese estado).
- Añadir ejemplos de output parsing con `grep`/`awk` sobre salida `-oG` (grepable).

### 1.5 — `guides/iptables.md`

- Añadir `iptables-apply` para aplicar reglas con rollback automático.
- Añadir nota sobre `ipset` para manejar listas grandes de IPs.

---

## Fase 2 — Mejoras en scenarios y concepts

> Esfuerzo: ~2 hrs | Prioridad: 🟡 Alta

### 2.1 — `scenarios/networking/01-detect-ssh-brute-force.md`

- Añadir alternativa con `awk` puro para monitoreo en tiempo real (reemplazar `sort | uniq -c` que requiere datos agrupados).
- Añadir ejemplo con `fail2ban` como mitigación real (no solo `iptables` directo).

### 2.2 — `scenarios/web/01-performance-and-error-analysis.md`

- Añadir ejemplo de correlación temporal: "los 5xx aumentaron cuando se desplegó X".

### 2.3 — `concepts/how-to-think-like-sysadmin.md`

- Añadir nota: "Los umbrales son referenciales y dependen del hardware; ajustar según baseline del sistema."
- Añadir caso de estudio narrado paso a paso (síntoma → diagnóstico → resolución) aplicando el modelo mental del documento.

---

## Fase 3 — Nueva guía: `guides/nftables.md` ✅ COMPLETADA

> Esfuerzo: ~3 hrs | Prioridad: 🟡 Alta | **PR: #50**

- Guía completa de `nftables` siguiendo la plantilla del skill `sysadmin-guides-skill.md`.
- Tabla de migración `iptables` → `nftables` por tipo de regla.
- Ejemplos prácticos: firewall básico, NAT, rate limiting, persistencia.
- Cubrir diferencias: `nft` vs `iptables` (tablas vs cadenas, familias de protocolo, sets named).
- Portabilidad: disponible en Debian 12+, Ubuntu 22.04+, RHEL 9+, Alpine (kernel).
- Conectar con `scenarios/` existentes que usan `iptables`.

---

## Fase 4 — Nueva guía: `guides/docker.md` ✅ COMPLETADA

> Esfuerzo: ~3 hrs | Prioridad: 🟡 Alta | **PR: #51**

- Guía de Docker para sysadmin (no desarrollo).
- Enfoque: diagnóstico de contenedores, no construcción de imágenes.
- Quick command: `docker ps -a`, `docker logs`, `docker stats`.
- Cubrir: crash loops, OOM, resource limits, networking, volúmenes.
- Modelo mental: Docker como gestor de procesos en entorno aislado.
- Conectar con `scenarios/system/14-docker-troubleshooting.md` y labs existentes.
- Portabilidad: comandos esenciales que funcionan en cualquier instalación Docker.

---

## Fase 5 — Nueva guía: `guides/systemd.md` ✅ COMPLETADA

> Esfuerzo: ~2 hrs | Prioridad: 🟢 Media | **PR: #52**

**Decisión tomada**: Crear `guides/systemd.md` nuevo en vez de expandir `systemd_journalctl.md`.

**Razón**: `systemd_journalctl.md` está enfocado en gestión de logs con journalctl. Systemd como init system merece su propia guía completa.

**Contenido de `guides/systemd.md`**:

- Unidades: service, socket, device, mount, automount, timer, path, slice
- Comandos: systemctl (start, stop, restart, enable, disable, status)
- Estados de unidades: active, inactive, failed, activating
- Targets: multi-user.target, graphical.target, rescue.target
- Timers: reemplazo moderno de cron
- Resource control: CPUQuota, MemoryMax, IOWeight
- Dependencias entre unidades: Requires, Wants, After, Before
- Override de configuración: systemctl edit, drop-in files
- Análisis de arranque: systemd-analyze, blame
- Journalctl integrado: logs por unidad

---

## Fase 6 — Diagramas Mermaid (postergado)

> Esfuerzo: ~1 hr | Prioridad: 🔵 Baja

- Convertir diagramas ASCII art (ej: flujo de iptables en `guides/iptables.md`) a Mermaid.
- **Razón para postergar**: ASCII art funciona en terminal y visores de texto plano. Mermaid solo renderiza en GitHub. Si se hace, mantener ambos formatos.
- **ROI**: Bajo. El diagrama ASCII actual ya es claro.

---

## Fase 7 — Estructura Dahua: 8 guías especializadas

> Esfuerzo: ~8 hrs | Prioridad: 🔴 Crítica | **PR: pendiente**

Crear `guides/dahua/` con 8 guías para administración de cámaras IP, NVR y DVR Dahua desde terminal.

### Archivos a crear

1. **`guides/dahua/README.md`** — Índice de la sección Dahua
   - Enlace a todas las guías
   - Nota legal sobre uso autorizado
   - Referencias a documentación oficial

2. **`guides/dahua/dahua-discovery.md`** — Descubrir dispositivos en la red
   - Método 1: Puerto Dahua propietario (37777) con nmap
   - Método 2: ONVIF Discovery (puerto 3702)
   - Método 3: DHCP logs (dnsmasq, isc-dhcp-server)
   - Método 4: ARP scan (solo LAN)
   - Método 5: Consultar servidor DHCP del router
   - Método 6: HTTP probe masivo con curl
   - OUI de MAC addresses (Dahua: 9C:EB, 54:BF)
   - Uno-liners para discovery rápido

3. **`guides/dahua/dahua-camera-api.md`** — API HTTP/ISAPI desde terminal
   - Fundamentos de API CGI/ISAPI
   - Autenticación HTTP Basic Auth
   - Categorías de API (magicBox, configManager, media, user, snapshot, ivs, storage, network, ptz, record)
   - Ejemplos prácticos:
     - Información del sistema
     - Sincronizar hora
     - Cambiar contraseña
     - Configurar IP
     - Capturar snapshot
     - Configurar NTP
     - Agregar cámara a NVR
     - Consultar eventos de IA
   - Parsear respuestas XML con grep/sed/awk
   - Script wrapper de autenticación
   - Uno-liners imprescindibles

4. **`guides/dahua/dahua-rtsp-stream.md`** — Diagnóstico de video (RTSP)
   - URLs RTSP (main stream, sub stream)
   - Diagnóstico básico con ffprobe
   - Ver video en vivo con ffplay
   - Capturar segmento de video con ffmpeg
   - Diagnóstico de problemas comunes:
     - Connection refused / timeout
     - Unauthorized
     - Video pixelado / entrecortado
     - Stream muerto
   - Cambiar configuración de video desde terminal
   - Uno-liners para diagnóstico

5. **`guides/dahua/dahua-mass-config.md`** — Scripting y configuración masiva
   - Script para descubrir cámaras en rango de IPs
   - Cambiar contraseña masivamente (loop con curl)
   - Configurar NTP en múltiples cámaras
   - Asignar IPs estáticas en lote
   - Agregar cámaras a NVR vía API
   - Backup de configuración
   - Restaurar configuración
   - Ejemplos con loops en bash
   - Manejo de errores y logging

6. **`guides/dahua/dahua-nvr-ssh.md`** — Acceso SSH a NVR Dahua
   - Habilitar SSH en NVR (vía web o API)
   - Navegación del sistema de archivos
   - Ver procesos y consumo de recursos (top, ps)
   - Diagnóstico de discos (smartctl, hdparm)
   - Ver logs del sistema
   - Backup de configuración
   - Restaurar grabaciones
   - Comandos específicos Dahua
   - Troubleshooting de SSH

7. **`guides/dahua/dahua-wizsense-wizmind.md`** — Diferencias y capacidades IA
   - Diferencias entre series (Lite, WizSense, WizMind)
   - WizSense: detección de humanos/vehículos
   - WizMind: reconocimiento facial, LPR/ANPR
   - APIs de IA (ivs.cgi, faceRecognition.cgi)
   - Configurar reglas de detección vía API
   - Extraer eventos de IA
   - Integración con sistemas externos
   - Ejemplos prácticos de consultas

8. **`guides/dahua/dahua-troubleshooting.md`** — Diagnóstico de fallas comunes
   - Árbol de decisión para 10 fallas comunes:
     1. Cámara no responde
     2. Video pixelado/entrecortado
     3. NVR no detecta cámara
     4. NVR no graba
     5. Disco lleno/error de disco
     6. Error de autenticación
     7. Hora incorrecta
     8. No se puede acceder por web
     9. RTSP no funciona
     10. IA no detecta
   - Comandos de diagnóstico para cada caso
   - Soluciones paso a paso
   - Referencias a otras guías

### Referencias cruzadas

Cada guía Dahua debe referenciar:

- `network_segmentation.md` → VLANs por piso
- `ip_ss.md` → Diagnóstico de link/PoE
- `ping_traceroute.md` → Verificación de conectividad
- `tcpdump.md` → Captura de tráfico
- `nmap.md` → Discovery
- `ssh.md` → Acceso remoto
- `curl.md` → API HTTP

---

## Fase 8 — Reference Dahua cheatsheet

> Esfuerzo: ~1 hr | Prioridad: 🟡 Alta | **PR: pendiente**

Crear `reference/dahua-cheatsheet.md` con tabla rápida de consulta.

### Contenido

- **Tabla de puertos**: HTTP (80), HTTPS (443), RTSP (554), SSH (22), Dahua (37777), ONVIF (3702)
- **URLs RTSP**: main stream, sub stream, third stream
- **Endpoints CGI más usados**: magicBox, configManager, snapshot, user, network, ptz, record, ivs
- **Comandos rápidos de diagnóstico**: discovery, ping, snapshot, reboot, factory reset
- **Códigos de error comunes**: 401 Unauthorized, 403 Forbidden, 404 Not Found, 500 Internal Error
- **OUI de MAC addresses**: Dahua (9C:EB, 54:BF), Hikvision (A4:F3, 88:67), Uniview (68:C4)
- **Referencias a guías completas**

---

## Fase 9 — Scenarios Dahua: 3 escenarios prácticos

> Esfuerzo: ~3 hrs | Prioridad: 🟡 Alta | **PR: pendiente**

Crear `scenarios/dahua/` con 3 escenarios siguiendo plantilla estándar del repo.

### Archivos a crear

1. **`scenarios/dahua/01-camara-no-graba.md`** — Cámara no transmite video
   - Problema: cámara aparece en NVR pero no muestra video
   - Diagnóstico: verificar RTSP, firewall, credenciales, codec
   - Procedimiento: ping, nmap, ffprobe, tcpdump
   - Mitigación: reboot, reset, reconfigurar
   - Variante Alpine: no aplica (cámaras no son Linux)

2. **`scenarios/dahua/02-nvr-sin-disco.md`** — NVR no detecta disco
   - Problema: NVR arranca pero no graba
   - Diagnóstico: SSH a NVR, smartctl, dmesg, verificar conexión SATA
   - Procedimiento: verificar disco, formatear, reiniciar servicio
   - Mitigación: reemplazar disco, verificar cables
   - Variante Alpine: no aplica

3. **`scenarios/dahua/03-migracion-masiva.md`** — Cambiar contraseña a 50 cámaras
   - Problema: migrar 50 cámaras de contraseña antigua a nueva
   - Diagnóstico: descubrir cámaras, verificar conectividad
   - Procedimiento: script bash con loop, curl, manejo de errores
   - Mitigación: backup previo, rollback si falla
   - Variante Alpine: no aplica

### Labs Docker para Dahua

Crear `labs/docker-compose.dahua.yml` con:

- Simulador de cámara Dahua (nginx con API CGI fake)
- Simulador de NVR (contenedor con SSH y API)
- Red VLAN para cámaras
- Cliente para ejecutar comandos de diagnóstico

---

## Fase 10 — Actualizar guías existentes con referencias a Dahua

> Esfuerzo: ~1 hr | Prioridad: 🟢 Media | **PR: pendiente**

Agregar secciones o ejemplos en guías existentes para conectar con Dahua.

### Archivos a actualizar

1. **`guides/network_segmentation.md`**
   - Agregar sección: "VLANs para cámaras IP por pisos"
   - Esquema típico: Piso 1 (VLAN 100), Piso 2 (VLAN 110), Exterior (VLAN 120), WiFi APs (VLAN 130)
   - Ejemplo de configuración de subinterfaces
   - ACLs para aislar tráfico de cámaras

2. **`guides/ip_ss.md`**
   - Agregar sección: "Diagnóstico de link físico y PoE"
   - Verificar estado del enlace con ethtool
   - Ver errores de TX/RX (posible cable defectuoso)
   - Diagnóstico PoE (si el switch lo soporta)

3. **`guides/ping_traceroute.md`**
   - Agregar ejemplo: "Verificación masiva de cámaras"
   - Loop con ping para verificar conectividad de múltiples cámaras

4. **`guides/tcpdump.md`**
   - Agregar ejemplos: "Capturar tráfico de cámaras en VLAN específica"
   - Filtros BPF para RTSP (port 554) y Dahua (port 37777)

---

## Fase 11 — Nueva guía: Access Points Enterprise

> Esfuerzo: ~3 hrs | Prioridad: 🟡 Alta | **PR: pendiente**

Crear `guides/access_points_enterprise.md` para APs empresariales.

### Marcas a cubrir

- **Ubiquiti UniFi**: controller, CLI, API, discovery
- **Aruba/HP**: ArubaOS, CLI, AirWave
- **Cisco**: AireOS, IOS-XE, WLC
- **Ruckus**: SmartZone, CLI

### Contenido

- Configuración básica de APs enterprise
- Diagnóstico de señal WiFi (iwconfig, iwlist, iw)
- Roaming entre APs
- Problemas comunes: interferencia, canal saturado, baja señal
- VLANs para WiFi corporativo
- Captive portal y autenticación (RADIUS, LDAP)
- Monitoreo de APs (SNMP, logs)
- Actualización de firmware
- Backup de configuración

---

## Fase 12 — Nueva guía: Access Points Consumer

> Esfuerzo: ~2 hrs | Prioridad: 🟢 Media | **PR: pendiente**

Crear `guides/access_points_consumer.md` para APs domésticos/SOHO.

### Marcas a cubrir

- **TP-Link**: configuración web, modo AP/repeater/bridge
- **D-Link**: configuración web, diagnóstico básico
- **Tenda**: configuración web, limitaciones

### Contenido

- Configuración básica vía web
- Modo AP vs repeater vs bridge vs client
- Diagnóstico básico (ping, traceroute, velocidad)
- Limitaciones vs enterprise (sin VLANs, sin RADIUS, sin controller)
- Problemas comunes y soluciones
- Cuándo usar consumer vs enterprise

---

## Fase 13 — Nueva guía: PoE Switches Managed

> Esfuerzo: ~2 hrs | Prioridad: 🟡 Alta | **PR: pendiente**

Crear `guides/poe_switches_managed.md` para switches con PoE gestionable.

### Contenido

- Estándares PoE: 802.3af (15.4W), 802.3at (30W), 802.3bt (60W/100W)
- Diagnóstico vía SNMP/CLI
- Ver consumo por puerto (watts, voltaje, corriente)
- Resetear puerto PoE (power cycle)
- Logs de errores PoE (sobrecarga, corto, bajo voltaje)
- Configuración de prioridades PoE
- Marcas populares: Ubiquiti, TP-Link, Netgear, Cisco, HPE/Aruba
- Ejemplos de comandos CLI por marca
- Troubleshooting: cámara no enciende, intermitente, bajo rendimiento

---

## Fase 14 — Nueva guía: PoE Injectors

> Esfuerzo: ~1 hr | Prioridad: 🟢 Media | **PR: pendiente**

Crear `guides/poe_injectors.md` para injectors PoE básicos.

### Contenido

- Tipos de injectors: passive (24V, 48V) vs active (802.3af/at)
- Diagnóstico con multímetro
- Verificar voltaje (48V típico para cámaras)
- Problemas comunes:
  - Cable largo (>100m) → caída de voltaje
  - Cable de mala calidad → pérdida de potencia
  - Injector defectuoso
  - Cámara incompatible (voltaje incorrecto)
- Splitters PoE (convertir PoE a DC para dispositivos no-PoE)
- Cuándo usar injector vs switch PoE
- Cálculo de presupuesto de potencia (power budget)

---

## Fase 15 — Nueva guía: Cable Diagnostics

> Esfuerzo: ~2 hrs | Prioridad: 🟡 Alta | **PR: pendiente**

Crear `guides/cable_diagnostics.md` para diagnóstico de cables de red.

### Contenido

- **ethtool**: velocidad, duplex, link status, auto-negotiation
- Diagnóstico de errores de TX/RX (posible cable defectuoso)
- Categorías de cable: Cat5e (1Gbps), Cat6 (10Gbps@55m), Cat6a (10Gbps@100m)
- Longitud máxima: 100m para Ethernet, 90m + 10m patch cords
- Herramientas de testing:
  - Toner probe (rastrear cable)
  - Cable tester básico (continuidad, cruzado, abierto, corto)
  - Cable certifier (Fluke, etc.) — para certificación profesional
- Problemas comunes:
  - Cable cruzado (crossover) vs recto (straight-through)
  - Conector RJ45 mal crimpado
  - Interferencia electromagnética (EMI)
  - Cable demasiado largo
  - Cable dañado (mordeduras, dobleces, humedad)
- Diagnóstico desde Linux:
  - `ethtool eth0` — ver velocidad y duplex
  - `ip -s link show eth0` — ver errores de TX/RX
  - `dmesg | grep eth0` — ver mensajes del kernel
- Cuándo recablear vs cuándo ajustar configuración

---

## Fase 16 — Labs Docker para Dahua

> Esfuerzo: ~2 hrs | Prioridad: 🟡 Alta | **PR: pendiente**

Crear `labs/docker-compose.dahua.yml` con entorno de práctica para Dahua.

### Servicios

- **dahua-camera-sim**: Simulador de cámara Dahua (nginx con API CGI fake, RTSP fake)
- **dahua-nvr-sim**: Simulador de NVR (contenedor con SSH y API fake)
- **dahua-client**: Cliente para ejecutar comandos de diagnóstico (curl, nmap, ffprobe)
- **Red VLAN**: Red aislada para cámaras (10.0.100.0/24)

### Ejercicios

1. Descubrir cámaras en la red
2. Consultar información del sistema vía API
3. Capturar snapshot
4. Configurar NTP
5. Cambiar contraseña
6. Diagnosticar RTSP
7. Agregar cámara a NVR

### Archivos incluidos

- `labs/dahua/nginx-cgi-fake.conf` — configuración nginx para simular API CGI
- `labs/dahua/rtsp-sim.sh` — script para simular stream RTSP
- `labs/dahua/nvr-sim.sh` — script para simular NVR con SSH

---

## Dependencias entre fases

```text
Fase 0 (links rotos) → sin dependencias, ejecutar primero
Fase 1 (quick wins) → sin dependencias, paralelizable con Fase 0, 2
Fase 2 (scenarios) → sin dependencias
Fase 3 (nftables) → ideal después de Fase 1.5 (iptables mejorada)
Fase 4 (docker) → sin dependencias
Fase 5 (systemd) → sin dependencias, archivo nuevo
Fase 6 (postergado) → sin fecha
Fase 7 (Dahua guías) → sin dependencias, priorizar
Fase 8 (Dahua cheatsheet) → depende de Fase 7
Fase 9 (Dahua scenarios) → depende de Fase 7
Fase 10 (actualizar guías) → depende de Fase 7
Fase 11 (APs enterprise) → sin dependencias
Fase 12 (APs consumer) → sin dependencias
Fase 13 (PoE switches) → sin dependencias
Fase 14 (PoE injectors) → sin dependencias
Fase 15 (cable diagnostics) → sin dependencias
Fase 16 (labs Dahua) → depende de Fase 7
```

---

## Resumen de fases

| Fase | Descripción | Estado | Esfuerzo |
|------|-------------|--------|----------|
| 0 | Links rotos | Pendiente | 30 min |
| 1 | Quick wins en guías | ✅ Completada | 2 hrs |
| 2 | Mejoras en scenarios | ✅ Completada | 2 hrs |
| 3 | nftables.md | ✅ Completada | 3 hrs |
| 4 | docker.md | ✅ Completada | 3 hrs |
| 5 | systemd.md | ✅ Completada | 2 hrs |
| 6 | Mermaid diagrams | Postergado | 1 hr |
| 7 | Dahua: 8 guías | Pendiente | 8 hrs |
| 8 | Dahua cheatsheet | Pendiente | 1 hr |
| 9 | Dahua scenarios | Pendiente | 3 hrs |
| 10 | Actualizar guías existentes | Pendiente | 1 hr |
| 11 | APs enterprise | Pendiente | 3 hrs |
| 12 | APs consumer | Pendiente | 2 hrs |
| 13 | PoE switches | Pendiente | 2 hrs |
| 14 | PoE injectors | Pendiente | 1 hr |
| 15 | Cable diagnostics | Pendiente | 2 hrs |
| 16 | Labs Docker Dahua | Pendiente | 2 hrs |

**Total estimado**: ~36 hrs de trabajo

---

## Comandos de validación

```bash
pnpm lint:md        # Markdown lint
pnpm lint:sh        # ShellCheck en scripts/
pnpm validate:sre   # Validación SRE (no bashismos, no grep -P)
pnpm validate       # Todo lo anterior
```
