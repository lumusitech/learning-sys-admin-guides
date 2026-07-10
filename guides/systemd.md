# systemd — Guía completa

**Nivel:** 🟡 Intermedio
**Archivos de práctica:** Sistema en vivo
**Ver escenarios relacionados:** [`system/01-top-processes`](../scenarios/system/01-top-processes-and-resources.md), [`system/02-log-analysis`](../scenarios/system/02-log-analysis-and-error-tracking.md)

---

## ⚡ Quick command

`systemctl list-units --type=service`

---

## ⚡ Quick run

```bash
systemctl status sshd && systemctl cat sshd | head -20
```

---

## 📑 Índice

1. [¿Qué es systemd?](#qué-es-systemd)
2. [Modelo mental](#modelo-mental)
3. [Estructura de archivos de unidad](#estructura-de-archivos-de-unidad)
4. [Tipos de servicio](#tipos-de-servicio)
5. [Dependencias avanzadas](#dependencias-avanzadas)
6. [Timers (reemplazo de cron)](#timers-reemplazo-de-cron)
7. [Socket activation](#socket-activation)
8. [Path units](#path-units)
9. [Resource control (cgroups)](#resource-control-cgroups)
10. [Slices](#slices)
11. [Análisis de arranque](#análisis-de-arranque)
12. [Override de configuración](#override-de-configuración)
13. [Uno-liners imprescindibles](#uno-liners-imprescindibles)
14. [Errores comunes](#errores-comunes)
15. [Buenas prácticas](#buenas-prácticas)
16. [Referencias internas](#referencias-internas)

---

## 🧠 ¿Qué es systemd?

**systemd** es el sistema de inicio (init) y gestor de servicios en la mayoría de distribuciones Linux modernas. Es el **primer proceso** que se ejecuta (PID 1) y gestiona:

- Servicios (daemons)
- Sockets de red
- Dispositivos
- Montajes
- Temporizadores
- Logs (journald)
- Control de recursos (cgroups)

> **Nota**: Esta guía se enfoca en aspectos avanzados de systemd. Para gestión básica de servicios y journalctl, ver [`systemd_journalctl.md`](systemd_journalctl.md).

---

## 🧠 Modelo mental

systemd es un **gestor de dependencias y estados**.

Piensa en systemd como un grafo dirigido:

- **Nodos**: unidades (servicios, sockets, timers, etc.)
- **Aristas**: dependencias (Requires, Wants, After, Before)
- **Estados**: inactive, activating, active, deactivating, failed

systemd resuelve el grafo para determinar el orden de arranque y qué activar.

### Filosofía de systemd

- **Declarativo**: defines el estado deseado, no los pasos
- **Paralelo**: arranca servicios concurrentemente cuando es seguro
- **Agresivo**: usa socket activation para iniciar servicios bajo demanda
- **Integral**: reemplaza cron, syslog, inetd, etc.

---

## 📝 Estructura de archivos de unidad

Todo en systemd es una **unidad** (unit file). Los archivos tienen extensión según el tipo:

### Secciones de un .service

```ini
[Unit]
Description=Mi Servicio Personalizado
Documentation=https://ejemplo.com/docs
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/opt/myapp
ExecStart=/usr/bin/myapp --config /etc/myapp.conf
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=5s
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
```

### Secciones explicadas

**[Unit]**: Metadatos y dependencias

| Directiva | Descripción |
|-----------|-------------|
| `Description=` | Descripción legible de la unidad |
| `Documentation=` | URL o man page de documentación |
| `After=` | Arrancar después de estas unidades (orden) |
| `Before=` | Arrancar antes de estas unidades (orden) |
| `Requires=` | Dependencia fuerte: si falla, esta unidad se detiene |
| `Wants=` | Dependencia débil: si falla, esta unidad continúa |
| `Conflicts=` | No puede estar activa al mismo tiempo que estas |
| `Condition...=` | Condiciones para activar (ej: `ConditionPathExists=/etc/myapp.conf`) |

**[Service]**: Configuración del servicio

| Directiva | Descripción |
|-----------|-------------|
| `Type=` | Tipo de servicio (simple, forking, oneshot, etc.) |
| `ExecStart=` | Comando para iniciar |
| `ExecStop=` | Comando para detener |
| `ExecReload=` | Comando para recargar configuración |
| `Restart=` | Política de reinicio (no, on-failure, always, on-abnormal) |
| `RestartSec=` | Tiempo antes de reiniciar |
| `User=` | Usuario con el que correr |
| `Group=` | Grupo con el que correr |
| `WorkingDirectory=` | Directorio de trabajo |
| `Environment=` | Variables de entorno |
| `EnvironmentFile=` | Archivo con variables de entorno |

**[Install]**: Información de instalación

| Directiva | Descripción |
|-----------|-------------|
| `WantedBy=` | Target que quiere esta unidad (para `enable`) |
| `RequiredBy=` | Target que requiere esta unidad |
| `Alias=` | Nombres alternativos |

---

## 🎛️ Tipos de servicio

El campo `Type=` en `[Service]` define cómo systemd monitorea el servicio:

### Type=simple (por defecto)

El proceso principal es el servicio. systemd considera el servicio activo inmediatamente después de ejecutar `ExecStart`.

```ini
[Service]
Type=simple
ExecStart=/usr/bin/myapp
```

**Usar cuando**: el proceso no hace fork y corre en foreground.

### Type=forking

El proceso hace fork y el padre termina. systemd espera que el padre termine antes de considerar el servicio activo.

```ini
[Service]
Type=forking
PIDFile=/run/myapp.pid
ExecStart=/usr/sbin/myapp --daemon
```

**Usar cuando**: el servicio es un daemon tradicional que hace fork.

### Type=oneshot

El servicio ejecuta una tarea y termina. systemd lo considera activo mientras se ejecuta.

```ini
[Service]
Type=oneshot
ExecStart=/usr/local/bin/backup.sh
RemainAfterExit=yes
```

**Usar cuando**: tareas de configuración, scripts de setup, limpieza.

### Type=notify

Similar a simple, pero el servicio notifica a systemd cuando está listo usando sd_notify().

```ini
[Service]
Type=notify
ExecStart=/usr/bin/myapp
```

**Usar cuando**: el servicio soporta el protocolo de notificación de systemd.

### Type=dbus

Similar a notify, pero espera a que el servicio adquiera un nombre en D-Bus.

```ini
[Service]
Type=dbus
BusName=org.example.MyService
ExecStart=/usr/bin/myapp
```

**Usar cuando**: el servicio expone una API D-Bus.

---

## 🔗 Dependencias avanzadas

systemd permite definir dependencias complejas entre unidades:

### Orden vs Requerimiento

- **After/Before**: solo orden de arranque (no requieren que la otra unidad esté activa)
- **Requires/Wants**: requieren que la otra unidad esté activa (no especifican orden)

### Combinaciones comunes

```ini
# Arrancar después de network, pero no fallar si network falla
After=network.target
Wants=network-online.target

# Requiere que mysql esté activo, y arrancar después
Requires=mysql.service
After=mysql.service

# Arrancar solo si existe el archivo de configuración
ConditionPathExists=/etc/myapp/myapp.conf

# Arrancar solo si la red está en línea
ConditionNetworkHost=online
```

### Dependencias automáticas

systemd agrega dependencias automáticas:

- `Before=shutdown.target` (todos los servicios)
- `Conflicts=shutdown.target` (todos los servicios)
- `After=` implícito para unidades montadas mencionadas en `ExecStart`

### Ver dependencias

```bash
# ¿De qué depende este servicio?
systemctl list-dependencies nginx.service

# ¿Qué servicios dependen de este?
systemctl list-dependencies --reverse nginx.service

# Ver todo el árbol
systemctl list-dependencies --all nginx.service

# Ver dependencias en formato texto
systemctl show nginx.service -p After,Before,Requires,Wants
```

---

## ⏰ Timers (reemplazo de cron)

Los **timers** son unidades `.timer` que activan unidades `.service` en momentos específicos. Son el reemplazo moderno de cron con ventajas:

- Logs integrados con journalctl
- Eventos perdidos se ejecutan al arrancar (Persistent=true)
- Randomized delay para evitar picos
- Soporte para calendarios complejos

### Ejemplo: backup diario

**/etc/systemd/system/backup.service**:

```ini
[Unit]
Description=Backup diario

[Service]
Type=oneshot
ExecStart=/usr/local/bin/backup.sh
User=root
```

**/etc/systemd/system/backup.timer**:

```ini
[Unit]
Description=Ejecutar backup diario

[Timer]
OnCalendar=daily
Persistent=true
RandomizedDelaySec=1h

[Install]
WantedBy=timers.target
```

**Activar**:

```bash
systemctl daemon-reload
systemctl enable --now backup.timer

# Ver próximo disparo
systemctl list-timers backup.timer
```

### Especificaciones de tiempo

```ini
# Cada 5 minutos
OnCalendar=*:0/5

# Cada hora
OnCalendar=hourly

# Diario a las 3:30 AM
OnCalendar=*-*-* 03:30:00

# Lunes a viernes a las 9 AM
OnCalendar=Mon..Fri *-*-* 09:00:00

# Primer día de cada mes
OnCalendar=monthly

# Cada 15 minutos con delay aleatorio
OnCalendar=*:0/15
RandomizedDelaySec=5min
```

### Ventajas sobre cron

```bash
# Ver logs del timer
journalctl -u backup.timer
journalctl -u backup.service

# Ver próximo disparo
systemctl list-timers --all

# Forzar ejecución manual
systemctl start backup.service

# Deshabilitar temporalmente
systemctl stop backup.timer
```

---

## 🔌 Socket activation

**Socket activation** permite iniciar servicios bajo demanda cuando llega una conexión. El socket escucha y systemd arranca el servicio solo cuando es necesario.

### Ejemplo: servicio activado por socket

**/etc/systemd/system/myapp.socket**:

```ini
[Unit]
Description=MyApp Socket

[Socket]
ListenStream=8080
Accept=yes

[Install]
WantedBy=sockets.target
```

**/etc/systemd/system/myapp@.service** (template):

```ini
[Unit]
Description=MyApp Instance

[Service]
ExecStart=/usr/bin/myapp --handle-connection
StandardInput=socket
```

**Activar**:

```bash
systemctl enable --now myapp.socket

# Ver sockets activos
systemctl list-sockets

# El servicio se iniciará automáticamente cuando llegue una conexión
```

### Ventajas

- **Ahorro de recursos**: servicios no corren hasta ser necesarios
- **Arranque más rápido**: servicios se inician en paralelo bajo demanda
- **Manejo de picos**: systemd encola conexiones mientras arranca el servicio

---

## 📂 Path units

Las **path units** activan servicios cuando archivos o directorios cambian.

### Ejemplo: procesar archivos nuevos

**/etc/systemd/system/process-incoming.service**:

```ini
[Unit]
Description=Procesar archivos entrantes

[Service]
Type=oneshot
ExecStart=/usr/local/bin/process-files.sh
```

**/etc/systemd/system/process-incoming.path**:

```ini
[Unit]
Description=Monitorear directorio incoming

[Path]
PathModified=/var/spool/incoming
MakeDirectory=yes

[Install]
WantedBy=multi-user.target
```

**Activar**:

```bash
systemctl enable --now process-incoming.path

# Ver paths activos
systemctl list-paths
```

### Tipos de monitoreo

```ini
# Archivo cambió (contenido o metadata)
PathChanged=/path/to/file

# Archivo se modificó (contenido)
PathModified=/path/to/file

# Archivo existe (se creó)
PathExists=/path/to/file

# Archivo existe y es no vacío
PathExistsGlob=/path/to/files/*

# Directorio se vació
DirectoryNotEmpty=/path/to/dir
```

---

## 🎛️ Resource control (cgroups)

systemd integra **cgroups** para limitar recursos de servicios:

### Límites de memoria

```ini
[Service]
MemoryMax=512M
MemoryHigh=400M
MemorySwapMax=256M
```

- `MemoryMax`: límite duro (OOM si se excede)
- `MemoryHigh`: límite blando (throttling antes de OOM)
- `MemorySwapMax`: límite de swap

### Límites de CPU

```ini
[Service]
CPUQuota=80%
CPUWeight=100
```

- `CPUQuota`: porcentaje de CPU (80% = 0.8 cores en sistema de 1 core)
- `CPUWeight`: prioridad relativa (100 por defecto, rango 1-10000)

### Límites de I/O

```ini
[Service]
IOWeight=100
IOReadBandwidthMax=/dev/sda 10M
IOWriteBandwidthMax=/dev/sda 5M
```

### Límites de procesos

```ini
[Service]
TasksMax=100
```

### Ejemplo completo

```ini
[Service]
ExecStart=/usr/bin/myapp
MemoryMax=1G
MemoryHigh=800M
CPUQuota=150%
TasksMax=50
```

### Ver límites aplicados

```bash
# Ver propiedades de cgroup
systemctl show myapp.service -p MemoryMax,CPUQuota,TasksMax

# Ver uso actual
systemctl status myapp.service

# Ver con systemd-cgtop (interactivo)
systemd-cgtop
```

---

## 🍰 Slices

Los **slices** agrupan unidades para aplicar límites de recursos compartidos:

### Crear slice personalizado

**/etc/systemd/system/myapps.slice**:

```ini
[Unit]
Description=Mis aplicaciones

[Slice]
MemoryMax=2G
CPUQuota=200%
```

### Asignar servicio a slice

```ini
[Service]
ExecStart=/usr/bin/myapp
Slice=myapps.slice
```

### Slices por defecto

- `system.slice`: servicios del sistema
- `user.slice`: sesiones de usuario
- `machine.slice`: máquinas/contenedores

### Ver estructura de slices

```bash
# Ver árbol de cgroups
systemd-cgls

# Ver uso por slice
systemd-cgtop

# Ver límites de un slice
systemctl show myapps.slice -p MemoryMax,CPUQuota
```

---

## 🔍 Análisis de arranque

systemd proporciona herramientas para analizar el tiempo de arranque:

### systemd-analyze

```bash
# Tiempo total de arranque
systemd-analyze

# Desglose por unidad
systemd-analyze blame

# Cadena crítica (qué retrasó el arranque)
systemd-analyze critical-chain

# Gráfico SVG de dependencias
systemd-analyze plot > boot.svg

# Análisis de seguridad
systemd-analyze security

# Verificar archivos de unidad
systemd-analyze verify myapp.service
```

### Optimizar tiempo de arranque

```bash
# Ver servicios que más tardan
systemd-analyze blame | head -20

# Ver cadena crítica
systemd-analyze critical-chain

# Deshabilitar servicios innecesarios
systemctl disable --now unused-service

# Cambiar a modo paralelo (si no está ya)
# Editar /etc/systemd/system.conf:
# DefaultTimeoutStartSec=30s
```

---

## 🔧 Override de configuración

systemd permite sobrescribir configuración sin modificar archivos originales:

### Crear override

```bash
# Editar override (crea archivo en /etc/systemd/system/service.service.d/override.conf)
systemctl edit nginx.service
```

**Contenido del override**:

```ini
[Service]
MemoryMax=1G
Environment=WORKERS=4
```

### Ver configuración completa

```bash
# Ver configuración final (incluyendo overrides)
systemctl cat nginx.service

# Ver solo overrides
systemctl cat nginx.service | grep -A 10 "drop-in"
```

### Revertir cambios

```bash
# Eliminar todos los overrides
systemctl revert nginx.service

# Recargar configuración
systemctl daemon-reload
```

### Override para todos los servicios

```bash
# Crear override global
systemctl edit --global
```

---

## 💡 Uno-liners imprescindibles

```bash
# Ver estructura de cgroups
systemd-cgls

# Top interactivo de cgroups
systemd-cgtop

# Ver próximo disparo de timers
systemctl list-timers --all

# Ver sockets activos
systemctl list-sockets

# Ver paths monitoreados
systemctl list-paths

# Análisis de seguridad de un servicio
systemd-analyze security nginx.service

# Verificar sintaxis de archivo de unidad
systemd-analyze verify myapp.service

# Ver configuración completa (incluyendo overrides)
systemctl cat myapp.service

# Ver dependencias de una unidad
systemctl list-dependencies myapp.service

# Ver propiedades de cgroup
systemctl show myapp.service -p MemoryMax,CPUQuota,TasksMax

# Tiempo de arranque del sistema
systemd-analyze

# Servicios que más tardan en arrancar
systemd-analyze blame | head -10

# Cadena crítica de arranque
systemd-analyze critical-chain

# Editar override de servicio
systemctl edit myapp.service

# Revertir overrides
systemctl revert myapp.service

# Recargar configuración después de cambios
systemctl daemon-reload

# Ver estado de todos los timers
systemctl list-timers

# Ver qué activó un servicio
systemctl show myapp.service -p TriggeredBy
```

---

## ⚠️ Errores comunes

### 1. Olvidar daemon-reload

```bash
# ❌ Crear/editar archivo de unidad pero no recargar
vim /etc/systemd/system/myapp.service
systemctl start myapp.service  # Usa configuración vieja

# ✅ Recargar después de cambios
vim /etc/systemd/system/myapp.service
systemctl daemon-reload
systemctl start myapp.service
```

### 2. Confundir After con Requires

```ini
# ❌ After no garantiza que la unidad esté activa
After=mysql.service
# Si mysql falla, myapp igual intenta arrancar

# ✅ Requires garantiza que esté activa
Requires=mysql.service
After=mysql.service
# Si mysql falla, myapp no arranca
```

### 3. No especificar Type correctamente

```ini
# ❌ Daemon que hace fork pero Type=simple
[Service]
Type=simple
ExecStart=/usr/sbin/myapp --daemon
# systemd pierde el proceso hijo

# ✅ Especificar Type=forking
[Service]
Type=forking
PIDFile=/run/myapp.pid
ExecStart=/usr/sbin/myapp --daemon
```

### 4. Límites de recursos demasiado bajos

```ini
# ❌ MemoryMax muy bajo causa OOM constante
[Service]
MemoryMax=50M
# Servicio se mata repetidamente

# ✅ Usar MemoryHigh para throttling antes de OOM
[Service]
MemoryHigh=200M
MemoryMax=500M
```

### 5. Timer sin Persistent=true

```ini
# ❌ Si el sistema está apagado a la hora programada, se pierde
[Timer]
OnCalendar=daily

# ✅ Persistent=true ejecuta al arrancar si se perdió
[Timer]
OnCalendar=daily
Persistent=true
```

---

## ✅ Buenas prácticas

### 1. Usar overrides en vez de modificar archivos originales

```bash
# ❌ Modificar archivo del paquete
vim /lib/systemd/system/nginx.service

# ✅ Crear override
systemctl edit nginx.service
```

### 2. Especificar límites de recursos

```ini
[Service]
ExecStart=/usr/bin/myapp
MemoryMax=1G
CPUQuota=100%
TasksMax=100
```

### 3. Usar Type=notify cuando sea posible

```ini
# ✅ systemd sabe exactamente cuándo el servicio está listo
[Service]
Type=notify
ExecStart=/usr/bin/myapp
```

### 4. Incluir Restart= para servicios críticos

```ini
[Service]
ExecStart=/usr/bin/myapp
Restart=on-failure
RestartSec=5s
StartLimitIntervalSec=60
StartLimitBurst=3
```

### 5. Usar Condition= para dependencias opcionales

```ini
[Unit]
Description=My Service
ConditionPathExists=/etc/myapp/config.yml
# Solo arranca si existe el archivo de configuración
```

### 6. Documentar unidades

```ini
[Unit]
Description=My Application Service
Documentation=https://docs.example.com/myapp
Documentation=man:myapp(8)
```

### 7. Usar EnvironmentFile para configuración

```ini
[Service]
EnvironmentFile=/etc/default/myapp
ExecStart=/usr/bin/myapp $MYAPP_ARGS
```

---

## 🔗 Referencias internas

- [`systemd_journalctl`](systemd_journalctl.md) — gestión básica de servicios y logs
- [`scenarios/system/01-top-processes`](../scenarios/system/01-top-processes-and-resources.md) — diagnóstico de procesos
- [`scenarios/system/02-log-analysis`](../scenarios/system/02-log-analysis-and-error-tracking.md) — análisis de logs
