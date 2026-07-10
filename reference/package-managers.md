# Gestores de paquetes — Referencia rápida

Operaciones comunes en apt (Debian/Ubuntu), apk (Alpine) y yum/dnf (RHEL/Fedora).

---

## 📊 Mapa de equivalencias

| Operación | apt (Debian/Ubuntu) | apk (Alpine) | yum / dnf (RHEL/Fedora) |
|-----------|-------------------|--------------|------------------------|
| Buscar paquete | `apt search <nombre>` | `apk search <nombre>` | `yum search <nombre>` / `dnf search <nombre>` |
| Instalar | `apt install <paquete>` | `apk add <paquete>` | `yum install <paquete>` / `dnf install <paquete>` |
| Eliminar | `apt remove <paquete>` | `apk del <paquete>` | `yum remove <paquete>` / `dnf remove <paquete>` |
| Actualizar lista | `apt update` | `apk update` | `yum check-update` / `dnf check-update` |
| Actualizar todo | `apt upgrade` | `apk upgrade` | `yum update` / `dnf upgrade` |
| Info del paquete | `apt show <paquete>` | `apk info <paquete>` | `yum info <paquete>` / `dnf info <paquete>` |
| Listar instalados | `apt list --installed` | `apk info -v` | `yum list installed` / `dnf list installed` |
| ¿Quién provee archivo? | `apt-file search <ruta>` | `apk info --who-owns <ruta>` | `yum provides <ruta>` / `dnf provides <ruta>` |
| Archivos de un paquete | `dpkg -L <paquete>` | `apk info -L <paquete>` | `rpm -ql <paquete>` |
| Limpiar caché | `apt clean` | `apk cache clean` | `yum clean all` / `dnf clean all` |

---

## 🛠️ Comandos rápidos por necesidad

### "Necesito instalar X pero no sé el nombre exacto"

```bash
apt search "parte del nombre"              # Debian/Ubuntu
apk search "parte del nombre"              # Alpine (apk search -v para verbose)
yum search "parte del nombre"              # RHEL/CentOS 7
dnf search "parte del nombre"              # RHEL/Fedora 8+
```

### "¿Qué paquete instaló este archivo?"

```bash
dpkg -S /usr/bin/ls                       # Debian/Ubuntu
apk info --who-owns /usr/bin/somefile     # Alpine
rpm -qf /usr/bin/ls                       # RHEL/Fedora
```

### "¿Qué paquetes están rotos o a medio instalar?"

```bash
apt --fix-broken install                  # Debian/Ubuntu
apk fix                                   # Alpine
yum-complete-transaction                  # RHEL/CentOS 7
dnf history rollback <ID>                 # RHEL/Fedora 8+
```

---

## 📦 Repositorios

| Operación | apt | apk | yum/dnf |
|-----------|-----|-----|---------|
| Listar repos | `apt-cache policy` | `cat /etc/apk/repositories` | `yum repolist` |
| Agregar repo | Editar `/etc/apt/sources.list` o `/etc/apt/sources.list.d/` | Editar `/etc/apk/repositories` | `yum-config-manager --add-repo <url>` |
| Repos habilitados | `grep -r . /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null \| grep -v "^#" \| grep -v "^$"` | `cat /etc/apk/repositories` | `yum repolist enabled` |

---

## ⚠️ Errores comunes en troubleshooting

| Síntoma | Causa probable | Acción |
|---------|---------------|--------|
| `E: Unable to locate package` (apt) | `apt update` no corrió o repo no configurado | `apt update && apt install ...` |
| `unsatisfiable constraints` (apk) | Paquete no existe o dependencias conflictivas | `apk update && apk search <paq>` |
| `No package available` (yum) | Repo no configurado o EPEL no instalado | `yum install epel-release` |
| `dpkg: error processing package` | Instalación interrumpida, dpkg corrupto | `dpkg --configure -a` |
| `apk: (1/1) Installing... FAILED` | /tmp sin espacio o sin permisos de escritura | `df -h /tmp`, verificar permisos |
| Dependencias rotas | Paquete de fuente externa o versión incompatible | `apt --fix-broken install` |
| `/var/cache/apt/archives/` lleno | Caché acumulada | `apt clean` o `apt autoclean` |

---

## 🐧 Alpine: qué tener en cuenta

Alpine usa `apk` y **musl libc** en lugar de glibc. Esto significa:

- No todos los paquetes existen: `apk search <nombre>` antes de asumir que está.
- Binarios compilados contra glibc no funcionan sin compat layer (`gcompat`).
- `apk add procps util-linux bc` para herramientas comunes que no vienen en base.
- `apk add --no-cache` en Dockerfiles para no guardar la caché en la imagen.

---

## 🔗 Ver también

- [`guides/curl.md`](../guides/curl.md) — descargar paquetes manualmente
- [`guides/wget.md`](../guides/wget.md) — alternativa a curl para descargas
- [`guides/tar.md`](../guides/tar.md) — extraer tarballs manuales
- [`reference/disk-layout.md`](disk-layout.md) — FHS: `/var/cache/apt/`, `/etc/apt/`
- [`scenarios/system/03-new-server-provisioning.md`](../scenarios/system/03-new-server-provisioning.md) — provisioning de servidor nuevo
