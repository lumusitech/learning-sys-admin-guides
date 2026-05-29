# 🧩 Escenario: Tarea cron que falla en silencio — sin logs ni errores visibles

**Dominio:** system
**Nivel:** 🟡 Intermedio
**Herramientas:** `crontab`, `grep`, `diff`, `journalctl`, `mail`
**Archivos:** Sistema en vivo

---

## 🎯 Problema

Una tarea programada con cron dejó de ejecutarse o falla sin generar logs visibles. El equipo no recibe alertas y solo se entera cuando el backup no se hizo, el reporte no se generó o el servicio dependiente falla. No hay errores explícitos en syslog ni en los logs del sistema.

---

## ⚡ Quick command (SRE)

```bash
crontab -l && grep CRON /var/log/syslog 2>/dev/null || journalctl -u cron --since "1 hour ago"
```

---

## ✅ Salida esperada

- la tarea aparece en `crontab -l` con la sintaxis correcta
- en los logs se ven entradas `CRON` para otras tareas, pero no para la que falla
- si la tarea se ejecutó, buscar su salida en `/var/mail/<usuario>` o en el log configurado

Interpretación:

- la tarea existe en crontab pero no aparece en logs → no se ejecutó (problema de permisos, PATH, o servicio cron caído)
- la tarea aparece en logs pero sin salida → falló silenciosamente (error de script, archivo inexistente)
- la tarea genera salida pero no se envía a ningún lado → falta de configuración de MAILTO o redirect de salida

---

## 🧠 Diagnóstico

Cron falla silenciosamente por razones que no son obvias: variables de entorno faltantes, PATH incompleto, permisos incorrectos, servicio cron no corriendo, o el script tiene errores que cron no loguea.

Patrones clave:

- tarea no aparece en logs → el servicio cron no está corriendo o la sintaxis de la tarea es incorrecta
- tarea aparece en logs pero sin ejecución → el script no tiene permisos de ejecución o el intérprete no existe
- tarea ejecuta pero no produce efecto → el script falla internamente sin código de salida
- `No MTA installed` en logs → cron intenta enviar mail pero no hay MTA configurado
- PATH diferente en cron → el script usa comandos que no están en el PATH de cron

👉 El 90% de los fallos de cron son: PATH incorrecto, permisos de script, o servicio cron no corriendo.

---

## 🛠️ Procedimiento (runbook)

### 1. Verificar que el servicio cron está corriendo

```bash
systemctl status cron
ps aux | grep cron
```

### 2. Verificar que la tarea existe en el crontab correcto

```bash
crontab -l
crontab -l -u <usuario>
```

### 3. Buscar ejecuciones recientes en logs

```bash
grep CRON /var/log/syslog | tail -20
# o en sistemas con journalctl:
journalctl -u cron --since "24 hours ago" | tail -20
```

### 4. Verificar si el script tiene permisos de ejecución

```bash
ls -la <script.sh>
```

### 5. Verificar la sintaxis de la tarea cron

```bash
crontab -l | grep -E '^\S'
```

Formato: `minuto hora día mes día_semana comando`

### 6. Verificar si hay errores de PATH o entorno

```bash
# Agregar esto al crontab para debug temporal:
# * * * * * env > /tmp/cron-env.log
# Luego comparar con el PATH del shell:
echo $PATH
cat /tmp/cron-env.log | grep PATH
```

---

## 🧯 Mitigación

Si se confirma que cron no ejecuta la tarea:

Verificar:

```bash
systemctl status cron
crontab -l
```

Acción:

```bash
# Si el servicio cron no está corriendo
systemctl start cron
systemctl enable cron

# Si el script no tiene permisos
chmod +x <script.sh>

# Si es un problema de PATH, usar rutas absolutas en el crontab
# 0 2 * * * /usr/bin/python3 /opt/scripts/backup.py >> /var/log/backup.log 2>&1
```

Mitigación adicional:

```bash
# Configurar MAILTO para recibir errores por email
crontab -e
# Agregar al inicio: MAILTO=admin@empresa.com

# O redirigir toda la salida a un log
# 0 2 * * * /opt/scripts/backup.sh >> /var/log/cron-backup.log 2>&1
```

Rollback:

```bash
# Restaurar crontab original si se modificó
crontab -l > /tmp/crontab-backup.txt
# Editar el crontab y corregir
crontab -e
```

Casos comunes:

- servicio cron detenido tras reboot → no estaba habilitado con `systemctl enable`
- PATH incompleto en cron → el script usa comandos que no están en `/usr/bin` o `/bin`
- permisos de script incorrectos → el archivo no tiene `+x` o el shebang es incorrecto
- MAILTO no configurado → errores se pierden en `/var/mail/` sin que nadie los lea
- sintaxis incorrecta en crontab → campo de día de la semana malinterpretado

---

## ✅ Interpretación

- la tarea aparece en logs tras reiniciar cron → el servicio estaba caído
- la tarea se ejecuta tras agregar rutas absolutas → el problema era PATH
- la tarea genera errores visibles tras configurar MAILTO o redirect → los errores siempre estuvieron, solo no se veían
- la tarea no aparece en logs → revisar sintaxis del crontab o si el usuario es correcto
- el script funciona manualmente pero no desde cron → variables de entorno o PATH diferente

---

## 🐧 Variante Alpine (OpenRC)

> Este escenario usa `systemctl` y `journalctl`.

### Variante B — systemctl + journalctl

```bash
# Debian:                          # Alpine:
systemctl status cron              rc-service crond status
systemctl start cron               rc-service crond start
systemctl enable cron              rc-update add crond
journalctl -u cron --since "1h"    logread | grep crond | tail -20
```

En Alpine, el servicio se llama `crond` (no `cron`). Los logs van a `/var/log/messages` o `logread`.

---

## 🔗 Referencias

- [`grep`](../../guides/grep.md) — filtrar logs de cron
- [`systemd_journalctl`](../../guides/systemd_journalctl.md) — logs de systemd
- [`scenarios/system/03-new-server-provisioning.md`](03-new-server-provisioning.md) — configuración inicial de servicios
