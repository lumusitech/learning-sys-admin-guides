# 🧩 Escenario: Proceso sospechoso — detección de actividad inesperada

**Dominio:** security
**Nivel:** 🔴 Avanzado
**Herramientas:** `ps`, `lsof`, `ss`, `top`, `strace`
**Archivos:** Sistema en vivo

---

## 🎯 Problema

Durante una auditoría de seguridad o monitoreo rutinario, se detecta un proceso con comportamiento anómalo: consumo inesperado de CPU, conexiones de red a IPs desconocidas, binarios en ubicaciones temporales, o un padre que no debería haberlo iniciado. El proceso podría ser un crypto miner, un backdoor, un reverse shell, o software no autorizado que compromete la integridad del sistema.

---

## ⚡ Quick command (SRE)

```bash
ps auxf --sort=-%cpu | head -20
```

---

## ✅ Salida esperada

- lista de procesos ordenada por consumo de CPU
- procesos con nombres genéricos o aleatorios (`/tmp/.x`, `kworker`, `minerd`)
- procesos con padre inesperado (ej: `bash` hijo de `apache`, `sshd` hijo de `cron`)
- procesos ejecutados desde `/tmp`, `/dev/shm`, `/var/tmp`
- procesos con conexiones de red activas a IPs externas

Interpretación:

- proceso desde `/tmp` o `/dev/shm` → altamente sospechoso, binario temporal
- proceso con nombre disfrazado de sistema (ej: `[kworker/0:1]` en `/tmp`) → ofuscación intencional
- proceso hijo de `apache` o `nginx` que hace conexión saliente → posible reverse shell
- proceso con 100% CPU y nombre genérico → posible crypto miner
- proceso sin binario en disco (eliminado tras ejecutarse) → evidencia de intrusión

---

## 🧠 Diagnóstico

Los atacantes y software malicioso buscan persistencia y recursos. Un crypto miner consume CPU, un reverse shell mantiene conexiones de red abiertas, y un backdoor se ejecuta desde ubicaciones inusuales. La clave es correlacionar: padre, hijo, ubicación del binario, conexiones de red y consumo de recursos.

Patrones clave:

- binario en `/tmp` o `/dev/shm` → ejecutable temporal, probablemente malicioso
- proceso con `ESTABLISHED` a IP externa desconocida → posible reverse shell o C2
- proceso hijo de servicio web (apache, nginx) con conexión saliente → explotación de web app
- proceso con nombre de kernel pero ubicación incorrecta → disfrazado
- proceso zombie persistente → posible shell interactiva que no se cerró bien

👉 Si un proceso no se puede atribuir a un servicio conocido, ejecutarse desde ubicación sospechosa, o mantiene conexiones a IPs no autorizadas, es prioridad de investigación.

---

## 🛠️ Procedimiento (runbook)

### 1. Identificar los procesos más pesados

```bash
ps aux --sort=-%cpu | head -15
ps aux --sort=-%mem | head -15
```

### 2. Ver el árbol de procesos para entender la relación padre-hijo

```bash
ps auxf | grep -v grep | grep -E "bash|sh|python|perl|nc|ncat|socat"
```

### 3. Verificar conexiones de red activas de procesos sospechosos

```bash
ss -tlnp
ss -tnp | grep ESTABLISHED
```

### 4. Ver la ubicación del binario ejecutado

```bash
ls -la /proc/<PID>/exe
cat /proc/<PID>/cmdline | tr '\0' ' '
```

### 5. Verificar los archivos abiertos por el proceso

```bash
lsof -p <PID>
lsof -i -p <PID>
```

### 6. Rastrear llamadas del sistema en tiempo real

```bash
strace -p <PID> -e trace=network,process -f
```

---

## 🧯 Mitigación

Si se confirma un proceso malicioso:

Verificar:

```bash
ls -la /proc/<PID>/exe
cat /proc/<PID>/cmdline | tr '\0' ' '
ss -tnp | grep <PID>
```

Acción:

```bash
# Matar el proceso y todos sus hijos
kill -9 <PID>
pkill -9 -P <PPID>

# Eliminar el binario malicioso
rm -f /tmp/.x /dev/shm/minerd /ruta/al/binario

# Verificar que no se reincorpora (persistencia)
watch -n 5 'ps aux | grep <nombre_proceso>'
```

Mitigación adicional:

```bash
# Revisar mecanismos de persistencia
crontab -l -u <usuario>
ls -la /etc/cron.d/ /etc/cron.daily/
systemctl list-timers --all

# Verificar si el binario fue eliminado tras ejecutarse
ls -la /proc/<PID>/exe 2>/dev/null
# "(deleted)" indica que el atacante eliminó el binario para cubrir rastros
```

Rollback:

```bash
# Si se mató un proceso legítimo por error
# Reiniciar el servicio correspondiente
systemctl restart <servicio>
```

Casos comunes:

- crypto miner en `/tmp` → ejecutable descargado por explotación de vulnerabilidad
- reverse shell hijo de apache → explotación de RCE en web app
- proceso con nombre `[kworker]` en `/tmp` → disfrazado como kernel worker
- binario eliminado tras ejecutarse → atacante cubrió rastros

---

## ✅ Interpretación

- el proceso no tiene binario en disco (muestra "deleted") → atacante eliminó evidencia
- el proceso mantiene conexión ESTABLISHED a IP externa → probable reverse shell o C2
- el proceso consume 100% CPU con nombre genérico → probable crypto miner
- el proceso es hijo de servicio web con conexión saliente → explotación de aplicación
- el proceso reaparece tras ser matado → hay mecanismo de persistencia (cron, systemd timer, script de inicio)

---

## 🐧 Variante Alpine (OpenRC)

> Este escenario no usa `systemctl`, `journalctl`, `apt` ni `ufw`. No requiere variante Alpine.

---

## 🔗 Referencias

- [`ps`](../../guides/ps.md) — listado y filtrado de procesos
- [`strace`](../../guides/strace.md) — trazado de llamadas al sistema
- [`lsof`](../../guides/lsof.md) — archivos y conexiones abiertas por procesos
- [`top`](../../guides/top.md) — monitoreo de recursos en tiempo real
- [`scenarios/security/04-suspicious-cron.md`](04-suspicious-cron.md) — persistencia vía cron
- [`scenarios/system/09-fork-bomb.md`](../system/09-fork-bomb.md) — proceso replicante
