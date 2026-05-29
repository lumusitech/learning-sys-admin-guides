# ps — Guía completa

**Nivel:** 🟢 Básico
**Archivos de práctica:** Sistema en vivo
**Ver escenarios relacionados:** [`system/01-top-processes`](../scenarios/system/01-top-processes-and-resources.md), [`system/04-high-cpu-runaway`](../scenarios/system/04-high-cpu-runaway-process.md), [`system/05-memory-issues-oom`](../scenarios/system/05-system-memory-issues-oom.md), [`system/07-high-io-wait`](../scenarios/system/07-high-io-wait.md), [`system/08-zombie-processes`](../scenarios/system/08-zombie-processes.md)

---

## ⚡ Quick command

`ps aux`

> ⚠️ `ps aux` funciona en procps (Debian/Ubuntu). En Alpine/BusyBox usá `ps aux` (misma sintaxis) o `ps -eo pid,ppid,user,comm` para portabilidad máxima.

---

## ⚡ Quick run

```bash
ps aux --sort=-%cpu | head -15
```

---

## 📑 Índice

1. [¿Qué es ps?](#qué-es-ps)
2. [Sintaxis básica](#sintaxis-básica)
3. [Salida clave — columnas](#salida-clave--columnas)
4. [Estados de proceso (STAT)](#estados-de-proceso-stat)
5. [Opciones principales](#opciones-principales)
6. [Salida personalizada (-o)](#salida-personalizada--o)
7. [Opciones de ordenamiento](#opciones-de-ordenamiento)
8. [Árbol de procesos](#árbol-de-procesos)
9. [Patrones de uso](#patrones-de-uso)
10. [Uso en troubleshooting](#uso-en-troubleshooting)
11. [Combinación con otras herramientas](#combinación-con-otras-herramientas)
12. [Uno-liners imprescindibles](#uno-liners-imprescindibles)
13. [Errores comunes](#errores-comunes)
14. [Buenas prácticas](#buenas-prácticas)

---

## 🧠 ¿Qué es ps?

**ps** (process status) toma una instantánea de los procesos en ejecución. A diferencia de `top` (que es un panel en vivo), `ps` captura el estado en un momento exacto y lo vuelca a stdout.

Se usa para:

- listar procesos por consumo de CPU, memoria o tiempo;
- detectar procesos zombie, en estado D, o huérfanos;
- construir pipelines de análisis (`ps | awk | sort | head`);
- auditar qué usuario ejecuta qué comando;
- obtener el PID para enviarle señales (`kill`).

No necesita instalación en ningún Unix-like.

---

## 🧠 Modelo mental

`ps` es la **foto del semáforo de procesos**. No muestra tendencia (eso es `top`), muestra el **dónde está cada proceso ahora**.

- `ps aux` → todos los procesos, todos los usuarios, formato BSD.
- `ps -ef` → todos los procesos, formato UNIX estándar.
- `ps axo` → todos los procesos, columnas que vos elegís.

Cada proceso tiene un PID (identificador) y un PPID (PID del padre). El proceso con PID 1 es `init` (systemd en Debian, OpenRC en Alpine). Cuando un padre muere antes que el hijo, el hijo queda huérfano y es adoptado por PID 1. Cuando un hijo termina pero el padre no lee su estado de salida, queda **zombie**.

---

## 📝 Sintaxis básica

```bash
ps [opciones]
```

`ps` soporta tres estilos de opciones:

| Estilo | Sintaxis | Ejemplo |
|--------|----------|---------|
| UNIX | `-` prefijo | `ps -ef` |
| BSD | sin prefijo | `ps aux` |
| GNU | `--` prefijo | `ps --sort=-%cpu` |

Pueden mezclarse: `ps aux --sort=-%mem`.

### Comandos más usados

```bash
ps aux              # BSD: todos los procesos, todos los usuarios
ps -ef              # UNIX: todos los procesos, formato largo
ps -ejH             # Árbol de procesos
ps -p <PID>         # Proceso específico por PID
ps -u <usuario>     # Procesos de un usuario
ps -C <nombre>      # Procesos por nombre de comando
```

---

## 🔑 Salida clave — columnas

Salida de `ps aux`:

```text
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.1 168780 13468 ?        Ss   08:00   0:05 /sbin/init
root       423  0.0  0.0      0     0 ?        I<   08:00   0:00 [kworker/0:1H]
www-data  1234  2.1  3.4 512340 280456 ?       S    09:30   1:23 nginx: worker process
```

| Columna | Significado | Cómo interpretarla |
|---------|-------------|-------------------|
| `USER` | Dueño del proceso | Saber qué usuario lanzó el comando |
| `PID` | Process ID | Identificador único. Se usa para `kill`, `lsof`, etc. |
| `%CPU` | Uso de CPU en % | > 80% sostenido → posible runaway |
| `%MEM` | Uso de RAM en % | Crece sin bajar → posible memory leak |
| `VSZ` | Memoria virtual (KB) | Incluye libs compartidas, mmap. Poco útil para troubleshooting. |
| `RSS` | Memoria residente (KB) | RAM física real que usa el proceso. El número que importa. |
| `TTY` | Terminal asociada | `?` → demonio sin terminal. `pts/0` → sesión SSH. |
| `STAT` | Estado del proceso | Ver tabla de estados abajo. |
| `START` | Hora de inicio | ¿Arrancó hace 5 minutos o 5 días? |
| `TIME` | Tiempo total de CPU | No es tiempo real. Si un proceso tiene TIME alto y %CPU bajo, trabajó mucho pero ahora está en espera. |
| `COMMAND` | Comando con argumentos | Última columna. Puede extenderse a varias líneas. |

### MEM% vs RSS

- `%MEM` es relativo: 5% de 16 GB = 800 MB. Útil para comparar entre procesos.
- `RSS` es absoluto en KB: `280456` = 274 MB. Útil para saber exactamente cuánto consume.
- Para ver RSS en MB legible: `ps aux | awk '{ printf "%s %.1f MB\n", $11, $6/1024 }'`.

---

## Estados de proceso (STAT)

El campo `STAT` puede tener varios caracteres. El **primer carácter** es el estado principal:

| Estado | Significado | Implicación de troubleshooting |
|--------|------------|-------------------------------|
| `R` | Running o runnable | Está ejecutándose o en cola de CPU |
| `S` | Sleeping (interrumpible) | Espera un evento. Normal en la mayoría de procesos. |
| `D` | Disk sleep (ininterrumpible) | Espera I/O de disco. **No recibe señales. No se puede matar.** |
| `Z` | Zombie | Terminó pero el padre no leyó su estado. **No consume CPU/RAM pero ocupa un slot en la tabla de procesos.** |
| `T` | Stopped | Detenido por señal (Ctrl+Z, SIGSTOP) o depurador. |
| `I` | Idle (kernel thread) | Hilo del kernel en espera. Ignorar para troubleshooting. |

**Banderas adicionales** (aparecen después del estado principal):

| Bandera | Significado |
|---------|------------|
| `<` | Alta prioridad (nice negativo) |
| `N` | Baja prioridad (nice positivo) |
| `s` | Líder de sesión |
| `l` | Multi-threaded |
| `+` | En foreground (grupo de procesos del terminal) |

Ejemplos:

```text
Ss   → Sleeping, líder de sesión (típico en demonios como sshd)
R+   → Running en foreground (un comando que corriste en la terminal)
D    → Bloqueado en I/O de disco (problema de rendimiento)
Z    → Zombie (el padre debe hacer wait())
```

---

## 🎛️ Opciones principales

### Mostrar todos los procesos

```bash
ps aux          # BSD: todos los usuarios, formato por defecto
ps -ef          # UNIX: todos los procesos, formato estándar
ps -e           # Solo PID y comando
```

### Filtrar por dueño

```bash
ps -u www-data                      # Por nombre de usuario
ps -U 33                            # Por UID numérico
```

### Filtrar por PID

```bash
ps -p 1234                          # Un PID
ps -p 1234,5678,9012               # Varios PID
```

### Filtrar por nombre de comando

```bash
ps -C nginx                        # Exacto: todos los procesos cuyo comm es "nginx"
ps -C sshd -o pid,user,args        # Con columnas personalizadas
```

---

## Salida personalizada (-o)

`-o` permite elegir qué columnas mostrar y en qué orden. Es la forma más potente de usar `ps`.

```bash
ps -eo pid,ppid,user,%cpu,%mem,stat,comm
```

Columnas disponibles (más útiles para SRE):

| Columna | Descripción |
|---------|------------|
| `pid` | Process ID |
| `ppid` | Parent PID |
| `user` | Usuario dueño |
| `%cpu` | Uso de CPU |
| `%mem` | Uso de memoria |
| `vsz` | Memoria virtual (KB) |
| `rss` | Memoria residente (KB) |
| `stat` | Estado del proceso |
| `comm` | Solo nombre del binario (sin argumentos) |
| `args` | Comando completo con argumentos |
| `etime` | Tiempo transcurrido desde que arrancó (formato: `[[dd-]hh:]mm:ss`) |
| `time` | Tiempo acumulado de CPU |
| `lstart` | Fecha y hora exacta de inicio |
| `nlwp` | Número de threads (light-weight processes) |
| `wchan` | Función del kernel donde está durmiendo (útil para procesos en D) |

### Ejemplo: reporte de procesos con más threads

```bash
ps -eo pid,nlwp,comm --sort=-nlwp | head -12
```

### Ejemplo: procesos en estado D con su WCHAN

```bash
ps -eo pid,stat,wchan,comm | awk '$2 ~ /^D/'
```

---

## Opciones de ordenamiento

Con la opción `--sort` se ordena por cualquier columna. El signo `-` invierte el orden.

```bash
# Top CPU
ps aux --sort=-%cpu | head -15

# Top memoria
ps aux --sort=-%mem | head -15

# Procesos más viejos (por tiempo de inicio)
ps aux --sort=start | head -15

# Más tiempo de CPU acumulado
ps aux --sort=-time | head -15

# Más threads
ps -eo pid,nlwp,comm --sort=-nlwp | head -15
```

También se puede ordenar por múltiples columnas:

```bash
ps aux --sort=-%mem,-%cpu | head -20
```

---

## Árbol de procesos

Para ver la jerarquía padre-hijo:

```bash
ps -ejH                       # Árbol con PID, PGID, SID
ps axfo pid,ppid,args         # Árbol con formato personalizado
ps auxf                       # Árbol en formato BSD (con argumentos)
```

La salida muestra la indentación. El proceso más a la izquierda es el ancestro:

```text
  PID  PPID COMMAND
    1     0 /sbin/init
  423     1   /usr/sbin/sshd
 1234   423     sshd: admin@pts/0
 1235  1234       -bash
 5678  1235         ps -ejH
```

---

## 📋 Patrones de uso

### Top CPU con columnas legibles

```bash
ps -eo pid,user,%cpu,%mem,rss,comm --sort=-%cpu | head -15
```

### Top memoria con RSS en MB

```bash
ps aux --sort=-%mem | head -10 \
  | awk '{ rss_mb=$6/1024; printf "%-8s %-6s %5.1f MB %s\n", $1, $2, rss_mb, $11 }'
```

### Procesos por usuario agrupados

```bash
ps -eo user,%cpu,%mem --no-headers \
  | awk '{ cpu[$1]+=$2; mem[$1]+=$3 } END { for (u in cpu) printf "%-10s CPU:%.1f MEM:%.1f\n", u, cpu[u], mem[u] }'
```

### Contar procesos por estado

```bash
ps -eo stat --no-headers \
  | awk '{ s[substr($1,1,1)]++ } END { for (st in s) printf "%s: %d\n", st, s[st] }' \
  | sort
```

### Encontrar el proceso padre de un PID

```bash
ps -o ppid= -p <PID>
```

### Tiempo de actividad de un proceso

```bash
ps -p <PID> -o etime,args --no-headers
```

### Procesos que más archivos tienen abiertos (combinado con lsof/`/proc`)

```bash
for pid in $(ps --no-headers -eo pid --sort=-%mem | head -10); do
  fds=$(ls /proc/$pid/fd 2>/dev/null | wc -l)
  cmd=$(ps -p $pid -o comm= 2>/dev/null)
  [ -n "$fds" ] && echo "$fds $pid $cmd"
done | sort -rn
```

---

## 🔍 Uso en troubleshooting

### CPU runaway

```bash
ps aux --sort=-%cpu | head -5
```

Si un proceso tiene > 80% de CPU sostenido:

```bash
# Ver qué está haciendo
strace -p <PID> -c -f 2>&1 | head -20

# O simplemente matarlo con señal suave primero
kill -15 <PID>
```

### Memory leak

```bash
# Ejecutar cada 5 segundos y comparar %MEM
watch -n 5 'ps -p <PID> -o %mem,args --no-headers'
```

Si %MEM sube constantemente sin bajar → memory leak confirmado.

### Procesos zombie

```bash
ps axo stat,ppid,pid,comm | awk '$1 ~ /^Z/'
```

Los procesos zombie no se matan directamente. Matar al PPID (padre) o reiniciar el servicio padre.

### Procesos en estado D (bloqueados en I/O)

```bash
ps -eo pid,stat,wchan,comm | awk '$2 ~ /^D/'
```

Estado D + alta cantidad = cuello de botella de disco. Investigar con `iostat`, `iotop`.

### Procesos con más de N threads

```bash
ps -eo pid,nlwp,comm --sort=-nlwp | awk '$2 > 50' | head -10
```

Muchos threads puede indicar una aplicación mal configurada o un ataque de conexiones.

---

## 🛠️ Combinación con otras herramientas

### ps + awk: top memoria por usuario

```bash
ps aux | awk 'NR>1 { mem[$1]+=$4; cpu[$1]+=$3 }
  END { for (u in mem) printf "%-10s CPU:%.1f MEM:%.1f\n", u, cpu[u], mem[u] }' \
  | sort -k2 -rn
```

### ps + grep: procesos de un servicio

```bash
ps aux | grep nginx
```

### ps + xargs: matar procesos por nombre

```bash
ps -C <nombre> -o pid= | xargs kill -15
```

### ps + sort + head: ranking de recursos

```bash
ps aux --sort=-%cpu | head -10
ps aux --sort=-%mem | head -10
ps aux --sort=-rss | head -10
```

### ps + pstree: árbol visual

```bash
pstree -p <PID>
```

---

## 💡 Uno-liners imprescindibles

```bash
# Top 10 CPU
ps aux --sort=-%cpu | head -11

# Top 10 memoria
ps aux --sort=-%mem | head -11

# Todos los procesos de un usuario
ps -u www-data

# Zombies con su padre
ps axo stat,ppid,pid,comm | awk '$1 ~ /^Z/ { print $2, $3, $4 }'

# Procesos en estado D (I/O bloqueante)
ps -eo pid,stat,wchan,args | awk '$2 ~ /^D/'

# Procesos sin terminal (demonios)
ps -eo pid,tty,args | awk '$2 == "?"'

# Cantidad de procesos por estado
ps -eo stat | awk '{ s[substr($1,1,1)]++ } END { for (st in s) printf "%s: %d\n", st, s[st] }'

# PID del proceso que más CPU usa
ps -eo pid --sort=-%cpu --no-headers | head -1

# PID del proceso que más memoria usa
ps -eo pid --sort=-%mem --no-headers | head -1

# Árbol de procesos compacto
ps -ejH | head -20
```

---

## ⚠️ Errores comunes

- **Confundir `ps aux` con `ps -aux`**. `ps -aux` busca procesos del usuario "x" (porque `-a` es "all with tty", `-u` espera un usuario). Usar `ps aux` sin guión para BSD.
- **No filtrar `grep` del resultado**. `ps aux | grep nginx` incluye la línea del propio grep. Solución: `ps aux | grep [n]ginx`.
- **Interpretar %CPU literalmente**. 100% en un proceso = 1 core saturado. Si el servidor tiene 4 cores, el máximo real es 400%.
- **Matar un zombie directamente**. No funciona. El zombie ya terminó. Hay que arreglar al padre.
- **Usar `kill -9` como primera opción**. `-9` (SIGKILL) no da chance al proceso de cerrar archivos o conexiones. Preferir `-15` (SIGTERM) primero.
- **`ps -p` sin PID**. No muestra nada. El PID debe existir.
- **Confundir RSS con VSZ**. VSZ incluye memoria compartida y mapeos. RSS es la memoria física real que el proceso ocupa.

---

## ✅ Buenas prácticas

- Para diagnóstico rápido, `ps aux --sort=-%cpu | head` es suficiente.
- Para scripts, usar `ps -eo` con columnas explícitas (portable y predecible).
- No asumir que `ps` de busybox tiene las mismas opciones que procps-ng. En Alpine:

  ```bash
  # Alternativas portable entre procps y busybox:
  ps aux                    # Funciona en ambos
  ps -eo pid,ppid,args      # Funciona en ambos
  ps aux --sort=-%cpu       # Solo procps (Debian/Ubuntu)
  ps aux | sort -k3 -rn     # Alternativa POSIX portable
  ```

- Al construir pipelines, usar `--no-headers` en `ps -eo` para no mezclar header con datos.
- Documentar qué columnas específicas se necesitan y por qué. No volcar `ps aux` completo sin filtro.
- En incidentes, primero `ps aux | head` para orientarse, después afinar con `-o`.
- Combinar `ps` con `watch` para monitorear cambios: `watch -n 2 'ps -eo pid,stat,%cpu,%mem,comm --sort=-%cpu | head -10'`.

---

## 🔗 Referencias internas

- [`top`](../top.md) — panel en vivo de procesos (complemento de `ps`)
- [`grep`](../grep.md) — filtrar por nombre o patrón
- [`awk`](../awk.md) — extraer y procesar columnas
- [`sort`](../sort.md) — ordenar por campo
- [`kill`](../kill.md) — enviar señales a procesos
- [`systemd_journalctl`](../systemd_journalctl.md) — logs de servicios
