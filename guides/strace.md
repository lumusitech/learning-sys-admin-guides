# strace — Guía completa

**Nivel:** 🔴 Avanzado
**Archivos de práctica:** Sistema en vivo
**Ver escenarios relacionados:** [`system/04-high-cpu-runaway-process.md`](../scenarios/system/04-high-cpu-runaway-process.md), [`system/05-system-memory-issues-oom.md`](../scenarios/system/05-system-memory-issues-oom.md), [`web/03-slow-sql.md`](../scenarios/web/03-slow-sql.md), [`web/05-502-bad-gateway.md`](../scenarios/web/05-502-bad-gateway.md)

---

## ⚡ Quick command

`strace -p <PID> -c`

> ⚠️ `strace` no está instalado por defecto en Alpine/BusyBox. Instalar con `apk add strace` o `apt install strace`.

---

## ⚡ Quick run

```bash
strace -e trace=open,read,write -p $(pgrep -f nginx | head -1) -c
```

---

## 📑 Índice

1. [¿Qué es strace?](#qué-es-strace)
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

## 🧠 ¿Qué es strace?

`strace` traza las llamadas al sistema (syscalls) que un proceso realiza. Cada vez que un proceso lee un archivo, abre una conexión, reserva memoria o espera I/O, `strace` lo registra.

- qué hace: muestra las llamadas al sistema de un proceso en tiempo real
- para qué sirve: diagnosticar por qué un proceso falla, qué archivos abre, dónde se bloquea
- cuándo usarlo: cuando un proceso falla sin error claro en los logs
- cuándo NO usarlo: en producción con mucho tráfico (genera overhead significativo)

---

## 🧠 Modelo mental

`strace` es como poner un micrófono al proceso para escuchar todo lo que le pide al kernel.

Piensalo así:

- `ps` → qué procesos están corriendo
- `top` → cuántos recursos consumen
- `strace` → qué están haciendo exactamente (syscall por syscall)

Si un proceso dice "no puedo abrir el archivo", `strace` te dice qué archivo intenta abrir y por qué falla (permisos, ruta incorrecta, archivo inexistente).

---

## 📝 Sintaxis básica

```bash
strace [opciones] <comando>
strace [opciones] -p <PID>
```

Dos modos principales:

- ejecutar un comando nuevo: `strace ls -la`
- adjuntar a un proceso existente: `strace -p 1234`

---

## 🔑 Salida clave

Cada línea de `strace` tiene este formato:

```text
syscall(args...) = return_value
```

Ejemplo:

```text
open("/etc/passwd", O_RDONLY) = 3
read(3, "root:x:0:0:root:/root:/bin/bash\n"..., 4096) = 1024
close(3) = 0
write(1, "root:x:0:0:root:/root:/bin/bash\n"..., 1024) = 1024
```

Campos importantes:

| Campo | Ejemplo | Significado |
|-------|---------|-------------|
| `syscall` | `open`, `read`, `write` | La llamada al sistema |
| `args` | `"/etc/passwd"`, `O_RDONLY` | Argumentos de la llamada |
| `return` | `= 3`, `= -1 ENOENT` | Valor de retorno (fd o error) |
| `errno` | `ENOENT`, `EACCES` | Código de error si falló |

Errores comunes:

| Error | Significado |
|-------|-------------|
| `ENOENT` | No such file or directory |
| `EACCES` | Permission denied |
| `ECONNREFUSED` | Connection refused |
| `ETIMEDOUT` | Connection timed out |
| `ENOMEM` | Out of memory |
| `EBUSY` | Resource busy |

---

## 🎛️ Opciones principales

| Opción | Descripción |
|--------|-------------|
| `-p <PID>` | Adjuntar a proceso existente |
| `-e trace=<syscalls>` | Filtrar por tipo de syscall (open, read, write, network, file, process) |
| `-c` | Resumen estadístico (conteo de syscalls, tiempo, errores) |
| `-f` | Seguir procesos hijos (fork/clone) |
| `-o <archivo>` | Escribir salida a archivo |
| `-t` | Agregar timestamp a cada línea |
| `-T` | Mostrar tiempo que tardó cada syscall |
| `-s <n>` | Truncar strings a n caracteres (default: 32) |
| `-v` | No abreviar argumentos (mostrar todo) |
| `-x` | Mostrar strings en hexadecimal |

---

## 📋 Patrones de uso

### Ver qué archivos abre un proceso

```bash
strace -e trace=open,openat -p <PID> 2>&1 | grep -v ENOENT
```

### Ver conexiones de red de un proceso

```bash
strace -e trace=network -p <PID>
```

### Ver por qué un proceso falla al iniciar

```bash
strace <comando> 2>&1 | grep -i "error\|fail\|enoent\|eacces"
```

### Ver cuánto tarda cada syscall

```bash
strace -T -p <PID> 2>&1 | tail -20
```

### Resumen de syscalls (cuáles usa más)

```bash
strace -c -p <PID>
```

### Seguir procesos hijos

```bash
strace -f -p <PID>
```

---

## 🔍 Uso en troubleshooting

### Proceso no puede abrir archivo

```bash
strace -e trace=open,openat -p <PID> 2>&1 | grep -v "= -1"
```

Si ves `ENOENT`, el archivo no existe. Si ves `EACCES`, no tienes permisos.

### Proceso bloqueado en I/O

```bash
strace -T -p <PID> 2>&1 | grep -E "read|write" | tail -10
```

Si ves `read` o `write` con tiempos altos, el proceso está esperando I/O.

### Proceso no puede conectarse a red

```bash
strace -e trace=network -p <PID> 2>&1 | grep -E "connect|ECONNREFUSED|ETIMEDOUT"
```

Si ves `ECONNREFUSED`, el servicio remoto no está corriendo. Si ves `ETIMEDOUT`, hay un problema de red.

### Proceso consumiendo CPU (qué está haciendo)

```bash
strace -c -p <PID>
```

El resumen te dice qué syscall consume más tiempo.

---

## 🛠️ Combinación con otras herramientas

### Con ps (encontrar el PID)

```bash
PID=$(pgrep -f nginx | head -1)
strace -p $PID -c
```

### Con grep (filtrar errores)

```bash
strace -p <PID> 2>&1 | grep -i "error\|fail\|enoent"
```

### Con awk (extraer tiempos)

```bash
strace -T -p <PID> 2>&1 | awk -F'<|>' '/^[a-z]/ {print $2, $1}' | sort -rn | head -10
```

### Con lsof (ver archivos abiertos vs syscalls)

```bash
lsof -p <PID> | wc -l
strace -e trace=open,close -p <PID> -c
```

---

## 💡 Uno-liners imprescindibles

```bash
# Ver qué archivos abre un proceso
strace -e trace=open,openat -p <PID> 2>&1

# Resumen de syscalls (qué hace más)
strace -c -p <PID>

# Ver por qué un comando falla
strace <comando> 2>&1 | grep -i "error\|fail\|enoent"

# Ver conexiones de red
strace -e trace=network -p <PID> 2>&1

# Ver cuánto tarda cada syscall
strace -T -p <PID> 2>&1 | tail -20

# Seguir proceso y sus hijos
strace -f -p <PID>

# Guardar trace en archivo para análisis posterior
strace -o /tmp/trace.log -p <PID>

# Ver syscalls de memoria
strace -e trace=mmap,brk,mprotect -p <PID>

# Trace con timestamps
strace -t -p <PID>

# Trace limitando longitud de strings
strace -s 200 -p <PID>
```

---

## ⚠️ Errores comunes

### Olvidar redirigir stderr

`strace` escribe a stderr. Usar `2>&1` para capturar con grep.

### No usar -f con procesos que forkean

Si el proceso crea hijos y no usas `-f`, solo ves el padre.

### Overhead en producción

`strace` genera overhead significativo. No usar en producción con mucho tráfico sin precaución.

### Confundir fd con error

`open(...) = 3` es éxito (fd=3). `open(...) = -1 ENOENT` es error.

### Strings truncados

Por default `strace` trunca strings a 32 caracteres. Usar `-s 200` para ver más.

---

## ✅ Buenas prácticas

- empezar con `strace -c` para tener un resumen antes de ver el detalle
- usar `-e trace=open,read,write` para no perderse en el ruido de todas las syscalls
- usar `-o /tmp/trace.log` para no saturar la terminal y poder analizar después
- usar `-T` para identificar syscalls lentas
- limitar el tiempo de captura (no dejar corriendo indefinidamente)
- no usar en producción sin necesidad — el overhead es real

---

## 🔗 Referencias internas

- [`lsof`](lsof.md) — archivos abiertos por procesos
- [`ps`](ps.md) — visualización de procesos
- [`top`](top.md) — monitoreo de procesos
