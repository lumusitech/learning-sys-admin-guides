# 🧩 Escenario: NFS stale mount — servidor NFS caído, mount colgado

**Dominio:** infrastructure
**Nivel:** 🟡 Intermedio
**Herramientas:** `mount`, `umount`, `lsof`, `df`, `showmount`
**Archivos:** Sistema en vivo

---

## 🎯 Problema

El servidor NFS se cayó o la red entre el cliente y el servidor se cortó. Los procesos que usan archivos en el mount NFS se cuelgan — los comandos `ls`, `cat`, `df` tardan mucho o no responden. Los usuarios no pueden acceder a los archivos compartidos. El sistema puede volverse inaccesible si hay procesos esperando el NFS.

---

## ⚡ Quick command (SRE)

```bash
df -h | grep nfs && mount | grep nfs
```

---

## ✅ Salida esperada

- `df` se cuelga o tarda mucho en responder → mount NFS stale
- `mount` muestra el NFS como `stale` o con opciones de timeout
- `lsof` muestra procesos esperando en I/O sobre archivos NFS
- los comandos que acceden a rutas NFS no responden → el mount está colgado

Interpretación:

- `df` se cuelga → el mount NFS está stale y el kernel está esperando respuesta
- procesos en estado `D` (uninterruptible sleep) → esperando I/O de NFS
- `showmount -e <servidor>` falla → el servidor NFS no responde
- el mount NFS muestra `hard` mount → los procesos esperarán indefinidamente

---

## 🧠 Diagnóstico

Un mount NFS se vuelve "stale" cuando el servidor NFS deja de responder. Los mounts NFS pueden ser "hard" (los procesos esperan indefinidamente) o "soft" (los procesos reciben error después de un timeout). Con mounts hard, los procesos se cuelgan y el sistema puede volverse inaccesible.

Patrones clave:

- `df` se cuelga → mount NFS stale, el kernel está esperando
- procesos en estado `D` → esperando I/O de NFS
- `showmount -e <servidor>` falla → servidor NFS caído o inaccesible
- el mount tiene opción `hard` → los procesos esperarán indefinidamente
- el mount tiene opción `soft` → los procesos recibirán error después del timeout

👉 Si `df` se cuelga y hay NFS montado, el problema es el servidor NFS.

---

## 🛠️ Procedimiento (runbook)

### 1. Verificar si hay mounts NFS activos

```bash
mount | grep nfs
```

### 2. Verificar si el servidor NFS responde

```bash
showmount -e <servidor_nfs>
ping -c 3 <servidor_nfs>
```

### 3. Ver procesos esperando en NFS

```bash
ps aux | awk '$8 ~ /D/ {print}'
```

### 4. Intentar umount forzado

```bash
umount -f /mnt/nfs
```

### 5. Si umount -f no funciona, usar umount lazy

```bash
umount -l /mnt/nfs
```

---

## 🧯 Mitigación

Si se confirma que el mount NFS está stale:

Verificar:

```bash
mount | grep nfs
showmount -e <servidor_nfs>
```

Acción:

```bash
# Desmontar forzado
umount -f /mnt/nfs

# Si no funciona, desmontar lazy (desmonta inmediatamente, limpia después)
umount -l /mnt/nfs
```

Mitigación adicional:

```bash
# Remontar el NFS cuando el servidor vuelva
mount -a

# O remontar específico
mount <servidor_nfs>:/export /mnt/nfs

# Para prevenir cuelgues futuros, usar mounts soft con timeout
# En /etc/fstab:
# servidor:/export /mnt/nfs nfs soft,timeo=10,retrans=3 0 0
```

Rollback:

```bash
# Si el umount forzado causa problemas, reiniciar el cliente NFS
systemctl restart nfs-utils
# o
systemctl restart nfs-client.target

# Remontar
mount -a
```

Casos comunes:

- servidor NFS caído → el mount se vuelve stale
- red entre cliente y servidor cortada → el mount se vuelve stale
- mount hard sin timeout → los procesos esperan indefinidamente
- mount soft con timeout muy corto → errores falsos en momentos de alta latencia
- servidor NFS reiniciado → los mounts existentes pueden necesitar remontarse

---

## ✅ Interpretación

- el umount forzado funciona y los procesos se liberan → el problema era el mount stale
- el umount forzado no funciona → usar umount lazy o reiniciar el cliente NFS
- el servidor NFS vuelve y el mount funciona tras remontar → el problema era el servidor
- los procesos siguen en estado `D` tras umount → pueden necesitar ser matados

---

## 🐧 Variante Alpine (OpenRC)

> Este escenario no usa `systemctl`, `journalctl`, `apt` ni `ufw`. No requiere variante Alpine.

---

## 🧑‍🏫 Modo docente

**Preguntas:** ¿Qué estado de proceso indica un mount NFS colgado? ¿Cómo forzás un desmontaje? ¿Qué opción de montaje previene cuelgues permanentes?

**Ejercicio:** Diagnosticar un stale mount, identificar procesos colgados con lsof, forzar umount, re-montar con opciones soft.

**Evaluación:** identificación de stale mount, desmontaje forzado exitoso, montaje con opciones soft y timeo configurado.

---

## 🔗 Referencias

- [`du`](../../guides/du.md) — uso de disco
- [`df`](../../guides/df.md) — espacio en disco
- [`lsof`](../../guides/lsof.md) — archivos abiertos
- [`scenarios/infrastructure/03-disaster-recovery.md`](03-disaster-recovery.md) — disaster recovery
- [`scenarios/system/07-high-io-wait.md`](../system/07-high-io-wait.md) — I/O wait (problema relacionado)
