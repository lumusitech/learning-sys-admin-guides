# systemd y journalctl — Guía completa

## Índice
1. [¿Qué es systemd?](#qué-es-systemd)
2. [Unidades (units)](#unidades-units)
3. [systemctl: gestión de servicios](#systemctl-gestión-de-servicios)
4. [Análisis de estado del sistema](#análisis-de-estado-del-sistema)
5. [journalctl: logs de systemd](#journalctl-logs-de-systemd)
6. [Filtros de journalctl](#filtros-de-journalctl)
7. [Formato de salida de journalctl](#formato-de-salida-de-journalctl)
8. [Mantenimiento de logs](#mantenimiento-de-logs)
9. [Escenarios reales](#escenarios-reales)
10. [Escenarios de falla](#escenarios-de-falla)
11. [Uno-liners imprescindibles](#uno-liners-imprescindibles)

---

## ¿Qué es systemd?

**systemd** es el sistema de inicio (init) y gestor de servicios en la mayoría de distribuciones Linux modernas. Es el **primer proceso** que se ejecuta (PID 1) y se encarga de:

- Arrancar el sistema
- Gestionar servicios (iniciar, parar, reiniciar)
- Gestionar dependencias entre servicios
- Monitorizar procesos hijos
- Gestionar logs (journald)
- Gestionar temporizadores (cron-like)
- Gestionar montajes, sockets, dispositivos, etc.

```bash
# Verificar que systemd está en uso
ps -p 1 -o comm=
# Debería mostrar: systemd
```

---

## Unidades (units)

Todo en systemd es una **unidad** (unit). Cada unidad tiene un tipo y un archivo de configuración.

### Tipos de unidades

| Tipo | Extensión | Descripción |
|------|-----------|-------------|
| Service | `.service` | Servicios demonio (nginx, sshd, etc.) |
| Socket | `.socket` | Sockets de red o IPC (activación por socket) |
| Timer | `.timer` | Temporizadores (como cron) |
| Mount | `.mount` | Puntos de montaje del sistema de archivos |
| Automount | `.automount` | Montaje automático (on-demand) |
| Target | `.target` | Grupo de unidades (como runlevels) |
| Device | `.device` | Dispositivos del kernel |
| Path | `.path` | Vigilancia de cambios en rutas |
| Slice | `.slice` | Grupo de control de recursos (cgroups) |
| Scope | `.scope` | Procesos externos agrupados |

### Ubicación de archivos de unidades

```bash
# Unidades del sistema (empaquetadas)
ls /lib/systemd/system/

# Unidades personalizadas o modificadas
ls /etc/systemd/system/

# Unidades de usuario
ls ~/.config/systemd/user/

# Unidades generadas dinámicamente
ls /run/systemd/system/
```

### Estado de las unidades

```bash
# Listar todas las unidades activas
systemctl list-units

# Listar todos los servicios
systemctl list-units --type=service

# Listar todas las unidades (incluyendo inactivas)
systemctl list-units --all

# Listar unidades fallidas
systemctl --failed

# Listar temporizadores
systemctl list-timers

# Listar sockets
systemctl list-sockets
```

---

## systemctl: gestión de servicios

### Operaciones básicas

```bash
# Iniciar un servicio
systemctl start nginx

# Parar un servicio
systemctl stop nginx

# Reiniciar un servicio
systemctl restart nginx

# Recargar configuración (sin reiniciar)
systemctl reload nginx

# Recargar o reiniciar (recarga si soporta, sino reinicia)
systemctl reload-or-restart nginx

# Habilitar para inicio automático
systemctl enable nginx

# Deshabilitar inicio automático
systemctl disable nginx

# Habilitar e iniciar (combinado)
systemctl enable --now nginx

# Deshabilitar y parar
systemctl disable --now nginx

# Verificar estado
systemctl status nginx
```

### Ver estado detallado

```bash
# Estado de un servicio
systemctl status nginx
# Muestra:
# - Cargado (loaded): ruta del archivo de unidad
# - Activo (active): running, exited, failed, etc.
# - PID principal
# - Tareas (tasks)
# - Memoria usada
# - CPU usada
# - Últimas líneas del log del servicio (journalctl)

# Resumen de estado
systemctl is-active nginx     # active/inactive
systemctl is-enabled nginx    # enabled/disabled
systemctl is-failed nginx     # active/failed
```

### Dependencias

```bash
# ¿De qué depende este servicio?
systemctl list-dependencies nginx

# ¿Qué servicios dependen de este?
systemctl list-dependencies --reverse nginx

# Ver todo el árbol de dependencias
systemctl list-dependencies --all nginx
```

### Sobrescribir unidades

```bash
# Editar la configuración de una unidad (crea override)
systemctl edit nginx

# Ver el contenido completo (incluyendo overrides)
systemctl cat nginx

# Revertir cambios
systemctl revert nginx
```

### Targets (runlevels)

```bash
# Target actual
systemctl get-default

# Cambiar target por defecto
systemctl set-default multi-user.target

# Targets comunes:
# poweroff.target    → apagar
# rescue.target      → modo recovery (single user)
# multi-user.target  → modo texto (sin interfaz gráfica)
# graphical.target   → modo gráfico
# reboot.target      → reiniciar

# Cambiar de target (como cambiar runlevel)
systemctl isolate multi-user.target

# Listar dependencias de un target
systemctl list-dependencies graphical.target
```

---

## Análisis de estado del sistema

### systemd-analyze

```bash
# Tiempo de arranque
systemd-analyze

# Tiempo por unidad
systemd-analyze blame

# Cadena crítica (qué retrasó el arranque)
systemd-analyze critical-chain

# Gráfico de dependencias (SVG)
systemd-analyze plot > boot.svg

# Tiempo de arranque por usuario
systemd-analyze time
```

### hostnamectl

```bash
# Información del sistema
hostnamectl

# Cambiar hostname
hostnamectl set-hostname nuevo-nombre

# Ver información de hardware
hostnamectl status
```

### localectl

```bash
# Configuración regional
localectl

# Cambiar layout de teclado
localectl set-keymap es

# Cambiar locale
localectl set-locale LANG=es_ES.UTF-8
```

### timedatectl

```bash
# Fecha, hora y zona horaria
timedatectl

# Listar zonas horarias
timedatectl list-timezones

# Cambiar zona horaria
timedatectl set-timezone Europe/Madrid

# Habilitar NTP
timedatectl set-ntp true
```

### loginctl

```bash
# Sesiones de usuario
loginctl list-sessions

# Información de una sesión
loginctl show-session 2

# Usuarios conectados
loginctl list-users
```

---

## journalctl: logs de systemd

**journalctl** consulta el **journal** de systemd, el sistema de logs binario de systemd. Reemplaza a logs en texto plano.

```bash
# Ver todos los logs (desde el arranque actual)
journalctl

# Ver logs del arranque actual
journalctl -b

# Ver logs del arranque anterior
journalctl -b -1

# Seguir logs en tiempo real (como tail -f)
journalctl -f

# Últimas N líneas
journalctl -n 50
```

---

## Filtros de journalctl

### Por servicio/unidad (-u)

```bash
# Logs de un servicio específico
journalctl -u nginx

# Logs de varios servicios
journalctl -u nginx -u sshd

# Logs de un servicio desde el arranque actual
journalctl -u nginx -b

# Seguir logs de un servicio
journalctl -u nginx -f
```

### Por tiempo

```bash
# Desde hace 1 hora
journalctl --since "1 hour ago"

# Desde una fecha/hora específica
journalctl --since "2024-01-15 14:00:00"

# Hasta una fecha/hora
journalctl --until "2024-01-15 16:00:00"

# Rango
journalctl --since "2024-01-15" --until "2024-01-16"

# Palabras clave de tiempo
journalctl --since yesterday
journalctl --since today
journalctl --since "1 day ago"
```

### Por prioridad

```bash
# Solo errores y superiores
journalctl -p err

# Niveles de prioridad (0-7):
# 0: emerg
# 1: alert
# 2: crit
# 3: err
# 4: warning
# 5: notice
# 6: info
# 7: debug

# Warning y superiores
journalctl -p warning

# Emergencia
journalctl -p emerg
```

### Por otros campos

```bash
# Por PID
journalctl _PID=1234

# Por usuario
journalctl _UID=1000

# Por grupo
journalctl _GID=1000

# Por comando
journalctl _COMM=sshd

# Por ejecutable
journalctl _EXE=/usr/sbin/sshd

# Por unidad de sistema
journalctl _SYSTEMD_UNIT=sshd.service

# Por dirección IP (del sistema)
journalctl _HOSTNAME=server1

# Combinar campos
journalctl _PID=1234 _COMM=nginx
```

---

## Formato de salida de journalctl

### -o (output)

```bash
# Por defecto (con paginación)
journalctl

# Sin paginación (como cat)
journalctl --no-pager

# JSON
journalctl -o json

# JSON-PRETTY (legible)
journalctl -o json-pretty

# verbose (todos los campos)
journalctl -o verbose

# cat (solo el mensaje, sin metadatos)
journalctl -o cat

# short (formato tradicional syslog)
journalctl -o short

# short-full (con timestamp ISO)
journalctl -o short-full

# short-iso
journalctl -o short-iso
```

### OUTPUT fields

```bash
# En formato verbose se ven todos los campos:
# _PID, _UID, _COMM, _EXE, _CMDLINE, _SYSTEMD_UNIT,
# _SELINUX_CONTEXT, _BOOT_ID, _MACHINE_ID,
# PRIORITY, SYSLOG_FACILITY, SYSLOG_IDENTIFIER,
# MESSAGE, MESSAGE_ID, _SOURCE_REALTIME_TIMESTAMP
```

---

## Mantenimiento de logs

### Tamaño y uso de disco

```bash
# Ver uso de disco del journal
journalctl --disk-usage

# Archivos de journal en disco
ls -lh /var/log/journal/
```

### Rotación y limpieza

```bash
# Eliminar logs de más de 7 días
journalctl --vacuum-time=7d

# Eliminar logs hasta dejar solo 100MB
journalctl --vacuum-size=100M

# Eliminar logs hasta dejar solo los últimos 2 arranques
journalctl --vacuum-files=2
```

### Configuración de journald

```bash
# /etc/systemd/journald.conf
# SystemMaxUse=100M        # Máximo espacio en disco (100MB)
# SystemMaxFileSize=50M    # Tamaño máximo por archivo
# RuntimeMaxUse=50M        # Máximo en /run/log (volátil)
# MaxRetentionSec=1week    # Tiempo máximo de retención
# ForwardToSyslog=yes      # Enviar a syslog tradicional
# Compress=yes             # Comprimir logs
```

---

## Escenarios reales

### 1. Verificar por qué un servicio no arranca

```bash
# Ver estado del servicio
systemctl status nginx

# Si está failed, ver logs específicos
journalctl -u nginx -b --no-pager

# Últimas líneas del error
journalctl -u nginx -b -n 20 -p err

# Posibles causas:
# - Error de sintaxis en configuración (nginx -t)
# - Puerto ocupado (ss -tlnp | grep :80)
# - Permisos incorrectos en archivos
# - Dependencia no disponible (mysql no iniciado)
```

### 2. Depurar un servicio que se cae constantemente

```bash
# Ver logs completos del servicio
journalctl -u nginx --since "1 day ago"

# ¿Cada cuánto se cae?
journalctl -u nginx | grep "Stopped\|Started" --color

# Ver si hay segfaults u OOM
journalctl -u nginx | grep -i "segfault\|killed\|OOM\|out of memory"

# Ver timestamps de última caída
journalctl -u nginx -b | grep -E "Starting|Started|Stopped|Failed"
```

### 3. Buscar errores en el sistema

```bash
# Todos los errores del arranque actual
journalctl -b -p err

# Errores de hardware
journalctl -b -p err | grep -i "hardware\|error\|fail" --color

# Errores de disco
journalctl -b -p err | grep -i "ata\|scsi\|sd \|nvme\|i/o error"

# Errores de memoria
journalctl -b -p err | grep -i "memory\|dimm\|edac\|mce"
```

### 4. Monitorear intentos de login SSH

```bash
# Intentos de SSH
journalctl -u sshd -b

# Logins fallidos
journalctl -u sshd -b | grep "Failed password"

# Logins exitosos
journalctl -u sshd -b | grep "Accepted"

# Intentos de usuario inexistente
journalctl -u sshd -b | grep "Invalid user"
```

### 5. Ver actividad reciente del sistema

```bash
# Últimas 50 líneas del sistema
journalctl -n 50

# Actividad de los últimos 10 minutos
journalctl --since "10 minutes ago"

# Watch de errores en vivo
journalctl -f -p err
```

### 6. Correlacionar eventos entre servicios

```bash
# Logs de varios servicios en orden temporal
journalctl -u nginx -u php-fpm -u mysql --since "1 hour ago" --no-pager
```

### 7. Ver tiempo de arranque y cuellos de botella

```bash
# Tiempo total
systemd-analyze

# Qué servicios tardan más
systemd-analyze blame | head -10

# Cadena crítica
systemd-analyze critical-chain
```

---

## Escenarios de falla

### 1. Servicio no arranca — "Unit not found"

```bash
systemctl start myservice
# Failed to start myservice.service: Unit not found.

# Causas:
# - El servicio no está instalado → apt install myservice
# - Typo en el nombre → systemctl list-units --all | grep -i my
# - Archivo .service no existe
```

### 2. Servicio arranca y se para — "Exit code 1"

```bash
systemctl status myservice
# ● myservice.service - My Service
#    Loaded: loaded (/etc/systemd/system/myservice.service; enabled)
#    Active: failed (Result: exit-code)
#    Process: 1234 ExecStart=/usr/bin/myservice (code=exited, status=1/FAILURE)

# Causas:
# - Error en configuración del servicio
# - Archivo de configuración incorrecto
# - Puerto ocupado
# - Permisos insuficientes

# Ver log específico:
journalctl -u myservice -b -p err
```

### 3. Servicio en estado "activating" (start)

```bash
systemctl status myservice
# Active: activating (start) since ...

# Causas:
# - El servicio tiene un Type=oneshot y el proceso tarda
# - Timeout de inicio muy bajo
# - El proceso padre no hace fork correctamente
# - Dependencia colgada (mysql no responde)
```

### 4. Logs no aparecen en journalctl

```bash
# Verificar que journald está corriendo
systemctl status systemd-journald

# Verificar tamaño
journalctl --disk-usage

# Verificar que los logs se guardan en disco (persistentes)
# /var/log/journal/ debe existir
ls /var/log/journal/

# Si no existe, crear:
sudo mkdir -p /var/log/journal
sudo systemd-tmpfiles --create --prefix /var/log/journal
sudo systemctl restart systemd-journald
```

### 5. Disco lleno por logs

```bash
# Ver uso de disco
journalctl --disk-usage
df -h /var/log

# Limpiar
journalctl --vacuum-size=200M
journalctl --vacuum-time=3d

# Configurar límite en /etc/systemd/journald.conf:
# SystemMaxUse=200M
# SystemMaxFileSize=50M
# MaxRetentionSec=1week

# Luego reiniciar journald
systemctl restart systemd-journald
```

### 6. Servicio reiniciándose continuamente

```bash
# Ver si tiene Restart=always en el archivo de unidad
systemctl cat myservice | grep Restart

# Ver log de reinicios
journalctl -u myservice | grep -E "Stopped|Started" | tail -20

# Deshabilitar reinicio automático temporalmente
systemctl stop myservice
# Investigar y luego corregir
```

---

## Uno-liners imprescindibles

```bash
# Estado de un servicio
systemctl status nginx

# Iniciar/parar/reiniciar
systemctl start nginx
systemctl stop nginx
systemctl restart nginx

# Habilitar/deshabilitar
systemctl enable nginx
systemctl disable nginx

# Listar servicios activos
systemctl list-units --type=service

# Servicios fallidos
systemctl --failed

# Ver todos los logs de un servicio
journalctl -u nginx

# Seguir logs en vivo
journalctl -f

# Seguir logs de un servicio
journalctl -u nginx -f

# Logs del arranque actual
journalctl -b

# Logs de hace 1 hora
journalctl --since "1 hour ago"

# Solo errores
journalctl -p err

# Últimas 20 líneas
journalctl -n 20

# Mostrar solo mensajes
journalctl -o cat

# Ver tiempo de arranque
systemd-analyze

# Servicios que más tardan en arrancar
systemd-analyze blame | head -10

# Cadena crítica de arranque
systemd-analyze critical-chain

# Cambiar target
systemctl isolate multi-user.target

# Usar temporizador como cron
systemctl list-timers

# Espacio usado por logs
journalctl --disk-usage

# Limpiar logs viejos
journalctl --vacuum-time=7d

# Ver target por defecto
systemctl get-default

# Editar unidad
systemctl edit nginx

# Ver contenido completo de unidad
systemctl cat nginx

# Recargar units (después de crear/editar)
systemctl daemon-reload
```
