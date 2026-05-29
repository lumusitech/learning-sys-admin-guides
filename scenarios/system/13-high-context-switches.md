# 🧩 Escenario: Context switches altísimos — servidor lento con CPU baja

**Dominio:** system
**Nivel:** 🔴 Avanzado
**Herramientas:** `vmstat`, `pidstat`, `sar`, `sysctl`, `perf`
**Archivos:** Sistema en vivo

---

## 🎯 Problema

El servidor está lento, los usuarios reportan timeouts y respuesta tardía, pero la CPU no está alta. El sistema tiene carga moderada y los procesos no parecen consumir recursos excesivos. Sin embargo, el sistema operativo está pasando más tiempo cambiando de contexto entre procesos que ejecutando código real.

---

## ⚡ Quick command (SRE)

```bash
vmstat 1 5 | awk 'NR>2 {print "cs:", $12, "us:", $13, "sy:", $14, "wa:", $16, "idle:", $15}'
```

---

## ✅ Salida esperada

- columnas `cs` (context switches) > 50.000/s en `vmstat`
- CPU `%us` y `%sy` bajos o moderados
- `%idle` alto pero el sistema sigue lento
- `procs r` (procesos en cola) alto

Interpretación:

- `cs` altísimo + CPU baja → el kernel está pasando más tiempo haciendo switch entre procesos que ejecutando código
- `procs r` alto → muchos procesos compitiendo por CPU, pero no la están usando eficientemente
- el sistema se siente lento a pesar de tener CPU libre → el overhead de context switching es el cuello de botella

---

## 🧠 Diagnóstico

Los context switches ocurren cuando el CPU cambia de un proceso a otro. Cada switch tiene un costo: guardar el estado del proceso actual, cargar el estado del siguiente. Si hay demasiados switches por segundo, el CPU pasa más tiempo haciendo gestión de procesos que trabajo real.

Patrones clave:

- `cs` > 50.000/s → overhead significativo de context switching
- `cs` > 200.000/s → el sistema está thrashing de context switches
- muchos hilos en una sola aplicación → la app crea más hilos de los necesarios
- contención de locks → hilos esperando locks y haciendo switch constantemente
- I/O de disco lento → procesos bloqueados en I/O causan switches al despertar

👉 Si la CPU está baja pero el sistema lento, y `cs` está alto, el problema es el overhead de context switching.

---

## 🛠️ Procedimiento (runbook)

### 1. Verificar context switches en tiempo real

```bash
vmstat 1 5
```

Observar la columna `cs`.

### 2. Identificar qué procesos causan más switches

```bash
pidstat -w 1 5
```

### 3. Verificar si el problema es I/O o locks

```bash
vmstat 1 3
```

Observar `%wa` (I/O wait) y `procs b` (bloqueados).

### 4. Verificar configuración de hilos del sistema

```bash
cat /proc/sys/kernel/threads-max
cat /proc/sys/kernel/pid_max
ulimit -u
```

### 5. Verificar si hay contención de locks (avanzado)

```bash
perf lock record -- sleep 5
perf lock report
```

---

## 🧯 Mitigación

Si se confirma que los context switches son el cuello de botella:

Verificar:

```bash
vmstat 1 3 | awk 'NR>2 {print "cs:", $12}'
pidstat -w 1 3
```

Acción:

```bash
# Si una aplicación específica causa los switches, reiniciarla
systemctl restart <servicio>

# Reducir el número de hilos workers si es una aplicación web
# Ejemplo nginx: worker_processes auto → worker_processes 4
# Ejemplo Python: ThreadPoolExecutor(max_workers=100) → max_workers=10
```

Mitigación adicional:

```bash
# Si el problema es I/O, mejorar el almacenamiento o reducir I/O
# Si el problema es contención de locks, revisar la arquitectura de la app

# Verificar si NUMA está causando problemas
numastat
# Si hay imbalance, considerar numactl para pin de procesos
```

Rollback:

```bash
# Restaurar configuración original de workers
# Revertir cambios en el unit file o config de la app
systemctl restart <servicio>
```

Casos comunes:

- aplicación con demasiados hilos workers → reducir `max_workers` o `worker_processes`
- contención de locks en base de datos → revisar consultas concurrentes y transacciones largas
- I/O de disco saturado → procesos bloqueados en I/O causan switches al despertar
- contenedor con demasiados procesos → limitar procesos por contenedor con cgroups
- aplicación que hace polling intensivo → reemplazar con I/O asíncrono o event-driven

---

## ✅ Interpretación

- `cs` baja tras reducir workers → el número de hilos era excesivo
- `cs` baja pero el sistema sigue lento → hay otro cuello de botella (I/O, red, locks)
- `%wa` alto + `cs` alto → el problema real es I/O, no los context switches per se
- los switches vienen de un solo proceso → el problema está en esa aplicación específica
- los switches se distribuyen entre muchos procesos → el sistema está sobrecargado en general

---

## 🐧 Variante Alpine (OpenRC)

> Este escenario usa `systemctl` en mitigación. `pidstat` requiere el paquete `sysstat` (no está en BusyBox).

### Variante D — herramientas extra

```bash
apk add sysstat    # pidstat, sar
apk add procps     # vmstat (si no está disponible)
```

### Variante A — solo systemctl

```bash
# Debian:                          # Alpine:
systemctl restart <servicio>        rc-service <servicio> restart
```

---

## 🔗 Referencias

- [`vmstat`](../../guides/vmstat.md) — CPU, memoria, I/O y context switches
- [`iostat`](../../guides/iostat.md) — métricas de disco (para descartar I/O)
- [`top`](../../guides/top.md) — monitoreo en tiempo real
- [`ps`](../../guides/ps.md) — visualización de procesos
- [`scenarios/system/07-high-io-wait.md`](07-high-io-wait.md) — I/O wait (causa relacionada)
