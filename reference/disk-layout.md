# Linux Filesystem Hierarchy — Referencia rápida

Dónde vive cada cosa en el filesystem de Linux. Esencial para troubleshooting de disco y permisos.

---

## 🗂️ Directorios raíz

| Directorio | Contiene | Cuándo revisarlo en troubleshooting |
|-----------|----------|-----------------------------------|
| `/` | Raíz del sistema. Debe tener espacio libre siempre. | No puede llenarse nunca. Si pasa → el sistema colapsa |
| `/bin` | Binarios esenciales (ls, cp, cat, sh) | En muchas distros es symlink a `/usr/bin` |
| `/boot` | Kernel (`vmlinuz-*`), initramfs, GRUB | Kernel panic, "no bootable device", /boot lleno tras updates |
| `/dev` | Archivos de dispositivo (discos, ttys, null, random) | Un dispositivo no aparece: verificar driver y udev |
| `/etc` | Configuración del sistema y servicios | El 90% del troubleshooting de servicios empieza acá |
| `/home` | Directorios de usuario | Disco lleno por backups de usuario, core dumps |
| `/lib`, `/lib64` | Librerías compartidas (.so) | "error while loading shared libraries" |
| `/media`, `/mnt` | Puntos de montaje temporales | Montaje manual falló, permisos de mount point |
| `/opt` | Software de terceros instalado manualmente | Binarios que no maneja el package manager |
| `/proc` | Sistema de archivos virtual: procesos, kernel, hardware | `/proc/cpuinfo`, `/proc/meminfo`, `/proc/<PID>/` |
| `/root` | Home del usuario root | `.bash_history` sospechoso en incidentes de seguridad |
| `/run` | tmpfs con datos volátiles de runtime (PID, sockets) | Se pierde al reboot. PIDs y sockets de servicios vivos |
| `/sbin` | Binarios de administración (mkfs, fdisk, iptables) | En muchas distros es symlink a `/usr/sbin` |
| `/srv` | Datos servidos por servicios (web, ftp) | Contenido estático de nginx/apache |
| `/sys` | Sistema de archivos virtual: kernel, devices, módulos | `/sys/class/net/`, `/sys/block/`, cgroups v1 |
| `/tmp` | Archivos temporales. Se limpia al reboot (o antes) | Disco lleno por procesos que no limpian, sesiones huérfanas |
| `/usr` | Binarios, librerías, docs del usuario (read-only idealmente) | `/usr/bin`, `/usr/lib`, `/usr/share` |
| `/var` | Datos variables: logs, colas, caches, bases de datos | `/var/log` es el primer lugar al que vas en un incidente |

---

## 🔍 Paths clave para troubleshooting

| Problema | Primer lugar a mirar |
|----------|---------------------|
| Disco lleno | `df -h`, `du -sh /* 2>/dev/null \| sort -rh \| head` |
| Servicio no arranca | `/etc/<servicio>/`, logs en `/var/log/<servicio>/` |
| Librería faltante | `ldd /path/al/binario`, `ldconfig -p \| grep <lib>` |
| Problema de red | `/etc/network/`, `/etc/resolv.conf`, `/etc/hosts` |
| Cron job no corre | `/var/spool/cron/`, `/etc/crontab`, `/etc/cron.*/` |
| Permisos denegados | `ls -la`, `stat`, `/etc/passwd`, `/etc/group` |

---

## 📏 Límites de inodos y espacio

```bash
df -h      # espacio en disco (GB)
df -i      # inodos disponibles (contador, no tamaño)
du -sh /*  # qué carpeta ocupa más (requiere root para /proc accuracy)
```

| Síntoma | Causa | Verificación |
|---------|-------|-------------|
| `df -h` dice que hay espacio pero `touch` falla | Sin inodos libres | `df -i` → IUse% al 100% |
| `/tmp` lleno pero no ves archivos grandes | Miles de archivos chicos | `find /tmp -type f` para contar archivos |
| `/var/log` crece sin control | logrotate no configurado | `ls -lhS /var/log/` para ver los más grandes |

---

## 🔗 Ver también

- [`concepts/linux-fhs.md`](../concepts/linux-fhs.md) — FHS en profundidad
- [`guides/df.md`](../guides/df.md) — espacio en disco
- [`guides/du.md`](../guides/du.md) — uso de disco por directorio
- [`guides/stat.md`](../guides/stat.md) — metadatos de archivos
- [`scenarios/system/06-disk-full-inodes.md`](../scenarios/system/06-disk-full-inodes.md) — disco lleno y sin inodos
