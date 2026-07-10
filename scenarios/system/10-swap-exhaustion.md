# 🧩 Escenario: Agotamiento de swap — sistema swapping hasta quedar inaccesible

**Dominio:** system
**Nivel:** 🟡 Intermedio
**Herramientas:** `free`, `vmstat`, `ps`, `sysctl`, `top`
**Archivos:** Sistema en vivo

---

## 🎯 Problema

El sistema se vuelve extremadamente lento, los comandos tardan segundos en ejecutarse y eventualmente deja de responder. Los usuarios reportan timeouts y desconexiones SSH. El sistema puede estar a punto de ser terminado por el OOM killer o quedar completamente inaccesible por thrashing de swap.

---

## ⚡ Quick command (SRE)

```bash
free -h && vmstat 1 3
```

---

## ✅ Salida esperada

- `Swap used` > 0 y creciendo
- columnas `si` (swap in) y `so` (swap out) de `vmstat` activas y altas
- `available` en `free` muy bajo o en 0
- `procs r` (procesos en cola) alto en `vmstat`

Interpretación:

- swap usado creciendo + `si`/`so` activos → presión real de memoria, el sistema está haciendo thrashing
- `available` bajo → no hay memoria libre real, el sistema depende del swap para funcionar
- `procs r` alto → muchos procesos esperando CPU o I/O (bloqueados por swap)
- swap llenándose → riesgo de OOM killer o colgar el sistema

---

## 🧠 Diagnóstico

El agotamiento de swap ocurre cuando la RAM se llena y el sistema comienza a mover páginas de memoria al disco (swap). Si el swap también se llena, el sistema entra en thrashing: pasa más tiempo moviendo páginas entre RAM y swap que ejecutando procesos reales.

Patrones clave:

- swap usado creciendo + `si`/`so` activos → el sistema está swapping activamente
- swap lleno + `available` bajo → el sistema está al límite, OOM killer puede activarse
- `procs r` alto → los procesos están esperando, el sistema está thrashing
- un proceso consumiendo mucha memoria → probable leak o configuración incorrecta
- múltiples procesos compitiendo por RAM → sobrecarga legítima o falta de recursos

👉 Si el swap está lleno y la RAM también, el sistema tiene minutos antes de colgar o activar OOM killer.

---

## 🛠️ Procedimiento (runbook)

### 1. Verificar estado de memoria y swap

```bash
free -h
```

### 2. Ver actividad de swap en tiempo real

```bash
vmstat 1 5
```

Observar columnas `si` (swap in) y `so` (swap out).

### 3. Identificar los principales consumidores de memoria

```bash
ps aux --sort=-%mem | head -15
```

### 4. Verificar si el OOM killer ya actuó

```bash
dmesg | grep -i oom
```

### 5. Verificar configuración de swapiness

```bash
cat /proc/sys/vm/swappiness
```

Un valor alto (> 60) hace que el sistema use swap agresivamente.

---

## 🧯 Mitigación

Si se confirma presión de swap:

Verificar:

```bash
free -h
vmstat 1 3
```

Acción:

```bash
# Reducir swappiness para que el sistema priorice RAM
sysctl vm.swappiness=10

# Matar el proceso que más memoria consume (si es un leak)
ps aux --sort=-%mem | head -5
kill -TERM <PID_del_leak>
```

Mitigación adicional:

```bash
# Si hay un proceso con leak de memoria, reiniciarlo
systemctl restart <servicio>

# Si no es posible matar procesos, agregar swap temporal
fallocate -l 2G /tmp/swapfile
chmod 600 /tmp/swapfile
mkswap /tmp/swapfile
swapon /tmp/swapfile
```

Rollback:

```bash
# Restaurar swappiness original
sysctl vm.swappiness=60

# Quitar swap temporal si se creó
swapoff /tmp/swapfile
rm /tmp/swapfile
```

Casos comunes:

- aplicación con memory leak → RSS crece sin límite hasta agotar RAM
- demasiados procesos compitiendo por RAM → falta de recursos o configuración incorrecta
- swappiness muy alto → sistema usa swap innecesariamente cuando hay RAM disponible
- contenedor sin límites de memoria → consume toda la RAM del host

---

## ✅ Interpretación

- la presión de swap baja tras matar el proceso → el problema era un leak de memoria
- la presión persiste tras matar un proceso → hay múltiples consumidores o la RAM es insuficiente
- el sistema se recupera con swap temporal → se necesita más RAM o optimizar la aplicación
- el OOM killer activó → la RAM y el swap estaban completamente agotados
- el swappiness era muy alto → el sistema estaba usando swap innecesariamente

---

## 🐧 Variante Alpine (OpenRC)

> Este escenario no usa `systemctl`, `journalctl`, `apt` ni `ufw`. No requiere variante Alpine.

---

## 🧑‍🏫 Modo docente

**Preguntas:** ¿Qué columnas de vmstat indican thrashing de swap? ¿Qué ajuste de sysctl alivia la presión de swap? ¿Cómo identificás el proceso que está haciendo swap?

**Ejercicio:** Detectar thrashing con vmstat (si/so), reducir vm.swappiness, identificar y matar el proceso causante.

**Evaluación:** detección correcta de thrashing por vmstat, ajuste de sysctl, identificación del proceso leak.

---

## 🔗 Referencias

- [`free`](../../guides/free.md) — memoria y swap
- [`vmstat`](../../guides/vmstat.md) — CPU, memoria, I/O en un comando
- [`ps`](../../guides/ps.md) — visualización de procesos
- [`top`](../../guides/top.md) — monitoreo en tiempo real
- [`scenarios/system/05-system-memory-issues-oom.md`](05-system-memory-issues-oom.md) — OOM killer (continuación natural)
