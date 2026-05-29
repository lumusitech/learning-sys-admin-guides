# htop — Guía completa

**Nivel:** 🟢 Básico
**Archivos de práctica:** Sistema en vivo
**Ver escenarios relacionados:** [`system/04-high-cpu-runaway-process.md`](../scenarios/system/04-high-cpu-runaway-process.md), [`system/05-system-memory-issues-oom.md`](../scenarios/system/05-system-memory-issues-oom.md), [`system/07-high-io-wait.md`](../scenarios/system/07-high-io-wait.md), [`system/08-zombie-processes.md`](../scenarios/system/08-zombie-processes.md)

---

## ⚡ Quick command

`htop`

> ⚠️ `htop` no está instalado por defecto en muchas distros. Instalar con `apt install htop` o `apk add htop`. En Alpine/BusyBox usar `top` como alternativa.

---

## ⚡ Quick run

```bash
htop -d 10
```

---

## 📑 Índice

1. [¿Qué es htop?](#qué-es-htop)
2. [Modelo mental](#modelo-mental)
3. [Sintaxis básica](#sintaxis-básica)
4. [Salida clave](#salida-clave)
5. [Opciones principales](#opciones-principales)
6. [Teclas de navegación](#teclas-de-navegación)
7. [Patrones de uso](#patrones-de-uso)
8. [Uso en troubleshooting](#uso-en-troubleshooting)
9. [Combinación con otras herramientas](#combinación-con-otras-herramientas)
10. [Uno-liners imprescindibles](#uno-liners-imprescindibles)
11. [Errores comunes](#errores-comunes)
12. [Buenas prácticas](#buenas-prácticas)

---

## 🧠 ¿Qué es htop?

`htop` es una versión mejorada de `top` con interfaz interactiva, colores, y navegación con teclado/flechas. Muestra procesos, CPU, memoria, swap, y permite matar, reniciar y filtrar procesos.

- qué hace: visor interactivo de procesos con interfaz visual
- para qué sirve: monitorear procesos, identificar consumidores de CPU/memoria, matar procesos
- cuándo usarlo: durante un incidente para ver qué está pasando en tiempo real
- cuándo NO usarlo: en scripts (usar `top -b` o `ps`), en servidores sin terminal (usar `top -b`)

---

## 🧠 Modelo mental

`htop` es la versión "visual" de `top`. Mientras que `top` muestra texto plano, `htop` muestra barras de CPU, colores, y permite navegar con flechas.

Piensalo así:

- `ps` → snapshot de procesos (una vez)
- `top` → snapshot continuo en texto plano
- `htop` → snapshot continuo con interfaz interactiva

`htop` es ideal para diagnóstico interactivo. Para scripts o monitoreo remoto, `top -b` o `ps` son mejores.

---

## 📝 Sintaxis básica

```bash
htop [opciones]
```

Sin opciones muestra la interfaz interactiva.

---

## 🔑 Salida clave

La interfaz de `htop` tiene tres secciones:

### 1. Barras de CPU (parte superior)

```text
  CPU[||||||||||||||||||||||||||||||||||||||||| 100.0%]
  Mem[||||||||||||||||||||           1024M/4096M]
  Swp[                               0M/2048M]
```

- cada barra representa un núcleo de CPU
- colores: verde=user, rojo=kernel, azul=low priority, amarillo=I/O wait

### 2. Información de memoria (debajo de CPU)

```text
Mem: 2048M/4096M used
Swp: 0M/2048M used
```

### 3. Lista de procesos (parte inferior)

```text
  PID USER   PRI  NI  VIRT   RES   SHR S CPU% MEM%   TIME+  Command
 1234 root    20   0  1024M  512M  128M S 95.0 12.5  10:30.42 python3 app.py
```

Campos importantes:

| Campo | Significado |
|-------|-------------|
| `PID` | ID del proceso |
| `USER` | Usuario propietario |
| `PRI` | Prioridad del scheduler |
| `NI` | Nice value (prioridad ajustable) |
| `VIRT` | Memoria virtual total |
| `RES` | Memoria residente (RAM real usada) |
| `SHR` | Memoria compartida |
| `S` | Estado: S=sleeping, R=running, Z=zombie, D=uninterruptible |
| `CPU%` | % de CPU usado |
| `MEM%` | % de memoria usado |
| `TIME+` | Tiempo total de CPU |
| `Command` | Comando ejecutado |

---

## 🎛️ Opciones principales

| Opción | Descripción |
|--------|-------------|
| `-d <decimas>` | Delay en décimas de segundo (10 = 1 segundo) |
| `-u <usuario>` | Mostrar solo procesos de un usuario |
| `-p <PID>` | Mostrar solo un proceso específico |
| `-s <columna>` | Ordenar por columna |
| `-t` | Mostrar en modo árbol |
| `-H` | Mostrar hilos (threads) |
| `-b` | Modo batch (no interactivo, para scripts) |
| `-n <n>` | Salir después de n iteraciones (en modo batch) |
| `--no-color` | Sin colores |
| `--sort-key <columna>` | Ordenar por columna específica |

---

## 📋 Patrones de uso

### Ver procesos ordenados por CPU

```bash
htop -s PERCENT_CPU
```

### Ver procesos ordenados por memoria

```bash
htop -s PERCENT_MEM
```

### Ver procesos de un usuario específico

```bash
htop -u www-data
```

### Ver un proceso específico

```bash
htop -p 1234
```

### Modo batch para scripts

```bash
htop -b -n 1 | head -30
```

### Ver hilos (threads)

```bash
htop -H
```

---

## 🔍 Uso en troubleshooting

### Proceso consumiendo toda la CPU

1. Ejecutar `htop`
2. Ordenar por CPU (presionar `F6`, seleccionar `PERCENT_CPU`)
3. Identificar el proceso con CPU% alto
4. Presionar `F9` para enviar señal (kill)

### Proceso consumiendo mucha memoria

1. Ejecutar `htop`
2. Ordenar por MEM% (presionar `F6`, seleccionar `PERCENT_MEM`)
3. Identificar el proceso con MEM% alto
4. Verificar si es un leak (MEM% crece con el tiempo)

### Proceso zombie

1. Ejecutar `htop`
2. Buscar procesos con estado `Z`
3. Ver el PPID (proceso padre)
4. Investigar el padre

### Proceso en estado D (uninterruptible)

1. Ejecutar `htop`
2. Buscar procesos con estado `D`
3. Indican I/O bloqueada — revisar con `iostat`

---

## 🛠️ Combinación con otras herramientas

### Con ps (para scripts)

```bash
# htop es interactivo, para scripts usar ps
ps aux --sort=-%cpu | head -10
```

### Con top (modo batch)

```bash
# htop -b para modo batch, o top -b
htop -b -n 1 | head -20
```

### Con strace (ver qué hace un proceso)

```bash
# Primero encontrar el PID en htop, luego:
strace -p <PID> -c
```

### Con kill (matar un proceso)

```bash
# En htop: seleccionar proceso, presionar F9, elegir señal
# O desde terminal:
kill -9 <PID>
```

---

## 💡 Uno-liners imprescindibles

```bash
# Abrir htop
htop

# htop con delay de 1 segundo
htop -d 10

# htop ordenado por CPU
htop -s PERCENT_CPU

# htop ordenado por memoria
htop -s PERCENT_MEM

# htop solo para un usuario
htop -u root

# htop para un proceso específico
htop -p 1234

# htop en modo batch (para scripts)
htop -b -n 1 | head -30

# htop con hilos
htop -H

# htop en modo árbol
htop -t

# htop sin colores
htop --no-color
```

---

## ⚠️ Errores comunes

### Usar htop en scripts

`htop` es interactivo. Para scripts usar `top -b` o `ps`.

### No saber las teclas de navegación

Las teclas más importantes: `F6` (ordenar), `F9` (kill), `F4` (filtrar), `F5` (árbol).

### Confundir VIRT con RES

`VIRT` es memoria virtual total (incluye swap y mapeos). `RES` es la RAM real usada.

### No ver hilos

Por default `htop` muestra procesos, no hilos. Usar `-H` para ver hilos.

### Usar htop en servidores sin terminal

`htop` necesita una terminal. En servidores remotos usar `htop -b` o `top -b`.

---

## ✅ Buenas prácticas

- usar `htop` para diagnóstico interactivo, `ps` para scripts
- ordenar por CPU o MEM según el problema
- usar modo árbol (`F5` o `-t`) para ver la relación padre-hijo
- usar `-b` para capturar la salida en scripts o pipes
- recordar que `htop` no está en todas las distros — `top` es la alternativa universal

---

## 🔗 Referencias internas

- [`top`](top.md) — visor de procesos (alternativa)
- [`ps`](ps.md) — snapshot de procesos
- [`free`](free.md) — memoria y swap
- [`kill`](ps.md) — enviar señales a procesos
