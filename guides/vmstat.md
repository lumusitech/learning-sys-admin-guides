# vmstat — Guía completa

**Nivel:** 🟡 Intermedio
**Archivos de práctica:** Sistema en vivo
**Ver escenarios relacionados:** [`system/07-high-io-wait`](../scenarios/system/07-high-io-wait.md), [`system/05-memory-issues-oom`](../scenarios/system/05-system-memory-issues-oom.md)

---

## ⚡ Quick command

`vmstat 1 5`

---

## ⚡ Quick run

```bash
vmstat 1 3
```

---

## 📑 Índice

1. [¿Qué es vmstat?](#qué-es-vmstat)
2. [Sintaxis básica](#sintaxis-básica)
3. [Salida clave](#salida-clave)
4. [Campos de memoria y swap](#campos-de-memoria-y-swap)
5. [Campos de I/O](#campos-de-io)
6. [Campos de CPU](#campos-de-cpu)
7. [vmstat con disk stats (-d)](#vmstat-con-disk-stats--d)
8. [Patrones de uso](#patrones-de-uso)
9. [Uso en troubleshooting](#uso-en-troubleshooting)
10. [Combinación con otras herramientas](#combinación-con-otras-herramientas)
11. [Uno-liners imprescindibles](#uno-liners-imprescindibles)
12. [Errores comunes](#errores-comunes)
13. [Buenas prácticas](#buenas-prácticas)

---

## 🧠 ¿Qué es vmstat?

**vmstat** (virtual memory statistics) reporta información sobre procesos, memoria, swap, I/O y CPU en una sola vista. Es la navaja suiza del diagnóstico de rendimiento del sistema.

A diferencia de herramientas específicas (`free`, `iostat`, `top`), `vmstat` da un **pantallazo de todas las áreas a la vez**, lo que permite correlacionar síntomas.

---

## 🧠 Modelo mental

`vmstat` divide la salida en seis áreas: procesos, memoria, swap, I/O, sistema y CPU. Cada columna es un contador o métrica. La **fila 1** es el promedio desde el arranque; las filas siguientes son diferencias por intervalo.

Cuando hay un problema de rendimiento, `vmstat` te dice:

- si el cuello de botella es **CPU** (columna `us` + `sy` altos, `id` bajo);
- si es **disco** (columna `wa` alta, `b` alto);
- si es **memoria** (`swap` en aumento, `cache` cayendo);
- si es **procesos** (`r` mucho mayor que la cantidad de núcleos).

---

## 📝 Sintaxis básica

```bash
vmstat [intervalo] [cantidad]
```

```bash
vmstat 1 5        # Cada 1 segundo, 5 muestras
vmstat 1          # Cada 1 segundo, infinito (Ctrl+C para salir)
vmstat -s         # Estadísticas acumuladas desde el arranque
vmstat -d         # Estadísticas por dispositivo de disco
vmstat -m         # Estadísticas de slabs (memoria del kernel)
```

---

## 🔑 Salida clave

```text
procs  ----------memory----------  ---swap--  -----io----  -system--  ------cpu-----
 r  b   swpd   free   buff  cache    si   so   bi    bo    in    cs  us  sy  id  wa  st
 2  0      0  32140  45680 1052340    0    0    0     5    23    18   5   2  93   0   0
 3  1      0  32120  45680 1052340    0    0   45    12  3420  5012  12   8  72   8   0
```

---

## Campos explicados

### Procesos

| Campo | Significado | Interpretación |
|-------|-------------|----------------|
| `r` | Procesos en cola de ejecución (en CPU o esperando) | Si `r` > cantidad de núcleos sostenido → CPU saturada |
| `b` | Procesos bloqueados en I/O | Si `b` > 0 sostenido → cuello de botella de disco |

### Memoria

| Campo | Significado | Interpretación |
|-------|-------------|----------------|
| `swpd` | Swap usado (KB) | Si crece en cada muestra → presión de memoria |
| `free` | Memoria libre (KB) | Sin caché. Puede ser 0 sin ser problema. |
| `buff` | Buffers del kernel (KB) | Para operaciones de bloque (discos). |
| `cache` | Caché de página (KB) | Archivos cacheados. El kernel libera caché cuando necesita memoria. |

### Swap

| Campo | Significado | Interpretación |
|-------|-------------|----------------|
| `si` | Swap in (KB/s) | Memoria traída de vuelta desde swap. Si > 0, hay actividad de swapping. |
| `so` | Swap out (KB/s) | Memoria movida a swap. **Si `so` > 0 sostenido, hay presión de RAM.** |

### I/O

| Campo | Significado |
|-------|-------------|
| `bi` | Bloques recibidos desde disco (blocks/s) |
| `bo` | Bloques enviados a disco (blocks/s) |

Normalmente un bloque = 1024 bytes. `bi=450` ≈ 450 KB/s de lectura.

### Sistema

| Campo | Significado |
|-------|-------------|
| `in` | Interrupciones por segundo (incluye reloj) |
| `cs` | Context switches por segundo |

`cs` alto puede indicar muchos procesos compitiendo por CPU o un sistema mal configurado.

### CPU

| Campo | Significado |
|-------|-------------|
| `us` | Tiempo de CPU en espacio de usuario (aplicaciones) |
| `sy` | Tiempo de CPU en kernel (llamadas al sistema) |
| `id` | Tiempo ocioso (idle) |
| `wa` | Tiempo esperando I/O (disk wait) |
| `st` | Tiempo robado por el hipervisor (máquinas virtuales) |

---

## vmstat con disk stats (-d)

```bash
vmstat -d | head -20
```

```text
disk- ------------reads------------  ------------writes------------  -----IO------
       total  merged  sectors    ms    total  merged  sectors    ms    cur    sec
sda    45678     234  2349288  46791     341     23   234332   2123     0   3.2
sdb    230474     12  3450292 120934   23401    349   238845  20341     1  15.7
```

| Campo | Significado |
|-------|-------------|
| `total` | Cantidad total de I/O |
| `merged` | I/O adyacentes agrupados por el kernel |
| `sectors` | Sectores transferidos (1 sector = 512 bytes) |
| `ms` | Milisegundos totales de I/O |
| `cur` | I/O en curso actualmente |
| `sec` | Segundos por I/O (promedio) |

---

## 📋 Patrones de uso

### Diagnóstico rápido de rendimiento

```bash
vmstat 1 3
```

- `r > nproc` → saturación de CPU.
- `wa > 10%` → disco lento o saturado.
- `so > 0` → presión de swap.
- `b > 1` → procesos bloqueados esperando I/O.

### Comparar con nproc

```bash
echo "Núcleos: $(nproc)"
vmstat 1 1 | tail -1 | awk '{ print "Cola de procesos:", $1 }'
```

### Swap trending (cada 2 segundos)

```bash
vmstat 2 10 | grep -v '^procs' | awk '{ print strftime("%H:%M:%S"), "si:", $7, "so:", $8 }'
```

---

## 🔍 Uso en troubleshooting

### ¿CPU o disco?

```bash
vmstat 1 5
```

- Si `us + sy` altos y `wa` bajo → cuello de botella en CPU o aplicación.
- Si `wa` alto (> 10-20%) → cuello de botella de disco.
- Si `r` alto ( > núcleos) + `wa` alto → ambos.

### ¿Hay presión de memoria?

```bash
vmstat 1 5 | tail -4
```

- `so` > 0 sostenido → sistema está moviendo páginas a swap. Se está quedando sin RAM.
- `si` > 0 → está trayendo páginas de vuelta (más presión).
- El combo `so > 0` + `wa > 10` + `b > 0` indica un servidor al límite.

### ¿Procesos bloqueados?

```bash
# b > 0 sostenido significa procesos esperando I/O
vmstat 1 3 | awk 'NR>2 { if ($2 > 0) print "⚠️ Procesos bloqueados en I/O:", $2 }'
```

---

## 🛠️ Combinación con otras herramientas

### vmstat + free: memoria completa

```bash
free -h && vmstat -s | head -10
```

`free` muestra el snapshot, `vmstat -s` muestra acumulados del kernel.

### vmstat + ps: procesos que consumen

```bash
vmstat 1 3
# Si r es alto, preguntar:
ps aux --sort=-%cpu | head -10
```

### vmstat + iostat: I/O profundo

```bash
vmstat 1 3            # Vista global de I/O (wa, b)
iostat -x 1 3         # Vista por disco
```

---

## 💡 Uno-liners imprescindibles

```bash
vmstat 1 5                        # Diagnóstico de 5 segundos
vmstat -s | head -15              # Estadísticas acumuladas
vmstat -d | sort -k5 -rn | head -5  # Discos por tiempo de lectura
vmstat 1 3 | tail -1              # Última muestra
vmstat 1 | awk '$13 > 10'         # Solo si wa > 10%
vmstat -Sm 1 3                    # En megabytes (Linux moderno)
```

---

## ⚠️ Errores comunes

- **Ignorar la primera línea**. La fila 1 de `vmstat` es el promedio desde el arranque. Las filas siguientes son las relevantes.
- **Leer `free` como indicador de memoria disponible**. Linux usa memoria libre como caché. `vmstat` no muestra `available` (eso es de `free -h`). Mirar `si/so` para detectar presión real.
- **No correlacionar columnas**. `wa` alto puede ser por disco lento O por falta de memoria causando swapping que fuerza escritura a disco.
- **Comparar `r` con la cantidad de procesos en ejecución**. `r` no es "procesos ejecutándose", es "procesos en cola de CPU". Si hay 4 núcleos y `r=3`, la CPU no es el cuello de botella.

---

## ✅ Buenas prácticas

- Siempre tomar al menos 3 muestras: `vmstat 1 3`. La primera es promedio histórico.
- Para monitoreo continuo, usar `vmstat 5` (cada 5 segundos).
- Correlacionar `r` con `nproc`. Si `r > nproc * 2`, hay saturación de CPU.
- Combinar `vmstat` con `iostat` y `free` para un diagnóstico completo.
- `wa` > 5% repetido en varias muestras → investigar disco.
- `so` > 0 + `wa` > 5 → posible swapping excesivo, revisar RAM.

---

## 🔗 Referencias internas

- [`iostat`](iostat.md) — estadísticas detalladas por disco
- [`free`](free.md) — memoria disponible (columna `available`)
- [`ps`](ps.md) — procesos que consumen recursos
- [`top`](top.md) — vista en vivo de procesos y recursos
