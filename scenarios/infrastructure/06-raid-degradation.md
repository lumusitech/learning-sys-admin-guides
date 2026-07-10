# 🧩 Escenario: RAID degradado — disco fallado, detectar y reconstruir

**Dominio:** infrastructure
**Nivel:** 🔴 Avanzado
**Herramientas:** `cat /proc/mdstat`, `mdadm`, `smartctl`, `dmesg`
**Archivos:** Sistema en vivo

---

## 🎯 Problema

El sistema operativo o los logs muestran que un disco del array RAID falló. El RAID está degradado — funciona pero sin redundancia. Si otro disco falla antes de la reconstrucción, se perderán todos los datos. Es necesario identificar el disco fallado, reemplazarlo físicamente y reconstruir el array.

---

## ⚡ Quick command (SRE)

```bash
cat /proc/mdstat
```

---

## ✅ Salida esperada

- `mdstat` muestra `[UU_]` o `[_UU]` → un disco falló, RAID degradado
- `mdstat` muestra `recovery` o `resync` → reconstrucción en progreso
- `dmesg` muestra errores I/O del disco → disco con sectores defectuosos
- `smartctl` muestra errores en el disco → disco con problemas de hardware

Interpretación:

- `[UU_]` → el tercer disco del array falló
- `recovery` activo → la reconstrucción está en progreso
- `dmesg` con errores I/O → el disco tiene sectores defectuosos o está fallando
- `smartctl` con errores → el disco tiene problemas de hardware detectados por SMART

---

## 🧠 Diagnóstico

Un RAID degradado significa que uno o más discos fallaron pero el array sigue funcionando con los discos restantes. La redundancia se perdió — si otro disco falla antes de la reconstrucción, se perderán los datos.

Patrones clave:

- `[UU_]` → un disco falló, RAID degradado
- `recovery` activo → la reconstrucción está en progreso
- `dmesg` con errores I/O → el disco tiene sectores defectuosos
- `smartctl` con errores → el disco tiene problemas de hardware
- múltiples discos fallados → posible pérdida de datos si no hay backup

👉 Si el RAID está degradado, lo primero es identificar el disco fallado y reemplazarlo.

---

## 🛠️ Procedimiento (runbook)

### 1. Verificar el estado del RAID

```bash
cat /proc/mdstat
```

### 2. Identificar el disco fallado

```bash
mdadm --detail /dev/md0
```

### 3. Verificar la salud del disco con SMART

```bash
smartctl -a /dev/sdX
```

### 4. Ver errores de disco en el kernel

```bash
dmesg | grep -i "error\|fail\|bad\|sector" | tail -20
```

### 5. Marcar el disco como fallido y eliminarlo del array

```bash
mdadm --fail /dev/md0 /dev/sdX1
mdadm --remove /dev/md0 /dev/sdX1
```

---

## 🧯 Mitigación

Si se confirma que el RAID está degradado:

Verificar:

```bash
cat /proc/mdstat
mdadm --detail /dev/md0
```

Acción:

```bash
# Marcar el disco fallido (si no se marcó automáticamente)
mdadm --fail /dev/md0 /dev/sdX1

# Eliminar el disco fallido del array
mdadm --remove /dev/md0 /dev/sdX1

# Después de reemplazar físicamente el disco:
# Agregar el nuevo disco al array
mdadm --add /dev/md0 /dev/sdY1

# La reconstrucción comenzará automáticamente
# Monitorear el progreso:
watch cat /proc/mdstat
```

Mitigación adicional:

```bash
# Verificar que la reconstrucción está en progreso
cat /proc/mdstat

# Verificar la velocidad de reconstrucción
mdadm --detail /dev/md0 | grep -i "rebuild\|resync"

# Verificar que no hay más discos con problemas
for disk in /dev/sd?; do
  smartctl -H "$disk" 2>/dev/null | grep -i "result"
done
```

Rollback:

```bash
# Si la reconstrucción falla, se puede intentar detener y reiniciar
mdadm --stop /dev/md0
mdadm --assemble --scan

# Si hay múltiples discos fallados, puede ser necesario restaurar desde backup
```

Casos comunes:

- disco con sectores defectuosos → reemplazar antes de que falle completamente
- disco con errores SMART → reemplazar preventivamente
- múltiples discos fallados → posible pérdida de datos, restaurar desde backup
- reconstrucción lenta → verificar que no hay I/O excesivo en el sistema

---

## ✅ Interpretación

- la reconstrucción completa exitosamente → el RAID vuelve a tener redundancia
- la reconstrucción falla → el nuevo disco puede estar defectuoso o hay más discos con problemas
- el disco fallado se reemplaza y la reconstrucción comienza → el problema se resolvió
- múltiples discos fallados → posible pérdida de datos, restaurar desde backup

---

## 🐧 Variante Alpine (OpenRC)

> Este escenario no usa `systemctl`, `journalctl`, `apt` ni `ufw`. No requiere variante Alpine.

---

## 🧑‍🏫 Modo docente

**Preguntas:** ¿Qué indica [UU_] en /proc/mdstat? ¿Cómo identificás el disco fallado? ¿Cómo iniciás la reconstrucción del array?

**Ejercicio:** Detectar RAID degradado en mdstat, identificar disco fallado con smartctl, marcar fallido y agregar reemplazo.

**Evaluación:** detección correcta de degradación, identificación del disco fallido, reconstrucción iniciada sin pérdida de datos.

---

## 🔗 Referencias

- [`du`](../../guides/du.md) — uso de disco
- [`df`](../../guides/df.md) — espacio en disco
- [`scenarios/infrastructure/03-disaster-recovery.md`](03-disaster-recovery.md) — disaster recovery
- [`scenarios/system/07-high-io-wait.md`](../system/07-high-io-wait.md) — I/O wait (problema relacionado)
