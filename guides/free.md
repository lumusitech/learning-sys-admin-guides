# free — Guía completa

**Nivel:** 🟢 Básico
**Archivos de práctica:** Sistema en vivo
**Ver escenarios relacionados:** [`system/05-memory-issues-oom`](../scenarios/system/05-system-memory-issues-oom.md), [`system/01-top-processes`](../scenarios/system/01-top-processes-and-resources.md)

---

## ⚡ Quick command

`free -h`

---

## ⚡ Quick run

```bash
free -h && free -m | awk '/^Mem:/ { printf "Usada: %.0f%%\n", $3/$2*100 }'
```

---

## 📑 Índice

1. [¿Qué es free?](#qué-es-free)
2. [Sintaxis básica](#sintaxis-básica)
3. [Salida clave](#salida-clave)
4. [Opciones principales](#opciones-principales)
5. [Interpretación avanzada](#interpretación-avanzada)
6. [Patrones de uso](#patrones-de-uso)
7. [Uso en troubleshooting](#uso-en-troubleshooting)
8. [Combinación con otras herramientas](#combinación-con-otras-herramientas)
9. [Uno-liners imprescindibles](#uno-liners-imprescindibles)
10. [Errores comunes](#errores-comunes)
11. [Buenas prácticas](#buenas-prácticas)

---

## 🧠 ¿Qué es free?

**free** muestra el uso de memoria física (RAM) y swap del sistema, incluyendo buffers y caché. Es la primera herramienta para diagnosticar presión de memoria.

A diferencia del administrador de tareas de escritorio, `free` muestra:

- **Memoria usada**: incluye buffers y caché en versiones modernas.
- **Memoria disponible**: lo que realmente puede asignar una aplicación nueva.
- **Swap usado**: si el sistema está usando disco como RAM (señal de alerta).

---

## 🧠 Modelo mental

La memoria en Linux se divide en tres zonas:

1. **Usada por procesos**: lo que necesita el sistema para funcionar.
2. **Caché y buffers**: el kernel usa memoria libre para cachear discos. **No es "memoria ocupada", es memoria útil lista para liberarse**.
3. **Libre**: completamente sin usar.

La columna que importa es `available`, no `used` ni `free`. `available` estima cuánta memoria podría asignar una aplicación nueva sin recurrir a swap.

---

## 📝 Sintaxis básica

```bash
free [opciones]
```

```bash
free               # En kilobytes
free -h            # Formato humano (KB, MB, GB)
free -m            # En megabytes
free -w            # Ancho para evitar truncar columnas
free -s 2          # Actualizar cada 2 segundos (como watch)
free -t            # Mostrar totales
```

---

## 🔑 Salida clave

```text
               total        used        free      shared  buff/cache   available
Mem:           15933        5218        3108         456        7606       10025
Swap:           2047           1        2046
```

| Columna | Significado |
|---------|-------------|
| `total` | Memoria física total instalada |
| `used` | Memoria en uso por procesos + caché (en Linux moderno) |
| `free` | Memoria completamente sin usar |
| `shared` | Memoria compartida entre procesos (tmpfs) |
| `buff/cache` | Buffers del kernel + caché de página |
| `available` | **Estimación de memoria disponible para nuevas aplicaciones** |

### Regla de interpretación

La columna que importa al diagnosticar es `available`:

- `available` > 20% de `total` → memoria normal.
- `available` < 10% de `total` → presión de memoria. Investigar.
- `available` cercano a 0 + swap creciendo → riesgo de OOM killer.

No confiar en `free` sola: que "free" sea 0 es normal porque Linux usa la memoria libre como caché. Mirar `available`.

### Swap

- Swap usado > 0 + disponible bajo → sistema bajo presión real.
- Swap usado > 0 + disponible normal → algún proceso accedió swap puntualmente. No es grave.
- Swap usado creciendo rápido → pedir más RAM o matar procesos.

---

## 🎛️ Opciones principales

| Opción | Efecto |
|--------|--------|
| `-h` | Formato humano (recomendado siempre) |
| `-m` | En megabytes (útil para scripts) |
| `-w` | Ancho de columna completo (evita truncar) |
| `-s <N>` | Actualizar cada N segundos (modo watch) |
| `-t` | Mostrar línea de totales |
| `--si` | Usar base 1000 en vez de 1024 |

---

## Interpretación avanzada

### Memoria caché no es "ocupada"

```bash
# Memoria realmente usada por procesos (sin caché)
free -m | awk '/^Mem:/ { printf "Real usada: %d MB (de %d total)\n", $3 - $6 - $7, $2 }'
```

### Porcentaje de uso real

```bash
free -m | awk '/^Mem:/ { printf "Usada: %.1f%%\n", ($3-$6-$7)/$2*100 }'
free -m | awk '/^Mem:/ { printf "Disponible: %.1f%%\n", $7/$2*100 }'
```

### Presión de swap

```bash
free -m | awk '/^Swap:/ { if ($3 > 0) print "⚠️ Swap en uso:", $3, "MB"; else print "✅ Swap limpio" }'
```

---

## 📋 Patrones de uso

### Vista rápida cada 2 segundos (mejor que `watch free`)

```bash
free -h -s 2 -t
```

### Totales de RAM + swap combinados

```bash
free -h -t
```

### Memoria por proceso (complemento)

```bash
ps aux --sort=-%mem | head -5
```

---

## 🔍 Uso en troubleshooting

### ¿Hay suficiente memoria?

```bash
free -h | awk '/^Mem:/ { print $7 }'       # available en humano
free -m | awk '/^Mem:/ { print $7/$2*100 }' # porcentaje disponible
```

### ¿El OOM killer puede actuar?

```bash
# Si available < 5% de total + swap usado > 0 → riesgo alto
free -m | awk '/^Mem:/ { av=$7; t=$2 } /^Swap:/ { sw=$3 }
  END { pct=av/t*100; if (pct<5 && sw>0) print "⚠️ Alto riesgo OOM"; else print "✅ Normal" }'
```

### Liberar caché (no mata procesos, solo cache del kernel)

```bash
sync && echo 3 | sudo tee /proc/sys/vm/drop_caches
```

Verificar después: `free -h`.

---

## 🛠️ Combinación con otras herramientas

### free + ps: memoria total usada por procesos

```bash
ps aux --sort=-%mem | head -10
free -h
```

Comparar la suma de RSS de `ps` con `used` de `free`. Si la suma de RSS es mucho menor que `used`, hay pérdida en caché o memory leak en algún proceso.

### free + vmstat: contexto completo

```bash
free -h && vmstat 1 3
```

`free` muestra el estado actual; `vmstat` muestra la tendencia de swapping y I/O.

---

## 💡 Uno-liners imprescindibles

```bash
free -h                                    # Resumen rápido
free -h -s 2 -t                            # Monitoreo en vivo
free -m | awk '/^Mem:/ { print $7 }'       # MB disponibles
free -m | awk '/^Swap:/ { print $3 }'      # MB de swap usados
free -m | awk '/^Mem:/ { printf "%.0f%%\n", ($3-$6-$7)/$2*100 }'  # % uso real
```

---

## ⚠️ Errores comunes

- **Leer `free` en vez de `available`**. `free` puede ser 0 y el sistema funcionar perfectamente. Linux usa la memoria libre como caché.
- **Preocuparse porque `buff/cache` es alto**. Es normal. El kernel cachea todo lo que no se usa para acelerar accesos a disco. Si una app necesita memoria, el kernel libera caché automáticamente.
- **Comparar `used` con la suma de RSS de `ps`**. `used` incluye caché. No va a coincidir. Usar `($3 - $6 - $7)` de `free -m` para obtener la memoria real de procesos.
- **Ejecutar `drop_caches` como práctica habitual**. Solo hacerlo bajo diagnóstico. Forzar la limpieza de caché degrada el rendimiento de disco temporalmente.

---

## ✅ Buenas prácticas

- Siempre usar `free -h` para humanos, `free -m` para scripts.
- No alarmarse porque `free` es bajo. La columna correcta es `available`.
- Monitorear `available` + swap juntos. Swap por sí solo no es malo; swap + available bajo es la alarma real.
- Combinar con `vmstat 1 5` para ver si swap crece en tiempo real.
- En contenedores Docker, `free` muestra la memoria del host, no la del contenedor. Usar `cat /sys/fs/cgroup/memory/memory.usage_in_bytes` dentro del contenedor para ver el límite real.

---

## 🔗 Referencias internas

- [`vmstat`](vmstat.md) — contexto completo de memoria, swap y CPU
- [`ps`](ps.md) — memoria por proceso (RSS)
- [`top`](top.md) — panel de memoria en vivo
- [`systemd_journalctl`](systemd_journalctl.md) — logs de OOM killer
