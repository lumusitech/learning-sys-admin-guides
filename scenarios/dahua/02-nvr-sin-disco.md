# 🧩 Escenario: NVR Dahua no detecta disco

**Dominio:** infrastructure
**Nivel:** 🔴 Avanzado
**Herramientas:** `ssh`, `df`, `lsblk`, `smartctl`, `dmesg`
**Archivos:** N/A (diagnóstico en vivo)

---

## 🎯 Problema

Un NVR Dahua arranca correctamente pero no detecta el disco duro. La interfaz web muestra "No HDD" o "Disk Error". No se pueden guardar grabaciones.

---

## ⚡ Quick command (SRE)

```bash
ssh admin@192.168.100.100 "df -h && lsblk && dmesg | grep -i 'sda\|error' | tail -20"
```

---

## ✅ Salida esperada

```text
Filesystem      Size  Used Avail Use% Mounted on
/dev/root        15G  8.2G  5.8G  59% /
/dev/mmcblk0p1  100M   20M   80M  20% /boot

NAME         MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda            8:0    0  2.0T  0 disk 
└─sda1         8:1    0  2.0T  0 part 
mmcblk0        179:0   0  3.7G  0 disk 
└─mmcblk0p1    179:1   0  3.7G  0 part 

[    2.345678] sd 0:0:0:0: [sda] Attached SCSI disk
[    2.456789] EXT4-fs (sda1): mounted filesystem with ordered data mode
```

**Interpretación:**

- `df -h` muestra `/dev/sda1` montado → disco detectado
- `lsblk` muestra `sda` con partición → disco físicamente presente
- `dmesg` sin errores → disco saludable

---

## 🧠 Diagnóstico

### Paso 1: Verificar estado del disco

```bash
# SSH al NVR
ssh admin@192.168.100.100

# Ver uso de disco
df -h

# Ver dispositivos de bloque
lsblk

# Ver mensajes del kernel sobre discos
dmesg | grep -i "sda\|ata\|error" | tail -30
```

**Patrones clave:**

- `df -h` no muestra `/dev/sda` → disco no montado o no detectado
- `lsblk` no muestra `sda` → disco físicamente no detectado
- `dmesg` muestra errores I/O → disco defectuoso
- `dmesg` muestra "resetting link" → problema de conexión SATA

### Paso 2: Verificar SMART status

```bash
# Ver información SMART
smartctl -a /dev/sda

# Ver salud del disco
smartctl -H /dev/sda

# Ver errores registrados
smartctl -l error /dev/sda
```

**Patrones clave:**

- `SMART overall-health self-assessment test result: PASSED` → disco saludable
- `FAILED` → disco defectuoso, reemplazar inmediatamente
- `Reallocated_Sector_Ct` > 0 → sectores dañados
- `Current_Pending_Sector` > 0 → sectores pendientes de reasignación

### Paso 3: Verificar conexión física

```bash
# Ver información del enlace SATA
dmesg | grep -i "ata\|link\|sata"

# Ver velocidad del enlace
cat /sys/block/sda/device/queue_depth
```

**Patrones clave:**

- `link is slow to respond` → cable SATA defectuoso
- `failed to IDENTIFY` → disco no responde
- `ATA link down` → cable desconectado o defectuoso

---

## 🛠️ Procedimiento (runbook)

### 1. Verificar que el disco está físicamente conectado

```bash
# SSH al NVR
ssh admin@192.168.100.100

# Ver dispositivos de bloque
lsblk

# Si no aparece sda:
# - Apagar NVR
# - Verificar cable SATA conectado
# - Verificar cable de energía del disco
# - Encender NVR
```

### 2. Verificar montaje del disco

```bash
# Ver si el disco está montado
df -h | grep sda

# Si no está montado:
mount /dev/sda1 /mnt/sda

# Verificar que se montó
df -h | grep sda
```

### 3. Verificar integridad del sistema de archivos

```bash
# Desmontar disco primero
umount /mnt/sda

# Verificar sistema de archivos
fsck /dev/sda1

# Si hay errores, reparar
fsck -y /dev/sda1

# Volver a montar
mount /dev/sda1 /mnt/sda
```

### 4. Verificar SMART status

```bash
# Ver salud del disco
smartctl -H /dev/sda

# Si muestra FAILED:
# - Backup inmediato de grabaciones
# - Reemplazar disco
# - Formatear disco nuevo
```

### 5. Formatear disco (si es necesario)

```bash
# ⚠️ ADVERTENCIA: Esto borra todos los datos
# Desmontar disco
umount /mnt/sda

# Formatear
mkfs.ext4 /dev/sda1

# Montar
mount /dev/sda1 /mnt/sda

# Verificar
df -h | grep sda
```

### 6. Reiniciar servicio de grabación

```bash
# Reiniciar servicio
/etc/init.d/record restart

# Verificar que está corriendo
ps aux | grep record

# Ver logs
tail -50 /var/log/record.log
```

---

## 🧯 Mitigación

**Verificar:**

```bash
# Diagnóstico completo
ssh admin@192.168.100.100 "df -h | grep -q sda && echo '✅ Disco montado' || echo '❌ Disco no montado'"
ssh admin@192.168.100.100 "smartctl -H /dev/sda | grep -q 'PASSED' && echo '✅ Disco saludable' || echo '⚠️ Disco con problemas'"
```

**Acción:**

```bash
# Si el disco está defectuoso:
# 1. Backup de grabaciones
rsync -av admin@192.168.100.100:/mnt/sda/record/ ./backup_record/

# 2. Apagar NVR
ssh admin@192.168.100.100 "shutdown -h now"

# 3. Reemplazar disco físicamente

# 4. Encender NVR y formatear disco nuevo
ssh admin@192.168.100.100 "mkfs.ext4 /dev/sda1 && mount /dev/sda1 /mnt/sda"
```

**Rollback:**

```bash
# Si el formateo falla, verificar conexión física:
# - Cable SATA
# - Cable de energía
# - Disco compatible con NVR

# Si el disco nuevo no funciona:
# - Verificar que el disco es compatible (capacidad máxima del NVR)
# - Probar con otro disco
```

**Casos comunes:**

- Cable SATA desconectado → reconectar cable
- Disco defectuoso → reemplazar disco
- Sistema de archivos corrupto → ejecutar fsck
- Disco no compatible → verificar especificaciones del NVR
- Firmware desactualizado → actualizar firmware del NVR

---

## ✅ Interpretación

- **Disco no aparece en lsblk** → problema físico (cable, energía, disco)
- **Disco aparece pero no monta** → sistema de archivos corrupto
- **SMART muestra FAILED** → disco defectuoso, reemplazar inmediatamente
- **Errores I/O en dmesg** → cable SATA defectuoso o disco degradado
- **Disco montado pero NVR no graba** → problema de servicio o configuración

---

## 🔗 Referencias

- [`guides/dahua/dahua-nvr-ssh.md`](../../guides/dahua/dahua-nvr-ssh.md) — SSH a NVR
- [`guides/dahua/dahua-troubleshooting.md`](../../guides/dahua/dahua-troubleshooting.md) — troubleshooting
- [`reference/dahua-cheatsheet.md`](../../reference/dahua-cheatsheet.md) — referencia rápida
