# tar — Guía completa de archivado y compresión

**Nivel:** 🟢 Básico
**Archivos de práctica:** Descripción general (funciona en cualquier sistema)
**Ver escenarios relacionados:** [`infrastructure/03-disaster-recovery`](../scenarios/infrastructure/03-disaster-recovery.md)

---

## ⚡ Quick command

`tar czf backup.tar.gz /ruta/a/backupear`

> ⚠️ Disponible en Alpine/BusyBox base (versión reducida pero funcional). Para soporte de xz o zstd en Alpine: `apk add xz zstd`.

---

## ⚡ Quick run

```bash
tar czf /tmp/backup-$(date +%Y%m%d).tar.gz /etc/ssh/
```

---

## 📑 Índice

1. [¿Qué es tar?](#qué-es-tar)
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

## 🧠 ¿Qué es tar?

tar (Tape ARchiver) es la herramienta estándar para empaquetar archivos y directorios en un solo archivo (tarball). Originalmente diseñado para backups en cinta magnética, hoy es el formato universal para distribución de software, backups y transferencias de directorios completos.

tar **no comprime** por sí mismo — solo empaqueta. La compresión viene de combinarlo con gzip, bzip2, xz o zstd.

---

## 🧠 Modelo mental

Pensá en tar como una **caja de mudanza**. Metés archivos y carpetas adentro de la caja (empaquetar), y después podés comprimir la caja con una bolsa al vacío (gzip/xz). Para ver qué hay adentro, abrís la caja (extraer/ver contenido).

tar preserva todo lo que el filesystem sabe del archivo: permisos, propietario, timestamps, estructura de directorios, y symlinks.

---

## 📝 Sintaxis básica

```text
tar [operación] [opciones] [archivo_tar] [archivos...]
```

### Operaciones principales

| Flag | Operación |
|------|-----------|
| `c` | Create: crear archivo tar |
| `x` | Extract: extraer archivo tar |
| `t` | List: ver contenido sin extraer |
| `r` | Append: agregar archivos a un tar existente |
| `u` | Update: agregar solo archivos más nuevos |

### Flags de compresión

| Flag | Formato | Extensión |
|------|---------|-----------|
| `z` | gzip | .tar.gz / .tgz |
| `j` | bzip2 | .tar.bz2 |
| `J` | xz | .tar.xz |
| `--zstd` | zstd | .tar.zst |

---

## 🔑 Salida clave

### `tar tvf archivo.tar.gz`

```text
-rw-r--r-- root/root   2837 2026-07-09 14:11 etc/passwd
-rw-r--r-- root/root   1234 2026-06-15 10:30 etc/group
drwxr-xr-x root/root      0 2026-07-01 08:00 etc/ssh/
-rw------- root/root    411 2026-06-01 09:15 etc/ssh/ssh_host_rsa_key
```

| Columna | Significado |
|---------|-------------|
| `-rw-r--r--` | Permisos |
| `root/root` | Propietario / grupo |
| `2837` | Tamaño en bytes |
| `2026-07-09 14:11` | Fecha de modificación |
| `etc/passwd` | Ruta (relativa desde la raíz del tar) |

### Crear + verbose

```text
$ tar cvzf backup.tar.gz /etc/ssh/
etc/ssh/
etc/ssh/ssh_config
etc/ssh/sshd_config
etc/ssh/ssh_host_rsa_key
```

---

## 🎛️ Opciones principales

| Flag | Significado |
|------|-------------|
| `v` | Verbose: mostrar archivos procesados |
| `f` | File: especificar archivo tar |
| `C dir` | Cambiar a directorio antes de operar |
| `p` | Preservar permisos (default en root) |
| `P` | No eliminar `/` inicial de las rutas |
| `--exclude=patrón` | Excluir archivos |
| `-T archivo` | Leer lista de archivos de un archivo |
| `--strip-components=N` | Eliminar N niveles de directorio al extraer |
| `--overwrite` | Sobrescribir archivos existentes |
| `-k` | No sobrescribir archivos existentes |
| `--remove-files` | Borrar archivos de origen después de empaquetar |

---

## 📋 Patrones de uso

### Crear tarball comprimido con gzip

```bash
tar czf backup.tar.gz /ruta/
```

### Extraer tarball

```bash
tar xzf archivo.tar.gz
```

### Ver contenido sin extraer

```bash
tar tzf archivo.tar.gz
```

### Crear excluyendo archivos y directorios

```bash
tar czf backup.tar.gz --exclude='*.log' --exclude='node_modules' /var/www/
```

### Extraer en directorio específico

```bash
tar xzf archivo.tar.gz -C /tmp/restore/
```

### Extraer eliminando el primer nivel de directorios

```bash
tar xzf archivo.tar.gz --strip-components=1
```

### Crear tarball desde stdin (pipe)

```bash
find /var/log -name "*.log" -mtime +30 | tar czf old_logs.tar.gz -T -
```

### Extraer un solo archivo del tarball

```bash
tar xzf archivo.tar.gz ruta/dentro/del/tar/archivo.txt
```

---

## 🔍 Uso en troubleshooting

### "El tarball de backup creado en crontab tiene 0 bytes"

```bash
tar tzf backup.tar.gz && echo "OK" || echo "Tarball corrupto"
```

### "Extraer corrompió los permisos de los archivos"

```bash
tar xzpf archivo.tar.gz    # la 'p' preserva permisos originales
```

### "Quiero ver si el tarball incluye un archivo específico"

```bash
tar tzf archivo.tar.gz | grep archivo_buscado
```

### "Comprimir con máximo ratio (xz)"

```bash
tar cJf backup.tar.xz /ruta/       # más lento pero más comprimido
```

---

## 🛠️ Combinación con otras herramientas

### tar + ssh

```bash
# Transferir tarball por SSH sin archivo intermedio
tar czf - /ruta/ | ssh user@server "tar xzf - -C /destino/"
```

### tar + find

```bash
find /var/log -name "*.log" -mtime +30 -print0 | tar czf old_logs.tar.gz --null -T -
```

### tar + wget/curl

```bash
wget -qO- https://ejemplo.com/app.tar.gz | tar xzf -
```

### tar + split

```bash
tar czf - /grande/ | split -b 100M - backup_parte_
# Restaurar: cat backup_parte_* | tar xzf -
```

---

## 💡 Uno-liners imprescindibles

```bash
# Crear tarball (el combo clásico)
tar czf backup.tar.gz /ruta/

# Ver contenido sin extraer
tar tzf archivo.tar.gz

# Extraer
tar xzf archivo.tar.gz

# Crear con xz (más compresión)
tar cJf backup.tar.xz /ruta/

# Excluir directorios problemáticos
tar czf backup.tar.gz --exclude='node_modules' --exclude='.git' --exclude='*.log' /var/www/

# Extraer en directorio específico sin el path original
tar xzf archivo.tar.gz --strip-components=2 -C /opt/

# Transferir directorio por SSH
tar czf - /ruta/ | ssh user@host "cd /destino && tar xzf -"

# Listar solo nombres de archivo
tar tzf archivo.tar.gz | awk -F/ '{print $NF}'

# Crear desde lista de archivos
find . -name "*.conf" | tar czf configs.tar.gz -T -

# Ver tamaño total del tarball sin extraer
tar tzvf archivo.tar.gz | awk '{sum += $3} END {print sum}'
```

---

## ⚠️ Errores comunes

| Error | Causa | Solución |
|-------|-------|----------|
| `tar: Removing leading '/' from member names` | Rutas absolutas en el tarball | Usar rutas relativas o `-C` |
| `tar: directory checksum error` | Archivo corrupto o incompleto | Re-descargar o verificar con `gzip -t` |
| `gzip: stdin: unexpected end of file` | Archivo truncado | Descarga incompleta, re-descargar |
| `tar: .: Cannot open: Permission denied` | Sin permisos de lectura | Ejecutar como root o verificar permisos |
| Tamaño de tarball crece inesperadamente | Archivos sparse o compresión ineficaz | Usar `--sparse` para archivos sparse |
| Symlinks no preservados | Falta flag `h` | Agregar `-h` para seguir symlinks (empaquetar el target) |
| `tar: cowardly refusing to create an empty archive` | No hay archivos para empaquetar | Verificar que la ruta contenga archivos |
| `tar: file changed as we read it` | Archivo modificado durante el empaquetado | Normal en logs activos, advertencia no fatal |

---

## ✅ Buenas prácticas

1. **Siempre usar `f` con nombre de archivo** inmediatamente después: `tar czf archivo.tar.gz`, no `tar cfz`
2. **Preferir rutas relativas** sobre absolutas (evitar el warning de `Removing leading /`)
3. **Usar `--exclude`** para no empaquetar caches, logs activos, node_modules, .git
4. **Verificar el tarball después de crear** con `tar tzf archivo.tar.gz > /dev/null`
5. **xz para archivos fríos** (backups, distribución), **gzip para calientes** (velocidad > tamaño)
6. **Transferir por SSH sin archivo intermedio** con el pipe: `tar czf - ruta | ssh host tar xzf -`
7. **Para archivos muy grandes usar `--remove-files`** después de empaquetar (como `mv`)
8. **Nunca usar `-P` en rutas absolutas** para backup — al restaurar podrías sobrescribir archivos de sistema
9. **Probar la restauración** del backup periódicamente

---

## 🔗 Referencias internas

- [`rsync`](rsync.md) — alternativa para sincronización incremental
- [`ssh`](ssh.md) — transferencia remota de tarballs
- [`find`](find.md) — seleccionar archivos para empaquetar
- [`cron`](cron.md) — backups programados con tar
- [`scenario`](../scenarios/infrastructure/03-disaster-recovery.md) — restauración desde tarballs de backup
