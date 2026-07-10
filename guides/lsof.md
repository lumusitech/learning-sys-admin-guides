# lsof — Guía completa

**Nivel:** 🟡 Intermedio
**Archivos de práctica:** Sistema en vivo
**Ver escenarios relacionados:** [`system/04-high-cpu-runaway`](../scenarios/system/04-high-cpu-runaway-process.md), [`networking/08-firewall-blocked-port`](../scenarios/networking/08-firewall-blocked-port.md)

---

## ⚡ Quick command

`lsof -i :80`

---

## ⚡ Quick run

```bash
lsof -i -P -n | head -20
```

---

## 📑 Índice

1. [¿Qué es lsof?](#qué-es-lsof)
2. [Sintaxis básica](#sintaxis-básica)
3. [Salida clave](#salida-clave)
4. [Opciones principales](#opciones-principales)
5. [Listar por puerto (-i)](#listar-por-puerto--i)
6. [Listar por proceso (-p)](#listar-por-proceso--p)
7. [Listar por usuario (-u)](#listar-por-usuario--u)
8. [Listar archivos abiertos](#listar-archivos-abiertos)
9. [Patrones de uso](#patrones-de-uso)
10. [Uso en troubleshooting](#uso-en-troubleshooting)
11. [Combinación con otras herramientas](#combinación-con-otras-herramientas)
12. [Uno-liners imprescindibles](#uno-liners-imprescindibles)
13. [Errores comunes](#errores-comunes)
14. [Buenas prácticas](#buenas-prácticas)

---

## 🧠 ¿Qué es lsof?

**lsof** (list open files) lista los archivos abiertos por procesos. En Unix, "todo es un archivo": sockets de red, dispositivos, tuberías, directorios y archivos regulares. `lsof` los muestra a todos.

Se usa para:

- descubrir qué proceso está escuchando en un puerto;
- identificar qué proceso tiene un archivo bloqueado;
- depurar problemas de "archivo en uso" al desmontar un disco;
- monitorear conexiones de red de un servicio.

---

## 🧠 Modelo mental

Cuando un programa no puede:

- escuchar en un puerto → `lsof -i :<puerto>` para ver qué proceso lo ocupa;
- desmontar un disco → `lsof /mnt/disco` para ver qué archivo está en uso;
- reiniciar un servicio → `lsof -i` para ver si quedó un socket abierto.

`lsof` es el puente entre "algo está pasando" y "quién lo está haciendo".

---

## 📝 Sintaxis básica

```bash
lsof [opciones]
```

```bash
lsof -i :80                   # ¿Quién escucha en el puerto 80?
lsof -p <PID>                 # Archivos abiertos por un proceso
lsof -u www-data              # Archivos abiertos por un usuario
lsof /var/log/syslog          # ¿Qué proceso está escribiendo este archivo?
lsof +D /var/log              # Archivos abiertos bajo un directorio
```

---

## 🔑 Salida clave

```text
COMMAND     PID   USER   FD   TYPE  DEVICE  SIZE/OFF  NODE  NAME
nginx      1234  root   6u   IPv4  34567    0t0       TCP   *:80 (LISTEN)
nginx      1235  admin  3u   IPv4  34568    0t0       TCP   10.0.0.1:80->10.0.0.5:54321 (ESTABLISHED)
sshd       1560  root   3u   IPv4  45678    0t0       TCP   *:22 (LISTEN)
```

| Columna | Significado |
|---------|-------------|
| `COMMAND` | Nombre del proceso |
| `PID` | Process ID |
| `USER` | Usuario dueño del proceso |
| `FD` | File descriptor (tipo de archivo) |
| `TYPE` | Tipo de archivo (REG, DIR, IPv4, IPv6, etc.) |
| `DEVICE` | Dispositivo (IDs de major/minor) |
| `SIZE/OFF` | Tamaño u offset |
| `NODE` | Número de inode (o protocolo) |
| `NAME` | Ruta, nombre de socket o dirección de conexión |

### File descriptors comunes

| FD | Significado |
|----|-------------|
| `cwd` | Current working directory |
| `rtd` | Root directory |
| `txt` | Text (código ejecutable) |
| `mem` | Archivo mapeado en memoria |
| `0u` | stdin (lectura/escritura) |
| `1u` | stdout |
| `2u` | stderr |
| `3u`, `4u`... | File descriptors del proceso |

---

## 🎛️ Opciones principales

| Opción | Efecto |
|--------|--------|
| `-i :<puerto>` | Conexiones de red en un puerto |
| `-iTCP` | Solo conexiones TCP |
| `-iUDP` | Solo conexiones UDP |
| `-p <PID>` | Archivos de un proceso específico |
| `-u <usuario>` | Archivos de un usuario |
| `+D <dir>` | Archivos abiertos bajo un directorio (recursivo) |
| `+d <dir>` | Archivos abiertos en un directorio (no recursivo) |
| `-t` | Solo PIDs (modo terse, útil para piping) |
| `-n` | No resuelve nombres de host (más rápido) |
| `-P` | No resuelve nombres de puerto (más rápido) |
| `-s` | Protocolo específico:TCP:LISTEN |
| `-c <prefix>` | Archivos de procesos cuyo comando empieza con... |

---

## Listar por puerto (-i)

La opción más usada. Variantes:

```bash
# Puerto específico
lsof -i :80

# Sin resolución de nombres
lsof -i :80 -P -n

# Solo LISTEN (servidores)
lsof -i :80 -sTCP:LISTEN

# Solo conexiones establecidas
lsof -i :80 -sTCP:ESTABLISHED

# Todos los puertos en escucha
lsof -i -sTCP:LISTEN -P -n

# Rango de puertos
lsof -i :1-1024
```

---

## Listar por proceso (-p)

Para saber qué archivos tiene abiertos un proceso:

```bash
lsof -p 1234

# Contar archivos abiertos
lsof -p 1234 | wc -l

# Solo conexiones de red
lsof -p 1234 -i

# Solo archivos regulares
lsof -p 1234 -a -f ''
```

---

## Listar por usuario (-u)

```bash
# Todos los archivos abiertos por nginx
lsof -u www-data

# Procesos de varios usuarios
lsof -u www-data,admin

# Excluir un usuario
lsof -u ^root
```

---

## Listar archivos abiertos

```bash
# ¿Quién tiene abierto este archivo?
lsof /var/log/syslog

# ¿Quién tiene archivos abiertos en este directorio?
lsof +D /var/log

# Archivos borrados pero aún abiertos (ocupan espacio en disco)
lsof +L1
```

Los archivos borrados pero aún abiertos son una causa común de discos llenos: un proceso mantiene un FD abierto a un archivo que ya no existe en el sistema de archivos. El espacio no se libera hasta que el proceso cierre el FD.

---

## 📋 Patrones de uso

### Puerto en escucha

```bash
lsof -i :3306 -sTCP:LISTEN -P -n
```

### Conexiones activas de un proceso

```bash
lsof -p 1234 -i -P -n | grep ESTABLISHED
```

### Archivos borrados pero ocupando espacio

```bash
lsof +L1 | awk '$5 == "delete" { print $9, $7 }'
```

### Archivos de log abiertos

```bash
lsof | grep '\.log$'
```

### Procesos con más archivos abiertos

```bash
lsof | awk '{print $1}' | sort | uniq -c | sort -rn | head -10
```

---

## 🔍 Uso en troubleshooting

### "Port already in use"

```bash
lsof -i :8080 -P -n
```

Devuelve el PID del proceso que ocupa el puerto. Matalo o espera que termine.

### "Device or resource busy" al desmontar

```bash
lsof /mnt/usb
```

Mustra qué proceso está usando archivos en el dispositivo. Termina el proceso o hazle `kill` si es necesario.

### Disco lleno pero no hay archivos grandes

Puede haber archivos borrados pero retenidos por procesos:

```bash
lsof +L1 | awk '$7 > 0 { print $9, $7, $1 }'
```

### Servicio que no responde

```bash
lsof -i -sTCP:ESTABLISHED -P -n | grep <PID_SERVICIO>
```

Si tiene muchas conexiones ESTABLISHED y el proceso está en CPU alta, podría estar saturado.

---

## 🛠️ Combinación con otras herramientas

### lsof + ps: ¿qué proceso ocupa el puerto?

```bash
lsof -i :80 -P -n | awk 'NR>1 {print $2}' | xargs ps -o pid,user,%cpu,args -p
```

### lsof + kill: cerrar conexiones de un usuario

```bash
lsof -t -u admin -i | xargs kill -15
```

### lsof + watch: monitoreo de conexiones

```bash
watch -n 2 'lsof -i -sTCP:ESTABLISHED -P -n | wc -l'
```

---

## 💡 Uno-liners imprescindibles

```bash
lsof -i :<puerto> -P -n                      # ¿Quién escucha?
lsof -i -sTCP:LISTEN -P -n                  # Todos los puertos en escucha
lsof -p <PID> -i -P -n                      # Conexiones de un proceso
lsof +L1 | awk '$7 > 0'                     # Archivos borrados retenidos
lsof /ruta                                   # ¿Quién usa este archivo?
lsof -u www-data -i                         # Conexiones de un usuario
lsof | awk '{print $1}' | sort | uniq -c | sort -rn | head   # Top procesos por FDs
lsof -t -i :80                              # Solo PID del proceso en puerto 80
```

---

## ⚠️ Errores comunes

- **Ejecutar `lsof` sin `-P -n`**. Resuelve nombres de host y puertos, lo que puede tardar minutos en servidores con muchas conexiones. Siempre usar `-P -n` en producción.
- **No tener permisos**. `lsof` requiere `root` para ver archivos de otros usuarios. Como usuario normal ves solo tus propios procesos.
- **Canalizar `lsof` sin filtrar**. `lsof` solo (sin opciones) lista **todos** los archivos abiertos del sistema. Pueden ser miles de líneas. Siempre filtrar por puerto, PID o archivo.
- **Buscar un puerto que no está en escucha**. `lsof -i :80` solo muestra si hay un proceso escuchando o conectado. Si el puerto está libre, no muestra nada.
- **Confundir `+D` con `+d`**. `+D` es recursivo (profundidad infinita). `+d` es un solo nivel. En root, `+D` puede ser muy lento.

---

## ✅ Buenas prácticas

- Siempre usar `-P -n` en producción para evitar resoluciones lentas.
- Filtrar por puerto (`:80`) cuando busques el proceso que escucha.
- Filtrar por PID (`-p <PID>`) cuando investigues un proceso específico.
- Antes de desmontar un disco, usar `lsof /mnt/punto` para saber qué lo retiene.
- Para monitorear conexiones, usar `lsof -i -sTCP:ESTABLISHED -P -n` y pipear a `wc -l`.
- En Alpine/BusyBox, `lsof` puede no estar instalado. Alternativa: `ss -tuln`, `fuser <puerto>/tcp`.

---

## 🔗 Referencias internas

- [`ip_ss`](ip_ss.md) — conexiones de red con `ss` (alternativa portable a `lsof`)
- [`ps`](ps.md) — procesos del sistema
- [`fuser`](fuser.md) — identificar proceso por puerto (rango de root)
