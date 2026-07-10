# Proceso de boot de Linux — Referencia rápida

Etapas del arranque de Linux para diagnosticar fallos de inicio.

---

## 📊 Etapas del boot

| Etapa | Qué pasa | Dónde mirar si falla |
|-------|----------|---------------------|
| 1. BIOS/UEFI | POST (power-on self test), carga firmware | Pantalla del servidor, IPMI/iLO/iDRAC |
| 2. Bootloader (GRUB/GRUB2) | Carga kernel + initramfs en memoria | `/boot/grub/grub.cfg`, error "grub rescue>" |
| 3. Kernel | Inicializa hardware, monta rootfs, ejecuta init | `dmesg`, consola serie, kernel panic |
| 4. initramfs | Monta drivers/modulos necesarios antes del root real | `dmesg \| grep initramfs`, `lsinitrd` |
| 5. init (PID 1) | systemd, OpenRC, SysV — lanza servicios del sistema | `systemctl status`, `dmesg`, journal |
| 6. Userspace | Getty, login, servicios de red, aplicaciones | `systemctl list-units --failed` |

---

## 🎯 Qué verificar en cada etapa

| Síntoma | Etapa probable | Comando diagnóstico |
|---------|---------------|-------------------|
| Pantalla negra, no hay POST | BIOS/UEFI | Consola física, IPMI |
| "grub rescue>" | Bootloader | `ls (hd0,1)/`, `grub-install /dev/sda` |
| Kernel panic al bootear | Kernel | `dmesg`, kernel params en GRUB |
| "No root device found" | initramfs | Regenerar initramfs: `mkinitcpio -P` o `dracut -f` |
| Servicios no arrancan | init/systemd | `systemctl list-units --failed` |
| Bootea pero sin red | Userspace | `ip a`, `ping` gateway |

---

## 🔌 systemd — Estados de arranque

| Comando | Qué muestra |
|---------|------------|
| `systemctl list-units --failed` | Unidades que fallaron al arrancar |
| `systemctl list-jobs` | Trabajos pendientes de systemd |
| `journalctl -b` | Todos los logs desde que booteó |
| `journalctl -b -1` | Logs del boot anterior (útil si reiniciaste) |
| `systemd-analyze blame` | Cuánto tardó cada servicio en arrancar |
| `systemd-analyze critical-chain` | Cadena crítica — qué bloquea qué |

---

## 🛠️ Rescate y recovery

| Escenario | Acción |
|-----------|--------|
| GRUB roto | Bootear con live CD → `chroot` → `grub-install` |
| Kernel panic tras update | En GRUB elegir kernel anterior (Advanced options) |
| No monta root | `fsck /dev/sda1`, `mount -o remount,rw /` |
| /etc/fstab roto | Editar desde initramfs shell o live CD |
| Contraseña de root perdida | GRUB → `init=/bin/bash` → `passwd` |

---

## 🔗 Ver también

- [`concepts/linux-fhs.md`](../concepts/linux-fhs.md) — sistema de archivos Linux en profundidad
- [`guides/systemd_journalctl.md`](../guides/systemd_journalctl.md) — logs del arranque
- [`guides/systemd.md`](../guides/systemd.md) — systemd y unidades de servicio
- [`scenarios/system/05-system-memory-issues-oom.md`](../scenarios/system/05-system-memory-issues-oom.md) — OOM killer y memoria
