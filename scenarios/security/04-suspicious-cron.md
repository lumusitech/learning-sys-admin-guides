# 🧩 Escenario: Entrada cron sospechosa — persistencia maliciosa

**Dominio:** security
**Nivel:** 🔴 Avanzado
**Herramientas:** `crontab`, `ls`, `md5sum`, `diff`, `find`
**Archivos:** Sistema en vivo

---

## 🎯 Problema

Durante una auditoría de seguridad o respuesta a incidentes, se descubre una entrada cron que ejecuta un script o comando sospechoso. La entrada puede haber sido agregada por un atacante que obtuvo acceso temporal y quiere mantener persistencia, o por un usuario malintencionado. El cron se ejecuta periódicamente sin que nadie lo note, ejecutando código malicioso de forma silenciosa.

---

## ⚡ Quick command (SRE)

```bash
for user in $(cut -d: -f1 /etc/passwd); do crontab -l -u "$user" 2>/dev/null | grep -v "^#" | grep -v "^$" && echo "  ^^^ ($user)"; done
```

---

## ✅ Salida esperada

- lista de entradas cron activas por usuario
- entradas que ejecutan scripts en ubicaciones inusuales (`/tmp`, `/dev/shm`, `/var/tmp`)
- entradas que descargan y ejecutan código de internet (`curl`, `wget`, `bash`)
- entradas con ofuscación (base64, eval, variables encadenadas)
- entradas que eliminan logs o evidencia

Interpretación:

- cron ejecutando script desde `/tmp` o `/dev/shm` → altamente sospechoso
- cron con `curl | bash` → descarga y ejecuta código remoto
- cron con `base64 -d` → posible ofuscación de payload
- cron que borra `/var/log/` → intento de destruir evidencia
- cron de usuario que no debería tener cron → acceso no autorizado

---

## 🧠 Diagnóstico

Las entradas cron son un método clásico de persistencia para atacantes. Una vez que obtienen acceso al sistema, agregan una entrada cron que se ejecuta periódicamente (cada minuto, hora o día) para mantener su acceso, descargar actualizaciones del malware, o exfiltrar datos.

Patrones clave:

- script en `/tmp`, `/dev/shm`, `/var/tmp` → ubicaciones temporales, altamente sospechoso
- `curl` o `wget` seguido de `bash` o `sh` → descarga y ejecución remota
- `base64 -d` → posible payload ofuscado
- `rm -rf /var/log` o `>` de archivos de log → destrucción de evidencia
- entrada sin comentario o con comentario genérico → difícil de atribuir
- cron de usuario www-data, nginx, o similar → posible explotación de web app

👉 Toda entrada cron debe estar documentada y asociada a un proceso o persona conocida.

---

## 🛠️ Procedimiento (runbook)

### 1. Listar todas las entradas cron del sistema

```bash
# Crontabs de usuarios
for user in $(cut -d: -f1 /etc/passwd); do
  crontab -l -u "$user" 2>/dev/null | grep -v "^#" | grep -v "^$" && echo "  ^^^ ($user)"
done

# Crontabs del sistema
cat /etc/crontab
ls -la /etc/cron.d/
ls -la /etc/cron.daily/
ls -la /etc/cron.hourly/
```

### 2. Buscar entradas que ejecutan scripts

```bash
for user in $(cut -d: -f1 /etc/passwd); do
  crontab -l -u "$user" 2>/dev/null | grep -E "^\S+\s+\S+\s+\S+\s+\S+\s+\S+" | while read -r line; do
    script=$(echo "$line" | awk '{print $NF}')
    if [ -f "$script" ]; then
      echo "=== $user: $line ==="
      md5sum "$script"
      file "$script"
      head -5 "$script"
    fi
  done
done
```

### 3. Verificar los scripts ejecutados por cron

```bash
# Para cada script sospechoso:
ls -la /ruta/al/script
md5sum /ruta/al/script
file /ruta/al/script
cat /ruta/al/script
```

### 4. Buscar entradas con descarga remota

```bash
grep -rE "curl|wget|nc|bash|python|perl" /var/spool/cron/crontabs/ /etc/crontab /etc/cron.d/ 2>/dev/null
```

### 5. Revisar logs de cron recientes

```bash
grep CRON /var/log/syslog | tail -30
# o con journalctl:
journalctl -u cron --since "7 days ago" | tail -30
```

---

## 🧯 Mitigación

Si se confirma una entrada cron sospechosa:

Verificar:

```bash
crontab -l -u <usuario_sospechoso>
cat /ruta/al/script_sospechoso
```

Acción:

```bash
# Eliminar la entrada cron sospechosa
crontab -l -u <usuario> | grep -v "comando_sospechoso" | crontab -u <usuario> -

# O editar directamente
crontab -e -u <usuario>
```

Mitigación adicional:

```bash
# Eliminar el script malicioso
rm -f /ruta/al/script_sospechoso

# Verificar que no hay otros mecanismos de persistencia
find /etc/cron.d /etc/cron.daily /etc/cron.hourly -type f -exec grep -l "sospechoso" {} \;

# Revisar systemd timers como alternativa de persistencia
systemctl list-timers --all

# Cambiar passwords y revocar claves SSH si hubo intrusión
passwd <usuario>
```

Rollback:

```bash
# Si se eliminó una entrada legítima por error
# Restaurar desde backup o recrear manualmente
crontab -e -u <usuario>
```

Casos comunes:

- atacante con reverse shell periódico → cron ejecuta `nc -e /bin/bash`
- crypto miner que se reinstala → cron descarga y ejecuta minerd
- exfiltración de datos → cron envía datos a servidor externo
- limpieza de evidencia → cron borra logs periódicamente

---

## ✅ Interpretación

- la entrada se elimina y no reaparece → el atacante solo tenía acceso al crontab
- la entrada reaparece tras eliminación → hay otro mecanismo de persistencia (systemd timer, script de inicio, otro cron)
- el script descarga código remoto → investigar el servidor C2 y bloquearlo
- el usuario no tenía conocimiento de la entrada → probablemente un atacante la agregó

---

## 🐧 Variante Alpine (OpenRC)

> Este escenario no usa `systemctl`, `journalctl`, `apt` ni `ufw`. No requiere variante Alpine.

---

## 🔗 Referencias

- [`find`](../../guides/find.md) — búsqueda de archivos
- [`grep`](../../guides/grep.md) — filtrado de contenido
- [`scenarios/security/02-suid-audit-and-file-permissions.md`](02-suid-audit-and-file-permissions.md) — auditoría de permisos
- [`scenarios/security/03-unauthorized-ssh-keys.md`](03-unauthorized-ssh-keys.md) — auditoría de claves SSH
- [`scenarios/system/11-cron-failure.md`](../system/11-cron-failure.md) — fallos de cron (perspectiva diferente)
