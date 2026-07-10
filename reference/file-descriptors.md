# File Descriptors y ulimit — Referencia rápida

Qué son los file descriptors (FD), cómo diagnosticar fugas y el error "too many open files".

---

## 🧠 ¿Qué es un file descriptor?

Un file descriptor (FD) es un número entero que el kernel asigna a cada recurso abierto por un proceso: archivos, sockets, pipes, dispositivos.

Los tres FDs estándar:

| FD | Nombre | Propósito | Redirección |
|----|--------|-----------|------------|
| 0 | stdin | Entrada estándar (teclado) | `<` |
| 1 | stdout | Salida estándar (pantalla) | `>` o `1>` |
| 2 | stderr | Salida de error (pantalla) | `2>` |

---

## 📊 Ver FDs de un proceso

```bash
ls -la /proc/<PID>/fd/           # lista todos los FDs abiertos
lsof -p <PID>                     # archivos, sockets, pipes abiertos
ls /proc/<PID>/fd/ | wc -l       # contar FDs abiertos
```

### Interpretar la salida de `/proc/<PID>/fd/`

```text
0 -> /dev/pts/0        # stdin (terminal)
1 -> /dev/pts/0        # stdout
2 -> /dev/pts/0        # stderr
3 -> socket:[12345]    # socket de red abierto
4 -> /var/log/app.log  # archivo de log abierto
5 -> pipe:[67890]      # pipe entre procesos
6 -> /var/lib/mysql/.. # archivo de datos
```

FDs muy altos (cientos o miles con el mismo patrón) = posible fuga (leak).

---

## 📐 Límites de FDs

| Comando | Qué muestra |
|---------|------------|
| `ulimit -n` | Límite soft de FDs por proceso |
| `ulimit -Hn` | Límite hard de FDs por proceso |
| `cat /proc/sys/fs/file-max` | Máximo de FDs a nivel sistema |
| `cat /proc/sys/fs/file-nr` | FDs asignados / libres / máximo |

### Valores típicos

| Entorno | Límite soft | Significado |
|---------|-----------|------------|
| Desktop Linux | 1024 | Por defecto conservador |
| Servidor Linux moderno | 65536 o 1048576 | systemd sube el límite |
| Docker (default) | 1048576 | Alto por defecto |
| MySQL / PostgreSQL | Configurable en `my.cnf` / `postgresql.conf` | Necesitan muchos FDs para conexiones |

---

## 🚨 Error: "Too many open files"

### Síntomas

```text
# En aplicación
socket.error: [Errno 24] Too many open files
java.io.IOException: Too many open files

# En shell
-bash: start_pipeline: pgrp pipe: Too many open files
```

### Diagnóstico

```bash
# 1. ¿Qué proceso tiene más FDs abiertos?
for pid in /proc/[0-9]*; do
  count=$(ls "$pid/fd/" 2>/dev/null | wc -l)
  [ "$count" -gt 100 ] && echo "$pid: $count FDs"
done

# 2. ¿Cuál es el límite actual?
ulimit -n

# 3. ¿El sistema está cerca del máximo global?
cat /proc/sys/fs/file-nr
# salida: 6784    0    9223372036854775807
#         ^^^^    ^
#         usados  libres (siempre 0 en kernels modernos)
```

### Acción inmediata

```bash
# Subir el límite (afecta la shell actual y sus hijos)
ulimit -n 65536

# Para un servicio con systemd
systemctl edit <servicio>
# agregar:
# [Service]
# LimitNOFILE=65536
systemctl daemon-reload && systemctl restart <servicio>

# Docker: al ejecutar el contenedor
docker run --ulimit nofile=65536:65536 ...
```

---

## 🔍 Fugas de FDs (FD leak)

Una fuga ocurre cuando un proceso abre archivos/sockets y nunca los cierra.

### Detectar con el tiempo

```bash
# Tomar snapshot ahora
ls /proc/<PID>/fd/ | wc -l > /tmp/fd_count_1

# Esperar 5 minutos y comparar
sleep 300
ls /proc/<PID>/fd/ | wc -l > /tmp/fd_count_2

diff /tmp/fd_count_1 /tmp/fd_count_2
# Si crece continuamente → fuga
```

### Patrón clásico: sockets en CLOSE_WAIT

```bash
ss -tan state close-wait | wc -l
# Si el número crece sin parar → la app no está cerrando sockets
```

---

## 🔗 Ver también

- [`guides/lsof.md`](../guides/lsof.md) — listar archivos y sockets abiertos
- [`guides/ip_ss.md`](../guides/ip_ss.md) — conexiones y estado de sockets
- [`guides/ps.md`](../guides/ps.md) — procesos y PIDs
- [`reference/tcp-connection-states.md`](tcp-connection-states.md) — estados TCP
- [`reference/cgroups.md`](cgroups.md) — control groups y límites de recursos
- [`scenarios/system/05-system-memory-issues-oom.md`](../scenarios/system/05-system-memory-issues-oom.md) — OOM killer
