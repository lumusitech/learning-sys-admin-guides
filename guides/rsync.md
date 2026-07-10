# rsync — Guía completa de sincronización y backup

**Nivel:** 🟡 Intermedio
**Archivos de práctica:** `labs/docker-compose.integrative.yml`
**Ver escenarios relacionados:** [`infrastructure/03-disaster-recovery`](../scenarios/infrastructure/03-disaster-recovery.md)

---

## ⚡ Quick command

`rsync -avz origen/ destino/`

> ⚠️ Para transfers remotos, rsync debe estar instalado en ambos lados. En Alpine: `apk add rsync`.

---

## ⚡ Quick run

```bash
rsync -avh --progress /var/log/ user@backup-server:/backups/logs/
```

---

## 📑 Índice

1. [¿Qué es rsync?](#qué-es-rsync)
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

## 🧠 ¿Qué es rsync?

rsync es una herramienta de sincronización de archivos y directorios. Su característica principal es la **transferencia delta**: solo envía las diferencias (deltas) entre origen y destino, no los archivos completos.

Esto lo hace mucho más eficiente que `scp` o `cp` para backups incrementales, mirroring y sincronización remota. Detecta qué archivos cambiaron y transfiere solo esos cambios.

---

## 🧠 Modelo mental

Pensá en rsync como **`cp` con inteligencia**. Donde `cp -r` copia todo de nuevo cada vez (incluso lo que no cambió), rsync analiza ambos lados y solo transfiere lo que realmente cambió.

Es como hacer `diff` entre dos directorios y aplicar solo los parches necesarios, en vez de reenviar todo el contenido.

---

## 📝 Sintaxis básica

```text
rsync [opciones] origen destino
```

| Variante | Ejemplo |
|----------|---------|
| Local → local | `rsync -av /opt/app/ /backup/app/` |
| Local → remoto | `rsync -av /opt/app/ user@server:/opt/app/` |
| Remoto → local | `rsync -av user@server:/opt/app/ /backup/app/` |
| Remoto → remoto | `rsync -av host1:/data/ host2:/data/` |

> ⚠️ La barra final `/` en el origen cambia el comportamiento: `dir/` copia el contenido de dir; `dir` copia el directorio dir entero.

---

## 🔑 Salida clave

```text
sending incremental file list
./
access.log
error.log
auth.log
          1234 100%    0.00kB/s    0:00:00 (xfr#1, to-chk=5/7)
          5678 100%    5.43MB/s    0:00:00 (xfr#2, to-chk=4/7)

sent 8901 bytes  received 123 bytes  18048.00 bytes/sec
total size is 12.45M  speedup is 1379.34
```

| Elemento | Significado |
|----------|-------------|
| `sending incremental file list` | Detectando cambios |
| `to-chk=5/7` | 5 archivos por verificar de 7 totales |
| `xfr#1` | Transferencia #1 |
| `speedup` | Cuánto más rápido fue que copia completa (delta efficiency) |

---

## 🎛️ Opciones principales

### Flags combinados comunes

| Combo | Significado |
|-------|-------------|
| `-avz` | Archive + verbose + compress (el combo clásico) |
| `-avh` | Archive + verbose + human-readable |
| `-av --delete` | Sincronización exacta: borra en destino lo que no está en origen |
| `-avP` | Archive + verbose + partial + progress |
| `-avn` | Dry run: mostrar qué haría sin hacerlo |

### Flags individuales

| Flag | Significado |
|------|-------------|
| `-a` | Archive mode: preserva permisos, timestamps, symlinks, etc. |
| `-v` | Verbose: muestra archivos transferidos |
| `-z` | Compress durante la transferencia |
| `-h` | Human-readable sizes |
| `-P` | --partial --progress: resume transferencias interrumpidas |
| `-n` | Dry run: no transfiere nada, solo muestra qué haría |
| `--delete` | Borra archivos en destino que no existen en origen |
| `-e ssh` | Usar SSH como transporte (implícito con host remoto) |
| `--exclude` | Excluir archivos/directorios por patrón |
| `--include` | Incluir archivos específicos dentro de exclusiones |
| `--max-size` | Limitar tamaño máximo de archivo |
| `--bwlimit` | Limitar ancho de banda (KB/s) |
| `--remove-source-files` | Borrar archivos origen después de transferirlos |

---

## 📋 Patrones de uso

### Backup incremental de un directorio

```bash
rsync -avh --delete /var/www/ /backup/www/
```

### Sincronizar con servidor remoto vía SSH

```bash
rsync -avz -e "ssh -p 2222" /opt/app/ admin@backup-server:/opt/app/
```

### Excluir archivos y directorios

```bash
rsync -av --exclude='*.log' --exclude='node_modules/' --exclude='.git/' src/ dest/
```

### Sincronización exacta (mirror)

```bash
rsync -av --delete src/ dest/
# ¡CUIDADO! --delete borra archivos en destino
```

### Mostrar qué se transferiría (dry run)

```bash
rsync -avn --delete src/ dest/
```

### Limitar ancho de banda (para no saturar la red)

```bash
rsync -av --bwlimit=1000 src/ user@server:dest/
```

### Transferir archivos grandes con resume

```bash
rsync -avP archivo_grande.iso user@server:/backups/
```

---

## 🔍 Uso en troubleshooting

### "El backup crontab no está funcionando"

```bash
rsync -avn /origen/ /destino/
```

Verificar en dry run qué archivos se detectan como diferentes. Si no hay nada, el backup ya está sincronizado.

### "No hay suficiente espacio en disco"

```bash
rsync -avn --stats /origen/ /destino/ | grep "Total file size"
```

Comparar el tamaño total necesario con el espacio disponible en destino.

### "El archivo no se transfiere aunque cambió"

```bash
rsync -av --checksum /origen/ /destino/
```

Por defecto rsync usa tamaño + timestamp para detectar cambios. Si el archivo cambió de contenido pero no de tamaño ni timestamp, usar `--checksum`.

---

## 🛠️ Combinación con otras herramientas

### rsync + ssh

```bash
rsync -avz -e "ssh -i ~/.ssh/backup_key" /data/ backup@nas:/data/
```

### rsync + find

```bash
# Solo archivos modificados en los últimos 7 días
find /var/www -type f -mtime -7 -print0 | rsync -av --files-from=- --from0 / backup@nas:/backup/
```

### rsync + cron

```bash
# Backup diario a las 2 AM
0 2 * * * rsync -av --delete /var/www/ /backup/www/ >> /var/log/rsync.log 2>&1
```

---

## 💡 Uno-liners imprescindibles

```bash
# Backup local con espejo exacto
rsync -avh --delete /origen/ /destino/

# Backup remoto comprimido
rsync -avz /origen/ user@backup:/destino/

# Dry run para ver qué se transferiría
rsync -avn --delete /origen/ /destino/

# Sincronizar excluyendo logs y caches
rsync -av --exclude='*.log' --exclude='cache/' --exclude='tmp/' src/ dest/

# Transferir con resume y barra de progreso
rsync -avP archivo_grande user@server:/destino/

# Forzar resincronización por checksum (ignorar timestamp)
rsync -avc /origen/ /destino/

# Limitar velocidad para no saturar red
rsync -av --bwlimit=5000 /origen/ user@server:/destino/

# Backup con compresión y exclusiones
rsync -avz --delete --exclude='.git/' --exclude='*.log' /var/www/ /backup/www/

# Ver estadísticas de la transferencia
rsync -avh --stats src/ dest/ | tail -10

# Borrar del origen después de transferir (mover)
rsync -av --remove-source-files /tmp/uploads/ /var/uploads/
```

---

## ⚠️ Errores comunes

| Error | Causa | Solución |
|-------|-------|----------|
| `rsync: command not found` | rsync no instalado en remoto | `apt install rsync` en ambos lados |
| `Permission denied (publickey)` | SSH key no configurada | `ssh-copy-id user@host` o usar `-e "ssh -i key"` |
| `No space left on device` | Disco lleno en destino | `df -h` en destino antes de transferir |
| Archivos no transferidos | Permisos incorrectos o timestamp no cambió | `--checksum` o verificar permisos |
| `@ERROR: chroot failed` | rsync daemon mal configurado | Revisar `/etc/rsyncd.conf` |
| Transferencia lenta sin razón | Red lenta o CPU saturada | Probar `-z` (compresión) o `--bwlimit` |
| `rsync error: some files could not be transferred` | Archivos cambiaron durante la transferencia | Re-ejecutar (idempotente) |
| `--delete` borró archivos que quería conservar | Sincronización inversa involuntaria | Siempre hacer dry run con `-n` primero |

---

## ✅ Buenas prácticas

1. **Siempre dry run primero** con `-n` antes de `--delete`
2. **Usar `-a` (archive)** para preservar permisos, timestamps y estructura
3. **Usar `-P`** para transfers grandes (resume si se interrumpe)
4. **Usar `--exclude`** para no transferir archivos temporales, caches, node_modules
5. **Loggear siempre** las transferencias: `>> /var/log/rsync.log 2>&1`
6. **Monitorear el espacio en disco** del destino antes y después
7. **Probar la restauración** periódicamente: un backup que no se restaura no es backup
8. **Usar `--checksum`** para datos críticos (no confiar solo en timestamp y tamaño)
9. **Sincronizar la misma dirección siempre**: origen → destino, no bidireccional
10. **Considerar `rclone`** para backups a cloud (S3, GCS, etc.) como complemento a rsync

---

## 🔗 Referencias internas

- [`storage_backup`](storage_backup.md) — estrategias de backup (NFS, restic, 3-2-1)
- [`ssh`](ssh.md) — transporte seguro para rsync remoto
- [`cron`](cron.md) — programar backups automáticos con rsync
- [`find`](find.md) — seleccionar archivos para rsync
- [`scenario`](../scenarios/infrastructure/03-disaster-recovery.md) — recuperación con backups
- [`scenario`](../scenarios/infrastructure/01-migrate-to-production.md) — migración de archivos con rsync
