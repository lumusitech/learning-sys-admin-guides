# cron — Guía completa

**Nivel:** 🟡 Intermedio
**Archivos de práctica:** `labs/docker-compose.cron.yml`
**Ver escenarios relacionados:** [`system/11-cron-failure`](../scenarios/system/11-cron-failure.md), [`security/04-suspicious-cron`](../scenarios/security/04-suspicious-cron.md)

---

## ⚡ Quick command

`crontab -l`

---

## ⚡ Quick run

```bash
crontab -l                              # Listar tareas del usuario actual
crontab -e                              # Editar tareas del usuario actual
```

---

## 📑 Índice

1. [¿Qué es cron?](#qué-es-cron)
2. [Modelo mental](#modelo-mental)
3. [Sintaxis básica (crontab)](#sintaxis-básica-crontab)
4. [Salida clave](#salida-clave)
5. [Opciones principales](#opciones-principales)
6. [Patrones de uso](#patrones-de-uso)
7. [Uso en troubleshooting](#uso-en-troubleshooting)
8. [Combinación con otras herramientas](#combinación-con-otras-herramientas)
9. [Uno-liners imprescindibles](#uno-liners-imprescindibles)
10. [Errores comunes](#errores-comunes)
11. [Buenas prácticas](#buenas-prácticas)

---

## 🧠 ¿Qué es cron?

**cron** es un daemon que ejecuta comandos en horarios programados. Es el planificador de tareas histórico de Unix. Se configura mediante `crontab` (cron table): archivos con una línea por tarea, cada línea define el momento de ejecución y el comando.

Usos típicos: backups nocturnos, rotación de logs, monitoreo periódico, limpieza de temporales, reportes por correo.

---

## 🧠 Modelo mental

cron es un despertador que suena en cinco dimensiones:

```text
* * * * * comando
- - - - -
| | | | |
| | | | +-- día de semana (0-7, 0=domingo)
| | | +---- mes (1-12)
| | +------ día del mes (1-31)
| +-------- hora (0-23)
+---------- minuto (0-59)
```

Cada campo puede ser un número, comodín (`*`, "cada"), rango (`1-5`), lista (`1,3,5`) o paso (`*/15`, "cada 15").

El daemon `crond` lee los crontabs al arrancar y cuando cambian. No necesita reinicio tras editar un crontab — el cambio es detectado automáticamente.

> ⚠️ En Alpine/BusyBox se usa `dcron` o `busybox crond`. Comandos similares, rutas de logs distintas (`/var/log/messages` en vez de `/var/log/syslog`).

---

## 📝 Sintaxis básica (crontab)

### Formato de una línea

```text
MIN HORA DIA_MES MES DIA_SEM COMANDO
```

### Ejemplos

```bash
# Ejecutar todos los días a las 2am
0 2 * * * /usr/local/bin/backup.sh

# Cada hora (minuto 0)
0 * * * * /usr/local/bin/check.sh

# Cada 15 minutos
*/15 * * * * /usr/local/bin/health.sh

# Lunes a viernes a las 9am
0 9 * * 1-5 /usr/local/bin/reporte.sh

# 1ro y 15 de cada mes a las 3:30am
30 3 1,15 * * /usr/local/bin/facturacion.sh
```

### Directorios del sistema

```bash
/etc/crontab                  # Crontab del sistema (formato con usuario)
/etc/cron.d/                  # Fragmentos de crontab (formato con usuario)
/etc/cron.hourly/             # Scripts por hora
/etc/cron.daily/              # Scripts diarios
/etc/cron.weekly/             # Scripts semanales
/etc/cron.monthly/            # Scripts mensuales
```

El formato de `/etc/crontab` y `/etc/cron.d/` incluye un campo extra: el usuario que ejecuta el comando.

```text
0 2 * * * root /usr/local/bin/backup.sh
```

### Gestión con crontab

```bash
crontab -l                     # Listar (stdout)
crontab -e                     # Editar con $EDITOR (vi por defecto)
crontab -r                     # Eliminar crontab completo
crontab -u admin -l            # Listar crontab de otro usuario (solo root)
crontab /ruta/archivo          # Importar desde archivo (reemplaza)
```

### Variables de entorno en crontab

```bash
SHELL=/bin/sh
PATH=/usr/local/bin:/usr/bin:/bin
MAILTO=admin@empresa.com

0 2 * * * backup.sh
```

`MAILTO` dirige la salida del comando a un correo. Si no hay MTA configurado, el correo se pierde (fallo silencioso).

---

## 🔑 Salida clave

### crontab -l

```text
0 2 * * * /usr/local/bin/backup.sh
0 3 * * * /usr/local/bin/reporte.sh
```

- Lista todas las tareas del usuario.
- Si no hay salida ni error → no hay tareas configuradas.
- Si sale `no crontab for <user>` → el usuario no tiene crontab (no es un error).

### Logs de cron

```text
Mar 15 02:00:01 host CRON[1234]: (root) CMD (/usr/local/bin/backup.sh)
Mar 15 02:00:02 host CRON[1235]: (root) CMD (/usr/local/bin/reporte.sh)
Mar 15 02:00:02 host backup.sh: BACKUP: Completado OK
```

- Cada ejecución se loguea con PID y comando.
- La salida del comando aparece después, con el nombre del script.
- Si el comando falla, el error se loguea según redirección del script.

---

## 🎛️ Opciones principales

### crond

| Opción | Descripción |
|--------|------------|
| `-b` | Background (daemon) |
| `-l N` | Nivel de log (0-8, 8 es debug completo) |
| `-L archivo` | Archivo de log (por defecto syslog) |

### crontab

| Opción | Descripción |
|--------|------------|
| `-l` | Listar tareas |
| `-e` | Editar con editor |
| `-r` | Eliminar crontab |
| `-u usuario` | Operar sobre crontab de otro usuario (root) |
| `-i` | Confirmar antes de borrar (con -r) |

---

## 📋 Patrones de uso

### Programar un backup diario

```bash
echo "0 2 * * * /usr/local/bin/backup.sh" >> /etc/crontab
# O mejor: usar crontab -e
```

### Ejecutar cada vez que arranca el sistema

```bash
@reboot /usr/local/bin/cleanup.sh
```

### Redirigir salida a archivo de log

```bash
0 2 * * * /usr/local/bin/backup.sh >> /var/log/backup.log 2>&1
```

Sin redirección, cron envía la salida por correo al dueño del crontab. Si no hay MTA, el output se pierde.

### Monitorear uso de disco cada hora

```bash
0 * * * * df -h | mail -s "Disk usage" admin@empresa.com
```

### Sincronizar archivos cada 30 minutos

```bash
*/30 * * * * rsync -a /datos/ usuario@backup:/datos/
```

### Rotar logs con logrotate (automático)

```bash
# /etc/logrotate.conf ya suele tener configuración por defecto
# logrotate se ejecuta desde cron.daily
0 6 * * * root test -x /usr/sbin/logrotate && /usr/sbin/logrotate /etc/logrotate.conf
```

---

## 🔍 Uso en troubleshooting

### Paso 1: Verificar que el daemon está corriendo

```bash
ps aux | grep crond
systemctl status cron          # systemd
rc-service crond status        # OpenRC
```

### Paso 2: Listar tareas del usuario

```bash
crontab -l
```

### Paso 3: Leer logs de cron

```bash
# systemd
journalctl -u cron --since "1 hour ago"

# Debian/Ubuntu
grep CRON /var/log/syslog

# Alpine/BusyBox
logread | grep crond
```

### Paso 4: Verificar permisos del script

```bash
ls -l /usr/local/bin/backup.sh   # Debe tener +x
file /usr/local/bin/backup.sh     # Debe ser script válido
```

### Paso 5: Debuggear el PATH

Agregar esto al inicio del script para ver qué entorno vehicular:

```bash
# En el script
env > /tmp/cron-env.log 2>&1
```

O forzar un PATH completo en el crontab:

```bash
PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
SHELL=/bin/sh

0 2 * * * /usr/local/bin/backup.sh
```

### Paso 6: Probar el comando manualmente

```bash
# Ejecutar con el mismo entorno que cron (sin alias, sin variables de usuario)
su -s /bin/sh -c "/usr/local/bin/backup.sh" root
```

### Patrones de fallo en logs

| Log / síntoma | Causa probable |
|---------------|---------------|
| `(root) CMD (comando)` + sin salida | Comando ejecutado pero no produce output |
| `exit status 127` | Comando no encontrado (PATH incorrecto) |
| `exit status 126` | Script sin permisos de ejecución |
| `exit status 1` | Error genérico del script |
| No hay entrada CRON en logs | Servicio cron no corriendo |
| `(admin) MAIL (mailed 0 bytes)` | MAILTO configurado pero sin MTA |

---

## 🛠️ Combinación con otras herramientas

### cron + logrotate

```bash
# /etc/cron.daily/logrotate ya lo configura automáticamente
# Verificar con:
logrotate -d /etc/logrotate.conf   # Dry run
```

### cron + rsync

```bash
0 3 * * * rsync -a --delete /origen/ /destino/ >> /var/log/rsync-cron.log 2>&1
```

### cron + df + mail

```bash
0 8 * * * df -h | mail -s "Reporte diario de disco" admin@empresa.com
```

### cron + systemd journal

```bash
# Si el script loguea al journal, se puede ver con:
journalctl -t backup-script --since "1 hour ago"
```

### cron + grep + awk (parseo de logs)

```bash
0 7 * * * grep "ERROR" /var/log/app.log | awk '{print $1, $5}' | sort | uniq -c > /tmp/errores-diarios.txt
```

---

## 💡 Uno-liners imprescindibles

```bash
crontab -l                                              # Listar tareas
crontab -e                                              # Editar tareas
journalctl -u cron --since "1 hour ago"                 # Logs recientes de cron (systemd)
grep CRON /var/log/syslog | tail -20                     # Últimas 20 ejecuciones (Debian)
logread | grep crond | tail -20                          # Últimas 20 ejecuciones (Alpine)
ps aux | grep crond                                      # Verificar si cron está corriendo
ls -la /etc/cron*                                        # Ver todos los cron del sistema
crontab -l | wc -l                                       # Contar tareas programadas
cat /etc/crontab                                         # Crontab del sistema
run-parts /etc/cron.daily --test                         # Probar scripts diarios
crontab -r -i                                            # Borrar crontab con confirmación
```

---

## ⚠️ Errores comunes

- **Usar rutas relativas en el comando**. cron tiene un PATH mínimo (`/usr/bin:/bin`). Siempre usar rutas absolutas o definir `PATH` al inicio del crontab.
- **No redirigir salida**. Por defecto cron envía stdout/stderr por correo. Si no hay MTA, la salida se pierde sin aviso.
- **Olvidar permisos de ejecución**. El script debe tener `chmod +x`. Si no, cron lo ejecuta pero falla con exit 126.
- **Confundir `crontab -e` con editar `/etc/crontab`**. `crontab -e` es por usuario; `/etc/crontab` es del sistema y requiere formato con usuario.
- **Asumir que el script tiene las mismas variables de entorno que el shell interactivo**. cron ejecuta con un entorno mínimo. Debuggear con `env > /tmp/cron-debug.log` al inicio del script.
- **Poner `@reboot` esperando que funcione como systemd**. `@reboot` no soporta dependencias ni orden de arranque. Si necesitás garantías de orden, usá systemd timers.
- **No verificar que el servicio cron esté corriendo**. Es la causa más simple y más pasada por alto.

---

## ✅ Buenas prácticas

- **Siempre redirigir salida**: `>> /var/log/mi-cron.log 2>&1`. Sin esto, si no hay MTA, los errores se pierden.
- **Usar rutas absolutas** en comandos y scripts.
- **Testear el comando manualmente** antes de programarlo con el mismo usuario que lo ejecutará.
- **Poner `set -e` al inicio de los scripts** para que fallen rápido si algo sale mal.
- **Monitorear la ejecución** con `journalctl -u cron` o revisando `/var/log/syslog`.
- **Documentar cada tarea** con un comentario en el crontab (`# Backup diario de BD`).
- **Usar `MAILTO`** si tenés MTA configurado para recibir fallos por correo.
- **Preferir systemd timers** sobre cron para servicios modernos: más control, logging integrado, dependencias.
- **Hacer backup del crontab** antes de editarlo: `crontab -l > ~/crontab.backup.$(date +%F)`.

---

## 🔗 Referencias internas

- [`systemd_journalctl`](systemd_journalctl.md) — logs de servicios y timers
- [`grep`](grep.md) — filtrar logs de cron
- [`redirections`](redirections.md) — redirigir salida de cron jobs
- [`systemd`](systemd.md) — timers como reemplazo moderno de cron
- [`df`](df.md) — monitoreo periódico de disco con cron
- [`scenario`](../scenarios/system/11-cron-failure.md) — tarea cron que falla en silencio
- [`scenario`](../scenarios/security/04-suspicious-cron.md) — entrada cron sospechosa
- [`lab`](../labs/docker-compose.cron.yml) — laboratorio cron con fallos preconfigurados
