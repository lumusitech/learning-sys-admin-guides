# dmesg — Guía completa

**Nivel:** 🟢 Básico
**Archivos de práctica:** Sistema en vivo
**Ver escenarios relacionados:** [`system/05-system-memory-issues-oom.md`](../scenarios/system/05-system-memory-issues-oom.md), [`system/07-high-io-wait.md`](../scenarios/system/07-high-io-wait.md), [`system/09-fork-bomb.md`](../scenarios/system/09-fork-bomb.md), [`infrastructure/06-raid-degradation.md`](../scenarios/infrastructure/06-raid-degradation.md)

---

## ⚡ Quick command

`dmesg | tail -30`

> ⚠️ En sistemas con `systemd`, `dmesg` muestra el buffer del kernel actual. En Alpine/BusyBox funciona igual. Para logs históricos usar `journalctl -k`.

---

## ⚡ Quick run

```bash
dmesg --level=err,warn | tail -20
```

---

## 📑 Índice

1. [¿Qué es dmesg?](#qué-es-dmesg)
2. [Modelo mental](#modelo-mental)
3. [Sintaxis básica](#sintaxis-básica)
4. [Salida clave](#salida-clave)
5. [Opciones principales](#opciones-principales)
6. [Patrones de uso](#patrones-de-uso)
7. [Uso en troubleshooting](#uso-en-troubleshooting)
8. [Combinación con otras herramientas](#combinación-con-otras-herramientas)
9. [Uno-liners imprescindibles](#uno-liners-imprescindibles)
10. [Errores comunes](#errores-comunes)
11. [Buenas prácticas](#buenas-prácticas)

---

## 🧠 ¿Qué es dmesg?

`dmesg` (display message) muestra los mensajes del buffer del kernel. El kernel registra eventos de hardware, errores de dispositivo, cambios de red, eventos de memoria y mensajes de arranque.

- qué hace: muestra mensajes del kernel en tiempo real o desde el buffer
- para qué sirve: diagnosticar errores de hardware, problemas de disco, fallos de memoria, errores de red
- cuándo usarlo: cuando el sistema se comporta de forma extraña y los logs de usuarios no muestran nada
- cuándo NO usarlo: para ver logs de servicios de usuario (usar `journalctl` o `tail`)

---

## 🧠 Modelo mental

`dmesg` es el "diario interno" del kernel. Cuando algo falla a nivel de hardware o driver, el kernel lo registra aquí antes de que cualquier servicio de usuario se entere.

Piensalo así:

- `journalctl` → logs de servicios y aplicaciones
- `dmesg` → logs del kernel y hardware
- `/var/log/syslog` → combinación de ambos (dependiendo de la configuración)

Si un disco falla, `dmesg` lo sabe antes que nadie. Si la memoria se agota, `dmesg` registra al OOM killer. Si un USB se conecta, `dmesg` lo registra.

---

## 📝 Sintaxis básica

```bash
dmesg [opciones]
```

Sin opciones muestra todos los mensajes del buffer del kernel.

---

## 🔑 Salida clave

Cada línea de `dmesg` tiene este formato:

```text
[timestamp] facility: message
```

Campos importantes:

| Campo | Ejemplo | Significado |
|-------|---------|-------------|
| `[timestamp]` | `[42341.123]` | Segundos desde el arranque del kernel |
| `facility` | `kernel`, `usb`, `ata`, `ext4` | Subsistema que generó el mensaje |
| `level` | `emerg`, `alert`, `crit`, `err`, `warn`, `notice`, `info`, `debug` | Severidad del mensaje |
| `message` | `Out of memory: Kill process 1234` | Descripción del evento |

Niveles de severidad:

| Nivel | Significado | Ejemplo |
|-------|-------------|---------|
| `emerg` | El sistema es inutilizable | Kernel panic |
| `alert` | Se requiere acción inmediata | Hardware fallando |
| `crit` | Condición crítica | Error de disco grave |
| `err` | Error | Dispositivo no encontrado |
| `warn` | Advertencia | Sector defectuoso remapeado |
| `notice` | Normal pero significativo | Nuevo dispositivo conectado |
| `info` | Informativo | Disco detectado en arranque |
| `debug` | Depuración | Detalles internos del driver |

---

## 🎛️ Opciones principales

| Opción | Descripción |
|--------|-------------|
| `--level=err,warn` | Mostrar solo errores y advertencias |
| `-T` | Mostrar timestamps legibles (fecha/hora) en vez de segundos desde boot |
| `-w` | Seguir en tiempo real (como `tail -f`) |
| `-c` | Mostrar y limpiar el buffer |
| `-C` | Limpiar el buffer sin mostrar |
| `-n 1` | Establecer nivel de consola (solo mensajes de este nivel aparecen en consola) |
| `--facility=core,usb` | Filtrar por subsistema |
| `-S` | Usar syslog en vez del buffer del kernel |
| `grep -i error` | Filtrar por palabra clave (usar con pipe) |

---

## 📋 Patrones de uso

### Buscar errores de hardware

```bash
dmesg | grep -i "error\|fail\|bad"
```

### Buscar errores de disco

```bash
dmesg | grep -i "ata\|scsi\|blk\|sector\|i/o error"
```

### Buscar errores de memoria

```bash
dmesg | grep -i "oom\|out of memory\|killed process"
```

### Buscar eventos de red

```bash
dmesg | grep -i "eth\|link\|carrier\|up\|down"
```

### Buscar dispositivos USB conectados

```bash
dmesg | grep -i "usb\|new device\|connected"
```

### Ver mensajes desde el arranque

```bash
dmesg | head -50
```

---

## 🔍 Uso en troubleshooting

### Disco con errores I/O

```bash
dmesg | grep -i "i/o error\|sector\|ata.*error"
```

Si ves errores de I/O, el disco puede estar fallando.

### OOM killer activado

```bash
dmesg | grep -i "oom\|killed process\|out of memory"
```

Si ves "Out of memory: Kill process", el sistema mató un proceso por falta de memoria.

### Hardware no detectado

```bash
dmesg | grep -i "not found\|failed to\|no device"
```

Si un dispositivo no aparece, `dmesg` puede decir por qué.

### Errores de red

```bash
dmesg | grep -i "eth.*error\|link.*down\|carrier.*lost"
```

Si la red falla, `dmesg` puede mostrar si es un problema de hardware.

---

## 🛠️ Combinación con otras herramientas

### Con journalctl (logs históricos)

```bash
# dmesg muestra solo el buffer actual
# journalctl -k muestra logs históricos del kernel
journalctl -k --since "1 hour ago" | grep -i error
```

### Con tail (seguir en tiempo real)

```bash
dmesg -w | grep --line-buffered -i "error\|warn"
```

### Con awk (extraer timestamps)

```bash
dmesg -T | awk '/error/ {print $1, $2, $3, $NF}'
```

### Con grep (filtrar por nivel)

```bash
dmesg --level=err | grep -i "disk\|memory\|network"
```

---

## 💡 Uno-liners imprescindibles

```bash
# Ver solo errores y advertencias
dmesg --level=err,warn

# Ver errores con timestamps legibles
dmesg -T --level=err

# Seguir errores en tiempo real
dmesg -w --level=err

# Buscar errores de disco
dmesg | grep -iE "ata|scsi|blk|i/o error|sector"

# Buscar errores de memoria (OOM)
dmesg | grep -iE "oom|out of memory|killed process"

# Ver últimos 20 mensajes del kernel
dmesg | tail -20

# Ver mensajes de arranque
dmesg | head -50

# Limpiar el buffer (útil después de diagnosticar)
dmesg -C

# Ver errores de red
dmesg | grep -iE "eth|link|carrier|up|down|error"

# Buscar dispositivos USB recientes
dmesg | grep -i "usb" | tail -10
```

---

## ⚠️ Errores comunes

### Confundir dmesg con journalctl

`dmesg` muestra solo el buffer del kernel (limitado en tamaño). Para logs históricos usar `journalctl -k`.

### No usar -T para timestamps

Los timestamps de `dmesg` son segundos desde el arranque. Usar `-T` para ver fechas legibles.

### Buffer limitado

El buffer del kernel tiene un tamaño fijo. Si el sistema lleva mucho tiempo corriendo, los mensajes antiguos se pierden. Usar `journalctl -k` para persistencia.

### No filtrar por nivel

Sin filtro, `dmesg` muestra todo incluyendo debug. Usar `--level=err,warn` para troubleshooting.

---

## ✅ Buenas prácticas

- empezar con `dmesg --level=err,warn` para no perderse errores importantes entre el ruido
- usar `-T` para correlacionar con logs de servicios (misma zona horaria)
- usar `dmesg -w` para monitorear en tiempo real durante un incidente
- combinar con `journalctl -k` para tener contexto histórico
- limpiar el buffer con `dmesg -C` después de diagnosticar para facilitar la detección de nuevos errores

---

## 🔗 Referencias internas

- [`top`](top.md) — monitoreo de procesos y memoria
- [`vmstat`](vmstat.md) — CPU, memoria, I/O
- [`iostat`](iostat.md) — métricas de disco
- [`free`](free.md) — memoria y swap
