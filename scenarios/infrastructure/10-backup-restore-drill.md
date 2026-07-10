# 🧩 Escenario: Verificar restauración de backup — drill programado

**Dominio:** infrastructure
**Nivel:** 🟡 Intermedio
**Herramientas:** `rsync`, `tar`, `diff`, `find`, `du`
**Archivos:** `labs/docker-compose.integrative.yml`, `labs/docker-compose.broken.yml`

---

## 🎯 Problema

El backup diario se ejecuta sin errores desde hace 6 meses, pero nunca se ha verificado una restauración real. Un backup que no se restaura no es un backup — es una ilusión de seguridad. Necesitás ejecutar un drill de restauración completo para verificar que los datos se pueden recuperar.

---

## ⚡ Quick command (SRE)

```bash
tar tzf /backups/daily-$(date +%Y%m%d).tar.gz && du -sh /backups/daily-$(date +%Y%m%d).tar.gz
```

---

## ✅ Salida esperada

```text
var/www/index.html
var/www/config.php
var/www/uploads/
...
2.3G    /backups/daily-20260710.tar.gz
```

Interpretación:

- El tarball se puede leer (no está corrupto) → la compresión funcionó
- Los archivos esperados están en el listado → el backup incluye lo que debería
- Tamaño similar al backup anterior → no hubo pérdida de datos

---

## 🧠 Diagnóstico

Los backups fallan silenciosamente. Los modos de falla más comunes:

- Backup se crea con 0 bytes (permiso de escritura, disco lleno)
- Backup incluye archivos equivocados (ruta mal especificada)
- Backup está corrupto (compresión falló a mitad de camino)
- Backup no incluye archivos nuevos (exclusión mal configurada)
- Restauración funciona pero los datos están obsoletos (último backup fue hace días)

Un drill de restauración completo valida el pipeline entero: backup → almacenamiento → restauración → verificación.

---

## 🛠️ Procedimiento (runbook)

### 1. Verificar que el backup más reciente existe y tiene tamaño

```bash
ls -lth /backups/daily-*.tar.gz | head -3
gzip -t /backups/daily-$(date +%Y%m%d).tar.gz && echo "OK" || echo "CORRUPT"
```

### 2. Verificar el contenido del backup

```bash
tar tzf /backups/daily-$(date +%Y%m%d).tar.gz | head -20
tar tzf /backups/daily-$(date +%Y%m%d).tar.gz | wc -l   # número de archivos
```

### 3. Restaurar en un directorio temporal

```bash
mkdir -p /tmp/restore-test
tar xzf /backups/daily-$(date +%Y%m%d).tar.gz -C /tmp/restore-test/
```

### 4. Verificar integridad de la restauración

```bash
# Comparar cantidad de archivos
echo "Original: $(find /var/www -type f | wc -l)"
echo "Backup:   $(find /tmp/restore-test -type f | wc -l)"

# Comparar estructura de directorios (portable)
cd /var/www && find . -type f | sort > /tmp/orig_files.txt
cd /tmp/restore-test && find . -type f | sort > /tmp/backup_files.txt
diff /tmp/orig_files.txt /tmp/backup_files.txt
```

### 5. Verificar que archivos clave existen

```bash
for f in index.html config.php robots.txt; do
  [ -f "/tmp/restore-test/var/www/$f" ] && echo "OK: $f" || echo "MISSING: $f"
done
```

### 6. Limpiar

```bash
rm -rf /tmp/restore-test
```

---

## 🧯 Mitigación

Verificar: Si el backup está corrupto, revisar el log de la última corrida del cron.

Acción: Re-ejecutar el backup manualmente con `rsync -avz /var/www/ /backups/temp/ && tar czf /backups/daily-$(date +%Y%m%d).tar.gz /backups/temp/`.

Rollback: Si el backup se creó bien, agendar el próximo drill en 30 días.

---

## ✅ Interpretación

Un backup que nunca se restaura es como un extintor que nunca se probó. El día que lo necesitás, no sabés si funciona.

El drill de restauración confirma que:

- El archivo de backup no está corrupto
- Los archivos esperados están incluidos
- El tamaño es consistente con el origen
- El proceso de extracción funciona

Un sysadmin profesional agenda drills de restauración con la misma periodicidad que los backups. Sin verificación, la confianza en el backup es fe — no ingeniería.

---

## 🐧 Variante Alpine (OpenRC)

```bash
# Alpine usa crond en vez de cron.service
rc-service crond status
cat /var/log/messages | grep backup

# gzip en vez de tar.gz integrity check
gzip -t /backups/daily.tar.gz

# En Alpine, el sistema de archivos puede no tener diff con process substitution
# Alternativa:
cd /var/www && find . -type f | sort > /tmp/orig_files.txt
cd /tmp/restore-test && find . -type f | sort > /tmp/backup_files.txt
diff /tmp/orig_files.txt /tmp/backup_files.txt
```

---

## 🔗 Referencias

- [`rsync`](../../guides/rsync.md) — creación de backups incrementales
- [`tar`](../../guides/tar.md) — archivado y compresión
- [`find`](../../guides/find.md) — verificación de archivos
- [`du`](../../guides/du.md) — comparación de tamaños
- [`cron`](../../guides/cron.md) — programación de backups y drills
- [`scenario`](03-disaster-recovery.md) — recuperación desde backup en emergencia
