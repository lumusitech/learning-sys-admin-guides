# 🧩 Escenario: Claves SSH no autorizadas — auditoría de accesos

**Dominio:** security
**Nivel:** 🟡 Intermedio
**Herramientas:** `ssh-keygen`, `diff`, `find`, `grep`, `auditd`
**Archivos:** Sistema en vivo

---

## 🎯 Problema

Durante una auditoría de seguridad se descubre que hay claves SSH en `authorized_keys` de usuarios que no fueron autorizadas por el equipo de operación. Un ex-empleado, un contractor, o un atacante podría tener acceso persistente al servidor sin que nadie lo sepa. Es necesario auditar todas las claves SSH del sistema y compararlas con las claves conocidas y autorizadas.

---

## ⚡ Quick command (SRE)

```bash
find /home -name "authorized_keys" -exec sh -c 'echo "=== {} ==="; cat {}' \;
```

---

## ✅ Salida esperada

- lista de claves públicas en `authorized_keys` de cada usuario
- cada clave muestra tipo, comentario y fingerprint
- claves que no aparecen en el inventario oficial → acceso no autorizado
- claves de usuarios que no deberían tener SSH → posible intrusión

Interpretación:

- clave con comentario de ex-empleado → acceso no revocado
- clave sin comentario o con comentario genérico → sospechosa, requiere investigación
- clave de herramienta de automatización conocida → probablemente legítima
- clave en usuario que no debería tener SSH (ej: `www-data`) → posible backdoor

---

## 🧠 Diagnóstico

Las claves SSH son acceso persistente. A diferencia de las passwords, no expiran por defecto y no se revocan automáticamente cuando un empleado se va. Un atacante que obtiene acceso a un servidor puede agregar su clave a `authorized_keys` y mantener acceso incluso después de que se cierre la vulnerabilidad original.

Patrones clave:

- clave desconocida en `authorized_keys` → acceso no autorizado
- clave de ex-empleado → acceso no revocado tras despido
- clave en usuario de servicio (www-data, nginx) → posible backdoor
- clave agregada recientemente → investigar quién y cuándo
- múltiples claves en usuario que debería tener solo una → exceso de accesos

👉 Toda clave SSH en el sistema debe estar documentada y asociada a una persona o servicio conocido.

---

## 🛠️ Procedimiento (runbook)

### 1. Listar todos los authorized_keys del sistema

```bash
find /home /root -name "authorized_keys" 2>/dev/null
```

### 2. Mostrar las claves con su fingerprint

```bash
find /home /root -name "authorized_keys" -exec sh -c '
  echo "=== {} ===";
  while IFS= read -r key; do
    echo "$key" | ssh-keygen -lf - 2>/dev/null || echo "Clave inválida: $key"
  done < "{}"
' \;
```

### 3. Comparar con el inventario oficial

```bash
# Si existe un archivo de claves autorizadas:
diff <(find /home -name "authorized_keys" -exec cat {} \; | sort) /ruta/inventario-claves.txt
```

### 4. Verificar permisos de .ssh y authorized_keys

```bash
find /home -name ".ssh" -exec ls -ld {} \;
find /home -name "authorized_keys" -exec ls -l {} \;
```

### 5. Revisar logs de acceso SSH recientes

```bash
grep "Accepted publickey" /var/log/auth.log | tail -20
# o con journalctl:
journalctl -u ssh --since "30 days ago" | grep "Accepted publickey"
```

---

## 🧯 Mitigación

Si se confirma una clave no autorizada:

Verificar:

```bash
find /home -name "authorized_keys" -exec sh -c 'echo "=== {} ==="; cat {}' \;
```

Acción:

```bash
# Eliminar la clave no autorizada del archivo authorized_keys
# Identificar la línea exacta primero:
grep -n "ssh-rsa AAAA..." /home/usuario/.ssh/authorized_keys

# Eliminar la línea (ejemplo: línea 3)
sed -i '3d' /home/usuario/.ssh/authorized_keys
```

Mitigación adicional:

```bash
# Corregir permisos si están mal
chmod 700 /home/usuario/.ssh
chmod 600 /home/usuario/.ssh/authorized_keys
chown -R usuario:usuario /home/usuario/.ssh

# Auditar claves de todos los usuarios
for user in $(cut -d: -f1 /etc/passwd); do
  home=$(eval echo ~$user)
  if [ -f "$home/.ssh/authorized_keys" ]; then
    echo "=== $user ==="
    cat "$home/.ssh/authorized_keys"
  fi
done
```

Rollback:

```bash
# Si se eliminó una clave por error, restaurar desde backup
cp /backup/authorized_keys /home/usuario/.ssh/authorized_keys
chmod 600 /home/usuario/.ssh/authorized_keys
```

Casos comunes:

- ex-empleado con clave no revocada → agregar proceso de offboarding
- contractor con acceso temporal que se hizo permanente → establecer fechas de expiración
- herramienta de automatización con clave compartida → usar cuentas de servicio dedicadas
- atacante que agregó backdoor → investigar cómo obtuvo acceso inicial

---

## ✅ Interpretación

- todas las claves están en el inventario → acceso controlado
- se encontró clave no autorizada → eliminar y investigar origen
- clave en usuario de servicio → probable backdoor, investigar
- permisos incorrectos en .ssh → corregir inmediatamente
- muchas claves sin comentario → establecer convención de nombres

---

## 🐧 Variante Alpine (OpenRC)

> Este escenario no usa `systemctl`, `journalctl`, `apt` ni `ufw`. No requiere variante Alpine.

---

## 🔗 Referencias

- [`ssh`](../../guides/ssh.md) — configuración y hardening SSH
- [`find`](../../guides/find.md) — búsqueda de archivos
- [`grep`](../../guides/grep.md) — filtrado de logs
- [`scenarios/security/01-detect-and-block-malicious-ips.md`](01-detect-and-block-malicious-ips.md) — detección de IPs maliciosas
- [`scenarios/security/02-suid-audit-and-file-permissions.md`](02-suid-audit-and-file-permissions.md) — auditoría de permisos
