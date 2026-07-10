# iostat — Guía completa

**Nivel:** 🟡 Intermedio
**Archivos de práctica:** Sistema en vivo
**Ver escenarios relacionados:** [`system/07-high-io-wait`](../scenarios/system/07-high-io-wait.md)

---

## ⚡ Quick command

`iostat -x 1 3`

---

## ⚡ Quick run

```bash
iostat -x 1 3
```

---

## 📑 Índice

1. [¿Qué es iostat?](#qué-es-iostat)
2. [Sintaxis básica](#sintaxis-básica)
3. [Salida clave](#salida-clave)
4. [Campos extendidos (-x)](#campos-extendidos--x)
5. [Interpretación de métricas](#interpretación-de-métricas)
6. [Discos y dispositivos](#discos-y-dispositivos)
7. [Patrones de uso](#patrones-de-uso)
8. [Uso en troubleshooting](#uso-en-troubleshooting)
9. [Combinación con otras herramientas](#combinación-con-otras-herramientas)
10. [Uno-liners imprescindibles](#uno-liners-imprescindibles)
11. [Errores comunes](#errores-comunes)
12. [Buenas prácticas](#buenas-prácticas)

---

## 🧠 ¿Qué es iostat?

**iostat** (input/output statistics) reporta estadísticas de CPU y de entrada/salida por dispositivo de disco o partición. Es la herramienta estándar para diagnosticar cuellos de botella de I/O.

Se usa para:

- identificar si el disco es el cuello de botella de rendimiento;
- detectar discos saturados antes de que degraden servicios;
- calcular latencia de I/O y tamaño de operaciones promedio.

---

## 🧠 Modelo mental

El disco es el componente más lento del servidor (CPU, RAM, disco, en ese orden). Cuando un proceso necesita leer o escribir, el CPU espera. Si el disco está saturado, todo el servidor se frena.

`iostat -x` muestra tres métricas clave:

- **`%util`**: el porcentaje de tiempo que el disco estuvo ocupado sirviendo I/O.
- **`await`**: la latencia promedio de cada operación de I/O (ms).
- **`svctm`**: el tiempo de servicio real del hardware (sin cola).

Un disco con `%util > 80%` + `await > 20ms` está saturado.

---

## 📝 Sintaxis básica

```bash
iostat [opciones] [intervalo] [cantidad]
```

```bash
iostat              # CPU + disco básico
iostat -x           # Columnas extendidas
iostat -x 1 5       # Cada 1 segundo, 5 muestras
iostat -d 1         # Solo disco, sin CPU
iostat -p sda       # Solo dispositivo específico
iostat -xh          # Formato humano (Linux moderno)
```

---

## 🔑 Salida clave

### Vista básica

```text
Device            tps    kB_read/s    kB_wrtn/s    kB_read    kB_wrtn
sda              45.2       120.5        340.2   12345678    34567890
sdb              12.3        45.6        78.9    4567890     1234567
```

| Campo | Significado |
|-------|-------------|
| `tps` | Transferencias por segundo (I/O operations per second) |
| `kB_read/s` | KB leídos por segundo |
| `kB_wrtn/s` | KB escritos por segundo |
| `kB_read` | KB totales leídos (acumulado) |
| `kB_wrtn` | KB totales escritos (acumulado) |

---

## Campos extendidos (-x)

```text
Device  rrqm/s  wrqm/s  r/s   w/s   rkB/s   wkB/s  avgrq-sz avgqu-sz  await  r_await  w_await  svctm  %util
sda     0.12    1.34    23.4  45.2  120.5   340.2  12.3     0.45      5.2    3.1      6.8      2.1    15.2
sdb     0.01    0.23    1.2   3.4   45.6    78.9   22.1     1.20      45.3   12.4     68.2     5.8    68.5
```

| Campo | Significado | Interpretación |
|-------|-------------|----------------|
| `rrqm/s` | Lecturas adyacentes agrupadas por segundo | Si es bajo, las apps leen de forma fragmentada |
| `wrqm/s` | Escrituras agrupadas | Alto es bueno: el kernel está eficientemente agrupando escrituras |
| `r/s` | Lecturas completas por segundo | IOPS de lectura |
| `w/s` | Escrituras completas por segundo | IOPS de escritura |
| `rkB/s` | KB leídos por segundo | Throughput de lectura |
| `wkB/s` | KB escritos por segundo | Throughput de escritura |
| `avgrq-sz` | Tamaño promedio de I/O (sectores) | Operaciones grandes = secuenciales; pequeñas = aleatorias |
| `avgqu-sz` | Longitud promedio de la cola de I/O | > 1 indica I/O en espera. Más alto = más saturado. |
| `await` | Tiempo promedio de respuesta (ms) | Incluye tiempo en cola. **La métrica que importa.** |
| `r_await` | Tiempo de respuesta de lecturas (ms) | Las lecturas son síncronas, así que este es el tiempo que un proceso espera |
| `w_await` | Tiempo de respuesta de escrituras (ms) | Las escrituras pueden ser asíncronas (pasan al cache del disco) |
| `svctm` | Tiempo de servicio real (ms) | Lo que tarda físicamente el disco. No incluye cola. |
| `%util` | Porcentaje de tiempo que el disco estuvo ocupado | **> 80% → saturado. > 60% → monitorear.** |

---

## Interpretación de métricas

### ¿Cuándo el disco es el problema?

| Síntoma | Causa |
|---------|-------|
| `%util > 80%` + `await > 20ms` | Disco saturado (HDD) |
| `%util > 80%` + `await > 2ms` | Disco saturado (SSD) |
| `await` alto + `svctm` bajo | Alta contención. Muchos procesos compitiendo por el disco. |
| `await` alto + `svctm` alto | Disco lento (hardware) o caché del disco corrupta. |
| `avgqu-sz > 1` | I/O en cola. El disco no da abasto. |
| `r_await` mucho mayor que `w_await` | Escrituras son asíncronas, lecturas son síncronas. Normal. |

### Discos saludables

| Tipo | %util máximo | await esperado |
|------|-------------|----------------|
| SSD NVMe | < 90% | < 2 ms |
| SSD SATA | < 80% | < 5 ms |
| HDD 7200rpm | < 60% | < 15 ms |
| HDD 5400rpm | < 40% | < 25 ms |
| NAS/NFS | < 30% | varía según red |

---

## Discos y dispositivos

### Monitorear un disco específico

```bash
iostat -x -p sda 1 3
```

### Todos los discos

```bash
iostat -x 1 3            # CPU + todos los discos
iostat -dx 1 3           # Solo discos (sin CPU)
```

### Sin monturas virtuales (solo discos físicos)

```bash
iostat -x 1 3 | grep -E '^(Device|sd|nvme|vd|dm-)'
```

---

## 📋 Patrones de uso

### Diagnóstico rápido de I/O

```bash
iostat -x 1 3 | tail -10
```

Buscar:

- `%util > 80%` en algún disco → saturado.
- `await > 20ms` en HDD o `> 2ms` en SSD → latencia alta.
- `avgqu-sz > 1` → I/O en cola.

### Comparar discos

```bash
iostat -x 1 1 | awk 'NR>2 && /^sd/ { print $1, "%util:", $NF, "await:", $10 }'
```

### Tamaño de operación promedio

```bash
iostat -x 1 1 | awk '/^sd/ { print $1, "avg I/O size:", $8*512/1024, "KB" }'
```

---

## 🔍 Uso en troubleshooting

### El servidor está lento. ¿Es el disco?

```bash
vmstat 1 3           # ¿wa > 10%?
iostat -x 1 3        # ¿%util > 80% en algún disco?
```

Si ambas responden sí → el disco es el cuello de botella.

### Una app específica va lenta

```bash
# 1. Ver si el disco está saturado
iostat -x 1 5

# 2. Ver qué proceso está I/O intensivo
iotop -o                # o si no está disponible:
pidstat -d 1 5          # I/O por proceso
```

### Detectar swapping por I/O alta

```bash
vmstat 1 3 | awk 'NR>2 { print "wa:", $16, "so:", $8 }'
# Si wa alto + so alto → swapping está causando I/O en disco
```

---

## 🛠️ Combinación con otras herramientas

### iostat + vmstat: diagnóstico completo

```bash
vmstat 1 5         # CPU, memoria, swap, I/O
iostat -x 1 5      # Disco detallado
```

### iostat + pidstat: I/O por proceso

```bash
iostat -x 1 3            # Disco saturado
pidstat -d 1 3           # Qué proceso genera la I/O
```

### iostat + grep: alerta en vivo

```bash
iostat -x 1 | awk '/sd/ && $NF > 80 { print strftime("%H:%M:%S"), $1, "%util:", $NF }'
```

---

## 💡 Uno-liners imprescindibles

```bash
iostat -x 1 3                         # Diagnóstico de 5 segundos
iostat -dx 1 3                        # Solo discos (sin CPU)
iostat -x 1 3 | awk '/sd/ && $NF > 80 { print $1, "saturado:", $NF "%" }'  # Alertas
iostat -x -p sda 1                    # Monitoreo continuo de un disco
iostat -x 1 1 | awk '/^sd/ { print $1, "await:", $10 }'   # Latencia por disco
iostat -m 1 1                         # En MB/s
iostat -x 1 | awk '/sd/ { print $1, "tps:", $2 }'         # Solo IOPS
```

---

## ⚠️ Errores comunes

- **Leer `%util` como "usado"**. `%util` no es capacidad usada del disco, es el porcentaje del tiempo que el disco estuvo ocupado sirviendo solicitudes. Puede ser 100% con poca transferencia si las operaciones son pequeñas y aleatorias.
- **Alarmarse con `await` alto en escrituras**. Las escrituras suelen ser asíncronas. Las lecturas (síncronas) son las que importan. Mirar `r_await`.
- **Comparar métricas entre discos de distinto tipo**. Un NVMe con `await: 5ms` está mal. Un HDD NAS con `await: 5ms` está excelente.
- **Ignorar el cache del disco**. `await` mide el tiempo de respuesta **visto por el sistema operativo**. Si el disco tiene cache, las escrituras pueden ser reportadas como rápidas aunque el disco físico tarde más.
- **No instalar `sysstat`**. `iostat` viene en el paquete `sysstat` (Debian) o `sysstat` (Alpine). No está instalado por defecto en todos los sistemas mínimos.

---

## ✅ Buenas prácticas

- Siempre usar `-x` para columnas extendidas. La salida básica no es suficiente.
- El primer reporte de `iostat` es desde el arranque. El segundo y siguientes son los relevantes.
- Para establecer una baseline de rendimiento, guardar `iostat -x 1 1` en un servidor saludable.
- En servidores con SSD, `await > 2ms` es una señal de alerta. En HDD, `await > 20ms`.
- Combinar `iostat` con `pidstat -d` para identificar el proceso responsable de la I/O.

---

## 🔗 Referencias internas

- [`vmstat`](vmstat.md) — contexto de CPU, memoria y swap
- [`ps`](ps.md) — procesos que consumen recursos
- [`top`](top.md) — vista en vivo de procesos y recursos
- [`production_server`](production_server.md) — monitoreo básico del servidor
