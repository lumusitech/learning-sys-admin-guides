# stat — Guía completa de metadatos de archivos

**Nivel:** 🟢 Básico
**Archivos de práctica:** Descripción general (funciona en cualquier sistema)
**Ver escenarios relacionados:** [`system/06-disk-full-inodes`](../scenarios/system/06-disk-full-inodes.md)

---

## ⚡ Quick command

`stat /etc/passwd`

> ⚠️ Sintaxis de fechas varía: en GNU/Linux usa `stat -c`, en BSD/macOS usa `stat -f`.

---

## ⚡ Quick run

```bash
stat -c "archivo: %n | tamaño: %s bytes | modificado: %y" /etc/passwd
```

---

## 📑 Índice

1. [¿Qué es stat?](#qué-es-stat)
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
12. [Referencias internas](#referencias-internas)

---

## 🧠 ¿Qué es stat?

stat muestra los **metadatos** de un archivo o filesystem: tamaño real, espacio en disco, permisos, propietario, timestamps (access, modify, change, birth), número de inodo y tipo de archivo.

Es más preciso que `ls -l` porque:

- muestra el tamaño real vs espacio en disco
- muestra los 4 timestamps (ls solo muestra modify time)
- muestra el número de inodo
- muestra en segundos exactos (ls redondea)

---

## 🧠 Modelo mental

Pensá en stat como la **ficha médica del archivo**. Así como la ficha médica tiene talla, peso, fecha de nacimiento y última consulta, stat tiene tamaño, permisos, fecha de creación y última modificación.

`ls -l` es como ver la etiqueta del paciente — superficial. `stat` es abrir la ficha completa.

---

## 📝 Sintaxis básica

```text
stat [opciones] archivo...
```

---

## 🔑 Salida clave

### `stat /etc/passwd` (por defecto, verbose)

```text
  File: /etc/passwd
  Size: 2837            Blocks: 8          IO Block: 4096   regular file
Device: 259,2   Inode: 2752653     Links: 1
Access: (0644/-rw-r--r--)  Uid: (    0/    root)   Gid: (    0/    root)
Access: 2026-07-10 18:24:45.123456789 -0300
Modify: 2026-07-09 14:11:32.987654321 -0300
Change: 2026-07-09 14:11:32.987654321 -0300
 Birth: 2026-06-01 08:00:00.000000000 -0300
```

### Interpretación campo por campo

| Campo | Significado |
|-------|-------------|
| Size | Tamaño del archivo en bytes |
| Blocks | Bloques de disco asignados (×512 bytes en Linux) |
| IO Block | Tamaño de bloque óptimo para I/O |
| Inode | Número de inodo (único en el filesystem) |
| Links | Cantidad de hard links al inodo |
| Access | Timestamp de último acceso (lectura) |
| Modify | Timestamp de última modificación (contenido) |
| Change | Timestamp de último cambio de metadatos (permisos, dueño, etc.) |
| Birth | Timestamp de creación (solo en algunos filesystems: ext4, btrfs, zfs) |

---

## 🎛️ Opciones principales

### Formato personalizado (GNU stat)

```text
stat -c "formato" archivo
```

| Secuencia | Significado |
|-----------|-------------|
| `%n` | Nombre del archivo |
| `%s` | Tamaño en bytes |
| `%b` | Bloques asignados |
| `%i` | Número de inodo |
| `%a` | Permisos en octal (0644) |
| `%A` | Permisos en texto (-rw-r--r--) |
| `%U` | Usuario propietario |
| `%G` | Grupo propietario |
| `%x` | Access time |
| `%y` | Modify time |
| `%z` | Change time |
| `%w` | Birth time |
| `%F` | Tipo de archivo (regular file, directory, symlink) |
| `%h` | Número de hard links |

### Formato personalizado (BSD/macOS)

```text
stat -f "formato" archivo
```

> ⚠️ La sintaxis es totalmente diferente: `stat -f "%N %z %m" archivo`.

---

## 📋 Patrones de uso

### Ver solo tamaño y nombre

```bash
stat -c "%s %n" archivo
```

### Ver permisos en octal

```bash
stat -c "%a %n" /etc/passwd
```

### Ver fecha de última modificación

```bash
stat -c "%y" archivo
```

### Ver todos los metadatos en una línea

```bash
stat -c " %n | tipo: %F | tamaño: %s | inodo: %i | permisos: %a | owner: %U:%G | modify: %y" *
```

### Ver metadatos del filesystem (no de un archivo)

```bash
stat -f /
```

---

## 🔍 Uso en troubleshooting

### "¿Por qué ls -l muestra más espacio usado que la suma de tamaños?"

```bash
stat -c "%n %s %b" * | awk '{total_size += $2; total_blocks += $3} END {print total_size, total_blocks * 512}'
```

Un archivo de 1 byte ocupa al menos 1 bloque (4096 bytes típico). Si hay miles de archivos chicos, el espacio en disco es mucho mayor que la suma de tamaños. Esto se detecta con inodos: `df -i`.

### "¿Quién y cuándo modificó este archivo?"

```bash
stat -c "owner: %U | modify: %y | change: %z" archivo_sospechoso
```

### "¿Este archivo es un hard link?"

```bash
stat -c "%h %i %n" * | awk '$1 > 1'
```

Si Links > 1, es un hard link. Mismo inodo = mismo archivo.

### "¿Permisos actuales de este archivo de config?"

```bash
stat -c "%a %U:%G %n" /etc/ssh/sshd_config
```

---

## 🛠️ Combinación con otras herramientas

### stat + find

```bash
# Archivos modificados en las últimas 24h con permisos
find /etc -type f -mtime -1 -exec stat -c "%a %y %n" {} \;
```

### stat + awk

```bash
# Ordenar archivos por fecha de modificación
stat -c "%Y %n" * | sort -rn | awk '{print $2}'
```

### stat + sort

```bash
# Top 10 archivos más grandes
stat -c "%s %n" * | sort -rn | head -10
```

---

## 💡 Uno-liners imprescindibles

```bash
# Metadatos completos de un archivo
stat /etc/passwd

# Tamaño y nombre de todos los archivos del directorio
stat -c "%s %n" *

# Permisos en octal
stat -c "%a %n" *

# Fecha de modificación formateada
stat -c "%y" archivo

# Identificar archivos con hard links
stat -c "%h %i %n" * | awk '$1 > 1'

# Archivos modificados más recientemente
stat -c "%Y %n" * | sort -rn | head -5

# Detectar archivos sin leer en 30 días
find . -type f -atime +30 -exec stat -c "%x %n" {} \;

# Espacio real vs tamaño de archivo (para archivos sparse)
stat -c "size=%s blocks=%b ratio=%s*512/%b" archivo_sparse

# Información del filesystem donde está este archivo
stat -f archivo

# Todos los timestamps con formato ISO
stat -c "access=%x modify=%y change=%z birth=%w" archivo
```

---

## ⚠️ Errores comunes

| Error | Causa | Solución |
|-------|-------|----------|
| `stat: no such file` | Archivo no existe o symlink roto | `readlink -f` para resolver paths |
| `stat -c` no funciona en macOS | BSD stat vs GNU stat | Usar `stat -f` en BSD, o `brew install coreutils` |
| `%w` devuelve `-` | Filesystem no soporta birth time | Usar `debugfs` para ext4 o `stat` en btrfs/zfs |
| Access time no se actualiza | `noatime` en `/etc/fstab` | Comportamiento normal: reduce I/O de disco |

---

## ✅ Buenas prácticas

1. **Usar `stat` para scripts, no `ls`**: el output de `ls` cambia según locale; `stat -c` es predecible
2. **Siempre verificar permisos con `%a`**: más fácil de comparar que `-rwxr-xr-x`
3. **Monitorear inodos con `%i`** si el disco se llena con el espacio libre (inodos agotados)
4. **Usar `%Y`** (segundos desde epoch) para comparar fechas en scripts
5. **Recordar**: modify time ≠ change time. Modify es contenido, change es metadatos
6. **Verificar hard links**: mismo inodo = mismo archivo, borrar uno no libera espacio si hay otros links

---

## 🔗 Referencias internas

- [`find`](find.md) — buscar archivos por metadatos
- [`du`](du.md) — espacio en disco
- [`df`](df.md) — espacio en filesystem
- [`ls -l`](ps.md) — alternativa limitada (no incluye inodo ni change time)
- [`scenario`](../scenarios/system/06-disk-full-inodes.md) — disco lleno por inodos agotados
- [`scenario`](../scenarios/security/02-suid-audit-and-file-permissions.md) — permisos y propietario sospechosos
