# top — Guía completa

**Nivel:** 🟢 Básico
**Archivos de práctica:** Sistema en vivo
**Ver escenarios relacionados:** [`high-cpu-runaway-process`](../scenarios/system/04-high-cpu-runaway-process.md), [`memory-issues-oom`](../scenarios/system/05-system-memory-issues-oom.md), [`high-io-wait`](../scenarios/system/07-high-io-wait.md), [`top-processes-and-resources`](../scenarios/system/01-top-processes-and-resources.md)

---

## ⚡ Quick command

`top -b -n 1 | head -20`

> ⚠️ `-b` y `-n` son de procps-ng (Ubuntu/Debian/macOS). En Alpine/BusyBox usá solo `top` o el fallback con `ps`.

---

## ⚡ Quick run

```bash
top
```

El comando más básico. Arranca `top` en modo interactivo actualizándose cada ~3 segundos. Presioná `q` para salir.

---

## Índice

1. [¿Qué es top?](#qué-es-top)
2. [Sintaxis básica](#sintaxis-básica)
3. [Salida clave](#salida-clave)
4. [Opciones principales](#opciones-principales)
5. [Teclas interactivas clave](#teclas-interactivas-clave)
6. [Patrones de uso](#patrones-de-uso)
7. [Uso en troubleshooting](#uso-en-troubleshooting)
8. [Combinación con otras herramientas](#combinación-con-otras-herramientas)
9. [Uno-liners imprescindibles](#uno-liners-imprescindibles)
10. [Errores comunes](#errores-comunes)
11. [Buenas prácticas](#buenas-prácticas)

---

## ¿Qué es top?

`top` es el visor de procesos en tiempo real del sistema Linux. Muestra una pantalla dividida en dos zonas:

- **Header** (parte superior): uptime, load average, tareas, uso de CPU, memoria y swap.
- **Tabla de procesos** (parte inferior): cada proceso con su PID, estado, consumo de CPU/RAM, tiempo de ejecución y comando.

Se usa para diagnosticar en caliente qué está consumiendo recursos del servidor. No necesita instalación extra en prácticamente cualquier Unix-like.

---

## Modelo mental

`top` es el **tablero de instrumentos del servidor en vivo**.

Así como un auto tiene velocímetro, tacómetro y medidor de temperatura, `top` te da:

- **CPU** → qué tan ocupado está cada núcleo
- **Memoria** → cuánta RAM está en uso y cuánta en caché
- **Swap** → si el sistema está usando disco como RAM (alerta)
- **Load average** → cuántos procesos están compitiendo por CPU
- **Procesos** → quién es el responsable de cada consumo

No es una foto (como `ps`), es una ventana que se actualiza sola.

---

## Sintaxis básica

```bash
top [opciones]
```

```bash
# Modo interactivo (default)
top

# Una sola toma en batch (útil para scripts)
top -b -n 1

# Ordenar por uso de memoria
top -o %MEM

# Monitorear procesos específicos
top -p 1234,5678
```

---

## Salida clave

### Header — Línea 1: uptime y load average

```text
top - 14:23:01 up 3 days,  2:15,  3 users,  load average: 0.45, 0.30, 0.25
```

| Campo | Qué significa |
|-------|---------------|
| `14:23:01` | Hora actual del servidor |
| `up 3 days` | Tiempo desde el último arranque |
| `3 users` | Sesiones de usuario activas |
| `load average: 0.45, 0.30, 0.25` | Promedio de procesos en cola (1m, 5m, 15m) |

**Regla de oro del Load Average:**

- Si el load supera la cantidad de núcleos lógicos del servidor (verificá con `nproc`), el sistema está encolando tareas. Hay cuello de botella.
- `load > nproc` sostenido → bottleneck confirmado.
- Los 3 valores muestran la tendencia:
  - `1m > 5m > 15m` → carga creciente (alarma)
  - `1m < 5m < 15m` → carga decreciente (mejorando)
  - `1m ≈ 5m ≈ 15m` → carga estable

### Header — Línea 2: Tasks

```text
Tasks: 123 total,   1 running, 122 sleeping,   0 stopped,   0 zombie
```

| Estado | Significado |
|--------|-------------|
| `running` | Ejecutándose activamente en CPU |
| `sleeping` | Esperando I/O, timer, o evento |
| `stopped` | Detenido por señal (SIGSTOP/SIGTSTP) |
| `zombie` | Muerto pero no recolectado por el padre |

Muchos zombies → problema en el proceso padre.

### Header — Línea 3: CPU states

```text
%Cpu(s):  5.2 us,  2.1 sy,  0.0 ni, 92.1 id,  0.3 wa,  0.2 hi,  0.1 si,  0.0 st
```

| Campo | Nombre | Significado |
|-------|--------|-------------|
| `us` | user | Tiempo de CPU en procesos de usuario |
| `sy` | system | Tiempo de CPU en procesos del kernel |
| `ni` | nice | Tiempo de CPU en procesos renicados |
| `id` | idle | CPU ociosa |
| `wa` | iowait | CPU esperando I/O de disco |
| `hi` | hardware irq | Atención de interrupciones de hardware |
| `si` | software irq | Atención de interrupciones de software |
| `st` | steal | Tiempo "robado" por el hipervisor (VM) |

Patrones clave:

- `wa` alto → cuello de botella de disco
- `us` alto sostenido → proceso consumiendo CPU
- `st` alto → hipervisor sobrecargado (VM)
- `id` muy bajo + `us` o `sy` alto → CPU saturada

Presioná `1` (tecla uno) durante el modo interactivo para desglosar por cada núcleo/hilo de CPU.

### Header — Líneas 4 y 5: Memoria y Swap

```text
MiB Mem :   7956.4 total,    324.5 free,   4123.2 used,   3508.7 buff/cache
MiB Swap:   2048.0 total,   2048.0 free,      0.0 used.   3456.5 avail Mem
```

| Campo | Significado |
|-------|-------------|
| `total` | Total instalado |
| `free` | No usado en absoluto |
| `used` | En uso por procesos |
| `buff/cache` | Usado como caché por el kernel (disponible si hace falta) |
| `avail Mem` | Memoria disponible estimada para nuevos procesos (incluye caché reclaimable) |

Patrón de alerta:

- `used` → 90%+ y `swap used` creciendo → presión real de memoria, riesgo de OOM.

### Tabla de procesos — columnas principales

```text
  PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
 1234 root      20   0  162.8m  12.5m   8.2m S   5.0   0.2   0:45.12 nginx
```

| Columna | Nombre | Significado |
|---------|--------|-------------|
| `PID` | Process ID | Identificador único del proceso |
| `USER` | Usuario | Dueño del proceso |
| `PR` | Priority | Prioridad del proceso (kernel) |
| `NI` | Nice value | Prioridad ajustable por el usuario |
| `VIRT` | Virtual Memory | Memoria virtual total (incluye shared, mapped, swapped) |
| `RES` | Resident Memory | Memoria física real en RAM (la que importa) |
| `SHR` | Shared Memory | Memoria compartida (parte de RES) |
| `S` | State | `R` running, `S` sleeping, `D` uninterruptible, `Z` zombie, `T` stopped |
| `%CPU` | CPU usage | Porcentaje de CPU usado (puede pasar 100% en multi-core) |
| `%MEM` | Memory usage | Porcentaje de RAM física usado |
| `TIME+` | CPU Time | Tiempo total de CPU acumulado |
| `COMMAND` | Command | Nombre del proceso (presioná `c` para ver ruta y args completos) |

---

## Opciones principales

| Opción | Nombre | Qué hace |
|--------|--------|----------|
| `-b` | batch mode | Modo no interactivo. Útil para scripts y pipes. **No disponible en BusyBox** |
| `-n N` | iterations | Número de iteraciones en batch mode. **No disponible en BusyBox** |
| `-d S` | delay | Intervalo de actualización en segundos (ej: `-d 5`) |
| `-p PID` | monitor PIDs | Monitorea solo los PIDs indicados (separados por coma) |
| `-u USER` | user filter | Muestra solo procesos de un usuario |
| `-U USER` | user filter | Similar a `-u` pero coincide con EUID (real user) |
| `-o CAMPO` | sort field | Ordena por un campo específico (ej: `-o %MEM`, `-o %CPU`) |
| `-H` | threads | Muestra hilos (threads) individuales en vez de procesos |
| `-i` | idle | Oculta procesos idle (solo los que están usando CPU) |
| `-E FORMAT` | memory scaling | Escala de memoria en header: `k` `m` `g` `t` (KB, MB, GB, TB) |
| `-E FORMAT` | memory scaling proc | Escala de memoria en procesos: `k` `m` `g` `t` |

### Teclas interactivas clave

Cuando `top` corre en modo interactivo (sin `-b`), estas teclas actúan al instante:

| Tecla | Acción | Para qué sirve |
|-------|--------|----------------|
| `q` | Salir | Cierra `top` |
| `h` | Ayuda | Muestra pantalla de ayuda con todas las teclas |
| `1` | Toggle CPU cores | Desglosa el summary de CPU por cada núcleo/hilo. Esencial en servidores multi-core para ver si un solo núcleo está saturado |
| `c` | Toggle command path | Muestra la ruta completa y argumentos del comando en vez del nombre corto. Vital para distinguir entre varios procesos de Node/Java/Python |
| `e` | Scale memory (procesos) | Cambia la unidad de memoria de cada proceso: KB → MB → GB → TB |
| `E` | Scale memory (header) | Cambia la unidad de memoria del resumen general: KB → MB → GB → TB |
| `k` | Kill | Envía señal a un PID. Pide el PID y la señal (default SIGTERM) |
| `r` | Renice | Cambia la prioridad (nice) de un proceso |
| `M` | Sort by MEM | Ordena por uso de memoria (%MEM descendente) |
| `P` | Sort by CPU | Ordena por uso de CPU (%CPU descendente) |
| `T` | Sort by TIME+ | Ordena por tiempo acumulado de CPU |
| `R` | Reverse sort | Invierte el orden actual |
| `u` | Filter user | Filtra procesos por nombre de usuario |
| `i` | Hide idle | Muestra solo procesos que están usando CPU actualmente |
| `W` | Write config | Guarda la configuración actual de `top` en `~/.toprc` |

> ⚠️ Estas teclas funcionan en `top` de procps-ng (Ubuntu/Debian/macOS nativo, WSL2). **No están disponibles en BusyBox `top`** (Alpine).

---

## Patrones de uso

### 1. Encontrar el proceso que más CPU consume

```bash
top -b -n 1 -o %CPU | head -20
```

O en interactivo: presioná `P` mayúscula para ordenar por CPU.

### 2. Encontrar el proceso que más memoria consume

```bash
top -b -n 1 -o %MEM | head -20
```

O en interactivo: presioná `M` mayúscula para ordenar por memoria.

### 3. Monitorear un proceso específico

```bash
top -p 1234
```

Con múltiples PIDs:

```bash
top -p 1234,5678,9012
```

### 4. Ver hilos individuales de un proceso

```bash
top -H -p 1234
```

Útil para procesos multithread (Java, Node, Python con GIL).

### 5. Monitoreo continuo para log

```bash
top -b -n 10 -d 2 | tee top-snapshot.log
```

Toma 10 muestras cada 2 segundos y las guarda.

### 6. Detectar I/O wait

```bash
top -b -n 1 | grep "Cpu(s)"
```

Si `wa` > 10–20%, hay cuello de botella de disco (ver scenario `07-high-io-wait`).

### 7. Detectar procesos zombie

```bash
top -b -n 1 | grep Z
```

O en interactivo: revisar la columna `S` en busca de `Z`.

---

## Uso en troubleshooting

`top` es el primer comando que ejecuta un SRE ante cualquier incidente de performance.

Se usa en:

| Síntoma | Qué mirar en `top` | Escenario relacionado |
|---------|---------------------|----------------------|
| Servidor lento, CPU al 100% | `%Cpu(s): us` alto, proceso con `%CPU` alto | [`04-high-cpu-runaway-process`](../scenarios/system/04-high-cpu-runaway-process.md) |
| Servidor sin memoria, OOM killer | `MiB Mem: used` > 90%, proceso con `%MEM` alto | [`05-system-memory-issues-oom`](../scenarios/system/05-system-memory-issues-oom.md) |
| Servidor lento, CPU baja | `%Cpu(s): wa` alto, procesos en estado `D` (uninterruptible) | [`07-high-io-wait`](../scenarios/system/07-high-io-wait.md) |
| Procesos colgados, tabla de procesos | Load average alto, procesos zombies | |

**Checklist de diagnóstico rápido con `top`:**

1. `top` (sin flags) → mirar load average y CPU states
2. Presionar `1` → ver si un solo núcleo está saturado
3. Presionar `P` → ordenar por CPU, identificar el proceso responsable
4. Presionar `c` → ver la ruta completa del comando
5. Presionar `M` → ordenar por memoria, ver si hay fuga de RAM
6. Mirar `MiB Swap: used` → si crece, hay presión real de memoria

---

## Combinación con otras herramientas

### top + grep

```bash
# Extraer solo la línea de CPU
top -b -n 1 | grep "Cpu(s)"

# Buscar un proceso específico
top -b -n 1 | grep nginx

# Detectar procesos zombie
top -b -n 1 | grep Z
```

### top + awk

```bash
# Extraer el PID del proceso que más CPU consume
top -b -n 1 -o %CPU | awk '/^ *[0-9]/ {print $1, $9, $12; exit}'

# Formatear salida de memoria
top -b -n 1 | awk '/^MiB Mem/ {print "Usada:", $6, "Libre:", $4}'
```

### top + head

```bash
# Top 5 procesos por CPU
top -b -n 1 -o %CPU | head -12

# Top 5 procesos por memoria
top -b -n 1 -o %MEM | head -12
```

### top + watch

```bash
# Actualizar top cada 2 segundos limpiando pantalla
watch -n 2 'top -b -n 1 -o %CPU | head -15'
```

### top + tee

```bash
# Capturar snapshot y verlo al mismo tiempo
top -b -n 1 | tee top-snapshot-$(date +%Y%m%d-%H%M%S).log
```

### top + vmstat + ps

```bash
# Diagnóstico completo en un solo pipeline
echo "=== CPU ===" && top -b -n 1 | grep "Cpu(s)" && echo "=== Load ===" && top -b -n 1 | head -1 && echo "=== Mem ===" && top -b -n 1 | grep "MiB Mem" && echo "=== Top procesos ===" && top -b -n 1 -o %CPU | head -12
```

---

## Uno-liners imprescindibles

```bash
# Top 5 procesos por CPU (modo batch)
top -b -n 1 -o %CPU | head -12

# Top 5 procesos por memoria
top -b -n 1 -o %MEM | head -12

# Monitorear un proceso específico cada 2 segundos
top -d 2 -p 1234

# Detectar I/O wait en una línea
top -b -n 1 | grep "Cpu(s)"

# Detectar procesos zombie
top -b -n 1 | grep -E "^\s*[0-9]+.*\sZ\s"

# Ver todos los hilos de un proceso
top -H -p 1234

# Guardar 5 snapshots cada 3 segundos
top -b -n 5 -d 3 > top-snapshot.log

# Filtrar solo procesos de un usuario
top -b -n 1 -u www-data

# Ver solo procesos activos
top -i

# Escalar a GB la salida de memoria
top -E g

# Diagnóstico rápido para Slack/SMS
top -b -n 1 | head -5 | grep -E "load average|Cpu|Mem|Swap"

# Alternativa universal (funciona en Alpine sin procps-ng)
ps axo pid,pcpu,pmem,rss,vsz,comm --sort=-pcpu | head -10
```

---

## Errores comunes

### 1. Confundir VIRT con RES

`VIRT` es memoria virtual total (casi siempre gigantesca en procesos como Java o Chromium). `RES` es la memoria física real usada en RAM. La que importa para diagnosticar uso de memoria.

**Dato concreto:** un proceso Java con `-Xms2g -Xmx4g` muestra `VIRT` > 4GB incluso si solo usa 500MB de `RES`. No te asustes por VIRT alta.

### 2. Interpretar mal %CPU en multi-core

`%CPU` puede pasar de 100%. En un servidor de 8 núcleos, un proceso puede mostrar hasta 800% si satura todos los núcleos.

Ejemplo:

```text
PID  %CPU  COMMAND
3456 750.0  java
```

Eso son 7.5 núcleos ocupados. Casi un núcleo completo de un servidor de 8.

### 3. Esperar `-b` o `-n` en BusyBox/Alpine

El `top` de BusyBox no soporta batch mode ni flags de iteración. En ese entorno, corré `top` interactivo o usá `ps` como alternativa:

```bash
ps axo pid,pcpu,pmem,rss,vsz,comm --sort=-pcpu | head -10
```

### 4. Usar `top` en lugar de `uptime` para load average

Si solo necesitás el load average, es más rápido y liviano:

```bash
cat /proc/loadavg
# o
uptime
```

### 5. Olvidar que `top` consume recursos

En servidores con miles de procesos, `top` puede consumir CPU notablemente. Preferí `top -b -n 1` (una sola toma) en vez de dejarlo corriendo en interactivo. O usá `ps` para consultas rápidas.

---

## Buenas prácticas

### 1. Usar `-o CAMPO` para ordenar en batch

Evitá pipes con `sort` cuando puedas ordenar directamente con `-o`:

```bash
# Bien
top -b -n 1 -o %MEM | head -10

# Mal
top -b -n 1 | sort -k10 -rn | head -10
```

### 2. En interactivo, aprender las teclas

Las teclas `P`, `M`, `1`, `c`, `e`/`E` son las más usadas. Memorizalas. Hacen el diagnóstico mucho más rápido.

### 3. Combinar con otras herramientas

`top` solo dice *qué* proceso consume. Para saber *por qué*, combiná con:

- `strace` para ver syscalls
- `lsof` para ver archivos abiertos
- `journalctl` para ver logs
- `vmstat` / `iostat` para contexto de sistema

### 4. Usar `-n 1` para scripts

Nunca dejes `top -b` sin `-n` en un script. Vas a tener un loop infinito de salida.

### 5. Paridad de entornos (WSL2 / macOS vs contenedor Alpine)

- **Local (WSL2, macOS nativo) o SSH a servidor Ubuntu/Debian** → `top` completo de procps-ng. Funcionan todas las teclas interactivas (`1`, `c`, `M`, `P`, `e`/`E`) y los flags `-b -n -o`.
- **SSH a servidor remoto Linux** → misma experiencia completa si es Linux estándar (Ubuntu, Debian, RHEL, CentOS).
- **`docker exec -it <container> top` en Alpine** → solo BusyBox `top`. Sin `-b`, sin `-n`, sin teclas interactivas. Solo corré `top` directamente.
- **Alternativa universal para entornos mínimos:** usá `ps`:

  ```bash
  ps axo pid,pcpu,pmem,rss,comm --sort=-pcpu | head -10
  ```

  Esto funciona en cualquier Unix-like, incluido Alpine.

### 6. Guardar snapshots con timestamp

```bash
top -b -n 1 > top-$(date +%Y%m%d-%H%M%S).log
```

### 7. Configurar `.toprc` para tu flujo

Si siempre querés ver la salida con las mismas columnas y orden, presioná `W` estando en `top` interactivo. Guarda tu configuración en `~/.toprc`.

---

## Referencias internas

- [`04-high-cpu-runaway-process.md`](../scenarios/system/04-high-cpu-runaway-process.md) — diagnóstico de procesos que saturan CPU
- [`05-system-memory-issues-oom.md`](../scenarios/system/05-system-memory-issues-oom.md) — memoria agotada y OOM killer
- [`07-high-io-wait.md`](../scenarios/system/07-high-io-wait.md) — cuello de botella de disco detectado con `wa`
- [`01-top-processes-and-resources.md`](../scenarios/system/01-top-processes-and-resources.md) — análisis general de procesos y recursos
- [`ps.md`](ps.md) — snapshot de procesos (alternativa a `top`)
- [`vmstat.md`](vmstat.md) — métricas de procesos, memoria, swap, I/O y CPU
