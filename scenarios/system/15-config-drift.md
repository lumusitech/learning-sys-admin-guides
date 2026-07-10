# 🧩 Escenario: Config drift — cambios no autorizados en el servidor

**Dominio:** system
**Nivel:** 🟡 Intermedio
**Herramientas:** `find`, `stat`, `diff`, `git`, `awk`
**Archivos:** `labs/docker-compose.broken.yml`

---

## 🎯 Problema

Un servicio que funcionaba correctamente ayer dejó de responder esta mañana. No hubo deploy ni cambio planificado. Al inspeccionar, encontrás que `/etc/nginx/nginx.conf` fue modificado anoche y que varios archivos en `/etc/` tienen timestamps recientes sin explicación. Necesitás detectar qué cambió, cuándo, y si fue un cambio autorizado o un incidente de seguridad.

---

## ⚡ Quick command (SRE)

```bash
find /etc -type f -mtime -1 -exec stat -c "%y %n" {} \; | sort -r
```

---

## ✅ Salida esperada

```text
2026-07-10 02:15:33 /etc/nginx/nginx.conf
2026-07-10 02:15:28 /etc/ssh/sshd_config
2026-07-10 02:14:51 /etc/apt/sources.list
2026-07-10 01:30:00 /etc/cron.d/backup
```

Interpretación:

- Múltiples archivos modificados en la misma ventana (2:14-2:15 AM) → cambio deliberado o automatizado
- `/etc/ssh/sshd_config` modificado a las 2 AM → sospechoso (no es horario de mantención típico)
- `/etc/apt/sources.list` cambiado → posible adición de repositorio malicioso
- Si no hay registro de cambio planificado, es config drift no autorizado

---

## 🧠 Diagnóstico

Config drift es cuando la configuración real del sistema se desvía de la configuración esperada. Puede ser:

- **Accidental**: alguien hizo un cambio rápido para debuggear y no documentó
- **Automatizado**: un script o paquete que modifica configs sin avisar
- **Malicioso**: un atacante modificando configuraciones para persistencia

El diagnóstico se basa en 3 preguntas: ¿qué cambió? ¿cuándo? ¿quién?

---

## 🛠️ Procedimiento (runbook)

### 1. Identificar archivos modificados recientemente

```bash
find /etc -type f -mtime -1 -ls 2>/dev/null
find /etc -type f -mtime -7 -ls 2>/dev/null | awk '{print $6, $7, $8, $NF}' | sort
```

### 2. Si el directorio está versionado con git

```bash
cd /etc && git status
cd /etc && git diff
cd /etc && git log --oneline -5
```

### 3. Comparar con backup conocido

```bash
diff /etc/nginx/nginx.conf /backup/nginx.conf
diff /etc/ssh/sshd_config /backup/sshd_config
```

### 4. Identificar quién hizo el cambio

```bash
grep -E "nginx|sshd|apt" /var/log/auth.log | grep -v "CRON"
last -20
```

### 5. Verificar integridad con checksums

```bash
md5sum /etc/nginx/nginx.conf /etc/ssh/sshd_config /etc/apt/sources.list
sha256sum /etc/passwd /etc/shadow /etc/sudoers
```

### 6. Restaurar archivos modificados

```bash
cp /backup/nginx.conf /etc/nginx/nginx.conf
cp /backup/sshd_config /etc/ssh/sshd_config
systemctl reload nginx sshd
```

---

## 🧯 Mitigación

Verificar:

```bash
stat /etc/nginx/nginx.conf /etc/ssh/sshd_config
```

Acción:

- Restaurar config desde backup
- Si es malicioso: cambiar contraseñas, revisar accesos SSH
- Versionar `/etc/` con git para detección futura

Rollback:

- Revertir al último commit conocido en el repo git de /etc/
- Si no hay git, restaurar desde tarball de backup

---

## ✅ Interpretación

El config drift es la causa más común de "funcionaba ayer y hoy no". Sin versionamiento de configuraciones, diagnosticar qué cambió requiere comparación manual de cada archivo sospechoso.

La solución definitiva es versionar `/etc/` con git: cada cambio queda registrado con timestamp, autor y diff. Con `git diff` resolvés en 5 segundos lo que sin git te lleva 30 minutos de `stat` y `diff` manual.

---

## 🐧 Variante Alpine (OpenRC)

```bash
# Alpine usa archivos de log en /var/log/messages
grep "nginx\|sshd" /var/log/messages | tail -20

# No tiene systemctl, usar rc-service
rc-service nginx reload
rc-service sshd reload

# md5sum no siempre está, usar openssl
openssl dgst -md5 /etc/nginx/nginx.conf
```

---

## 🔗 Referencias

- [`find`](../../guides/find.md) — búsqueda por fecha de modificación
- [`stat`](../../guides/stat.md) — metadatos precisos de archivos
- [`diff`](../../guides/cut.md) — comparación de archivos
- [`grep`](../../guides/grep.md) — filtrado de logs
- [`scenario`](../security/01-detect-and-block-malicious-ips.md) — detectar IPs de atacantes
- [`scenario`](../security/07-privilege-escalation-attempt.md) — si el drift es malicioso
