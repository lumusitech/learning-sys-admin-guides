# 🧩 Escenario: Memory leak en proceso Python/Node — RSS crece sin límite

**Dominio:** system
**Nivel:** 🔴 Avanzado
**Herramientas:** `top`, `ps`, `watch`, `awk`, `systemctl`
**Archivos:** Sistema en vivo

---

## 🎯 Problema

Un proceso de aplicación (Python, Node.js, Java, etc.) consume cada vez más memoria con el tiempo. El RSS (Resident Set Size) crece sostenidamente sin estabilizarse. Eventualmente el sistema activa el OOM killer y mata el proceso, o el swap se agota y el servidor deja de responder. El problema se repite tras cada reinicio del servicio.

---

## ⚡ Quick command (SRE)

```bash
ps aux --sort=-%mem | head -10
```

---

## ✅ Salida esperada

- un proceso con `%MEM` alto y creciendo (20%+ y subiendo)
- el mismo proceso muestra RSS creciente en observaciones sucesivas
- otros procesos tienen uso de memoria estable
- `dmesg` o `journalctl -k` puede mostrar OOM killer en acción

Interpretación:

- un solo proceso con RSS creciente → memory leak confirmado
- el leak crece proporcionalmente al tiempo de ejecución o al tráfico
- tras reinicio el proceso arranca con RSS bajo y vuelve a crecer → leak progresivo
- el OOM killer mata el proceso → la presión de memoria fue crítica

---

## 🧠 Diagnóstico

Un memory leak ocurre cuando la aplicación reserva memoria (malloc, alloc) pero nunca la libera. En Python es común con referencias circulares, objetos retenidos en caché sin límite, o conexiones de base de datos que no se cierran. En Node.js es común con closures que retienen objetos o streams que no se destruyen.

Patrones clave:

- RSS creciendo sostenidamente → leak de memoria real (no caché ni buffers)
- el proceso consume más memoria después de cada request o tarea → leak proporcional al trabajo
- reinicio del servicio baja la memoria temporalmente → el leak está en el proceso, no en el sistema
- `dmesg | grep oom` muestra el proceso matado → la presión de memoria fue insuficiente
- el proceso usa muchas conexiones de red o DB → posible leak de conexiones no cerradas

👉 Si el RSS crece linealmente con el tiempo, es un leak. Si crece con el tráfico, es un leak en el procesamiento de requests.

---

## 🛠️ Procedimiento (runbook)

### 1. Identificar el proceso con mayor consumo de memoria

```bash
ps aux --sort=-%mem | head -10
```

### 2. Observar el crecimiento de RSS en tiempo real

```bash
PID=<PID_del_proceso>
watch -n 5 "ps -p $PID -o pid,rss,vsz,cmd"
```

### 3. Verificar si el OOM killer ya actuó

```bash
dmesg | grep -i oom
journalctl -k --since "24 hours ago" | grep -i oom
```

### 4. Verificar la configuración de límites del proceso

```bash
cat /proc/$PID/limits
cat /proc/$PID/status | grep -i mem
```

### 5. Verificar si el proceso tiene conexiones abiertas

```bash
lsof -p $PID | wc -l
lsof -p $PID | grep -i tcp | wc -l
```

---

## 🧯 Mitigación

Si se confirma un memory leak:

Verificar:

```bash
PID=<PID_del_proceso>
ps -p $PID -o pid,rss,cmd
```

Acción:

```bash
# Reiniciar el servicio para liberar la memoria inmediatamente
systemctl restart <servicio>

# Configurar reinicio automático periódico como workaround
# En systemd: RuntimeMaxSec=86400 (reiniciar cada 24h)
# En cron: 0 3 * * * systemctl restart <servicio>
```

Mitigación adicional:

```bash
# Limitar memoria máxima del proceso con systemd
# En el unit file: MemoryMax=2G
# O con cgroups directamente:
systemctl set-property <servicio> MemoryMax=2G

# Para Python: habilitar garbage collector explícito
# import gc; gc.collect()
```

Rollback:

```bash
# Si el reinicio causó downtime, restaurar el servicio
systemctl start <servicio>
# Verificar que el servicio está respondiendo
curl -s -o /dev/null -w "%{http_code}" http://localhost:<puerto>/health
```

Casos comunes:

- Python con caché sin límite (dict, list que crece) → configurar `maxsize` en cachés
- Node.js con closures que retienen objetos → usar `--max-old-space-size` como protección
- conexiones de DB no cerradas → usar context managers o connection pools con límites
- logging excesivo en buffers sin flush → configurar buffering y rotación de logs
- objetos grandes retenidos en memoria global → revisar variables globales y singletons

---

## ✅ Interpretación

- la memoria baja tras reinicio y luego vuelve a crecer → leak progresivo confirmado
- la memoria baja y se mantiene estable → el leak estaba en el estado acumulado del proceso
- el OOM killer mata el proceso tras reinicio → el leak es muy rápido, se necesita fix urgente
- la memoria se estabiliza tras limitar conexiones → el leak estaba en las conexiones no cerradas
- el proceso funciona bien en staging pero leak en producción → el leak depende del volumen de datos o tráfico

---

## 🐧 Variante Alpine (OpenRC)

> Este escenario usa `systemctl` en mitigación.

### Variante A — solo systemctl

```bash
# Debian:                          # Alpine:
systemctl restart <servicio>        rc-service <servicio> restart
systemctl status <servicio>         rc-service <servicio> status
```

En Alpine, los límites de memoria se configuran con `ulimit` o directamente en el script de inicio del servicio.

---

## 🧑‍🏫 Modo docente

**Preguntas:** ¿Cómo medís el crecimiento de RSS a lo largo del tiempo? ¿Qué configuración de systemd limita la memoria de un proceso? ¿Qué comando usás para monitorear en tiempo real?

**Ejercicio:** Monitorear RSS de un proceso con watch + ps, aplicar MemoryMax en systemd, reiniciar el servicio.

**Evaluación:** detección del leak por crecimiento sostenido de RSS, mitigación con systemd, verificación post-reinicio.

---

## 🔗 Referencias

- [`ps`](../../guides/ps.md) — visualización de procesos
- [`top`](../../guides/top.md) — monitoreo en tiempo real
- [`lsof`](../../guides/lsof.md) — archivos y conexiones abiertas
- [`scenarios/system/05-system-memory-issues-oom.md`](05-system-memory-issues-oom.md) — OOM killer
- [`scenarios/system/10-swap-exhaustion.md`](10-swap-exhaustion.md) — agotamiento de swap
