# Gestores de paquetes — Referencia rápida

Operaciones comunes en apt (Debian/Ubuntu), apk (Alpine), pacman (Arch) y yum/dnf (RHEL/Fedora).

---

## 📊 Mapa de equivalencias

| Operación | apt (Debian/Ubuntu) | apk (Alpine) | pacman (Arch) | yum / dnf (RHEL/Fedora) |
|-----------|-------------------|--------------|---------------|------------------------|
| Buscar paquete | `apt search <nombre>` | `apk search <nombre>` | `pacman -Ss <nombre>` | `yum search` / `dnf search` |
| Instalar | `apt install <paquete>` | `apk add <paquete>` | `pacman -S <paquete>` | `yum install` / `dnf install` |
| Eliminar | `apt remove <paquete>` | `apk del <paquete>` | `pacman -R <paquete>` | `yum remove` / `dnf remove` |
| Actualizar lista | `apt update` | `apk update` | `pacman -Sy` | `yum check-update` / `dnf check-update` |
| Actualizar todo | `apt upgrade` | `apk upgrade` | `pacman -Syu` | `yum update` / `dnf upgrade` |
| Info del paquete | `apt show <paquete>` | `apk info <paquete>` | `pacman -Qi` (local) / `-Si` (remoto) | `yum info` / `dnf info` |
| Listar instalados | `apt list --installed` | `apk info -v` | `pacman -Q` | `yum list installed` / `dnf list installed` |
| ¿Quién provee archivo? | `apt-file search <ruta>` | `apk info --who-owns <ruta>` | `pacman -Qo <ruta>` (instalado) / `pacman -F <ruta>` (remoto) | `yum provides <ruta>` / `dnf provides <ruta>` |
| Archivos de un paquete | `dpkg -L <paquete>` | `apk info -L <paquete>` | `pacman -Ql <paquete>` | `rpm -ql <paquete>` |
| Limpiar caché | `apt clean` | `apk cache clean` | `pacman -Scc` | `yum clean all` / `dnf clean all` |

---

## 🛠️ Comandos rápidos por necesidad

### "Necesito instalar X pero no sé el nombre exacto"

```bash
apt search "parte del nombre"              # Debian/Ubuntu
apk search "parte del nombre"              # Alpine (apk search -v para verbose)
pacman -Ss "parte del nombre"              # Arch (repos oficiales)
yay -Ss "parte del nombre"                 # Arch (repos + AUR)
yum search "parte del nombre"              # RHEL/CentOS 7
dnf search "parte del nombre"              # RHEL/Fedora 8+
```

### "¿Qué paquete instaló este archivo?"

```bash
dpkg -S /usr/bin/ls                       # Debian/Ubuntu
apk info --who-owns /usr/bin/somefile     # Alpine
pacman -Qo /usr/bin/ls                    # Arch (búsqueda en instalados)
pacman -Fy && pacman -F /usr/bin/ls       # Arch (búsqueda en repos sin instalar)
rpm -qf /usr/bin/ls                       # RHEL/Fedora
```

### "¿Qué paquetes están rotos o a medio instalar?"

```bash
apt --fix-broken install                  # Debian/Ubuntu
dpkg --configure -a                       # Debian/Ubuntu (reanudar pendientes)
apk fix                                   # Alpine (transacciones interrumpidas)
pacman -Qkk                               # Arch (verificar checksums de todos)
pacman -S <paquete>                       # Arch (reinstalar y restaurar archivos)
yum-complete-transaction                  # RHEL/CentOS 7
dnf history rollback <ID>                 # RHEL/Fedora 8+
```

---

## 📦 Repositorios (locales y remotos)

| Operación | apt | apk | pacman | yum/dnf |
|-----------|-----|-----|--------|---------|
| Listar repos | `apt-cache policy` | `cat /etc/apk/repositories` | `grep -v '^#' /etc/pacman.conf` | `yum repolist` / `dnf repolist` |
| Agregar repo remoto | Editar `/etc/apt/sources.list` o `sources.list.d/` | Editar `/etc/apk/repositories` | Editar `/etc/pacman.conf` + `/etc/pacman.d/mirrorlist` | `dnf config-manager --add-repo <url>` |
| Repo local / offline | `deb [trusted=yes] file:///ruta ./` en `sources.list.d` | `apk add --allow-untrusted ./file.apk` | `Server = file:///ruta` en `pacman.conf` o `pacman -U ./file.pkg.tar.zst` | `dnf localinstall ./file.rpm` |
| Firmas | GPG: `/etc/apt/trusted.gpg.d/`, opción `signed-by` | Claves RSA en `/etc/apk/keys/` | `pacman-key`, claves en `/etc/pacman.d/gnupg/` | GPG en rpmdb |

Repos habilitados (apt): `grep -r . /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null | grep -v "^#" | grep -v "^$"`

---

## 🗄️ Bases de datos locales (dónde se guarda qué)

| Gestor | BD de instalados | Índices de repos | Caché de descargas |
|--------|------------------|------------------|--------------------|
| apt/dpkg | `/var/lib/dpkg/status` | `/var/lib/apt/lists/` | `/var/cache/apt/archives/` |
| apk | `/lib/apk/db/installed` | (índices en la misma BD de apk) | `/var/cache/apk/` |
| pacman | `/var/lib/pacman/local/` | `/var/lib/pacman/sync/` | `/var/cache/pacman/pkg/` |
| yum/dnf | `/var/lib/rpm/` (rpmdb) | `/var/cache/dnf/` | `/var/cache/dnf/` |

No borrar estas rutas a mano: rompen el inventario del gestor y el sistema deja de poder repararse.

---

## 🔏 Verificación e integridad (checksums y firmas)

| Verificación | apt/dpkg | apk | pacman |
|--------------|----------|-----|--------|
| Archivos instalados vs BD | `dpkg -V` / `debsums -c` | `apk audit` | `pacman -Qkk` |
| Firma de paquetes/repos | GPG (`signed-by`, `trusted.gpg.d`) | Claves RSA `/etc/apk/keys/` | `pacman-key --verify` |
| Checksum de descargas manuales | `sha256sum archivo` / `md5sum archivo` (aplica a los tres) | | |

`pacman -Qkk` y `debsums -c` detectan archivos modificados o eliminados comparando contra lo registrado al instalar. Verificar con `sha256sum` toda descarga manual (`.deb`, `.rpm`, `.pkg.tar.zst`, tarballs) contra el valor publicado.

---

## 🐧 Arch: yay y AUR

`yay` es un wrapper de pacman que agrega acceso a AUR (Arch User Repository) con la misma sintaxis:

- `yay -Qi <paquete>` — info de paquete instalado (BD local);
- `yay -Si <paquete>` — info de paquete remoto (repos oficiales + AUR);
- `yay -Ss <termino>` — buscar en repos + AUR; `yay -Qs <termino>` — buscar entre instalados;
- `yay -Syu` — actualizar repos + AUR;
- `yay -G <paquete>` — clonar el PKGBUILD; `yay -P` — diff del PKGBUILD vs instalado.

Los paquetes de AUR se compilan con `makepkg` desde un PKGBUILD: se verifica el checksum declarado (`sha256sums=`) antes de compilar. ⚠️ Leer el PKGBUILD antes de instalar: cualquiera puede publicar en AUR.

> Nota: AUR **no es un repo con índices** como los de pacman (`/var/lib/pacman/sync/`): es una colección de PKGBUILDs que yay consulta por RPC y compila con makepkg. Para instalaciones offline o locales se usa `pacman -U ./archivo.pkg.tar.zst` o un repo propio con `Server = file:///` en `pacman.conf`.

---

## ⚠️ Errores comunes en troubleshooting

| Síntoma | Causa probable | Acción |
|---------|---------------|--------|
| `E: Unable to locate package` (apt) | `apt update` no corrió o repo no configurado | `apt update && apt install ...` |
| `E: Unmet dependencies` (apt) | Paquete roto o mezcla de repos | `apt --fix-broken install` |
| `dpkg: error processing package` | Instalación interrumpida, dpkg corrupto | `dpkg --configure -a` |
| `unsatisfiable constraints` (apk) | Paquete no existe o dependencias conflictivas | `apk update && apk search <paq>` |
| `apk: (1/1) Installing... FAILED` | /tmp sin espacio o sin permisos de escritura | `df -h /tmp`, verificar permisos |
| `error: target not found: <paq>` (pacman) | Paquete inexistente o repo no habilitado | `pacman -Ss <paq>`; verificar `pacman.conf` |
| `unable to lock database` (pacman) | `/var/lib/pacman/db.lck` presente | Verificar que no haya pacman activo y borrar el lock |
| `invalid or corrupted package (PGP signature)` (pacman) | Firma inválida: hora o claves viejas | `timedatectl`; `pacman-key --refresh-keys` |
| `pacman: error while loading shared libraries` (pacman) | Librería de la que depende pacman borrada: el gestor se rompe a sí mismo | `bsdtar -xpf /var/cache/pacman/pkg/<paq>-*.pkg.tar.zst -C /` |
| `No package available` (yum) | Repo no configurado o EPEL no instalado | `yum install epel-release` |
| Dependencias rotas | Paquete de fuente externa o versión incompatible | `apt --fix-broken install` / `apk del && apk add` / `pacman -S <paq>` |
| `/var/cache/apt/archives/` lleno | Caché acumulada | `apt clean` o `apt autoclean` |

---

## 🐧 Alpine: qué tener en cuenta

Alpine usa `apk` y **musl libc** en lugar de glibc. Esto significa:

- No todos los paquetes existen: `apk search <nombre>` antes de asumir que está.
- Binarios compilados contra glibc no funcionan sin compat layer (`gcompat`).
- `apk add procps util-linux bc` para herramientas comunes que no vienen en base.
- `apk add --no-cache` en Dockerfiles para no guardar la caché en la imagen.
- `ldd` de musl no imprime `not found`: reporta `Error loading shared library`.

---

## 🔗 Ver también

- [`guides/apt.md`](../guides/apt.md) — apt/dpkg en profundidad (dependencias rotas, checksums)
- [`guides/apk.md`](../guides/apk.md) — apk en profundidad (repos, world, audit)
- [`guides/pacman.md`](../guides/pacman.md) — pacman y yay en profundidad (BDs, firmas PGP)
- [`guides/docker_debug_container.md`](../guides/docker_debug_container.md) — probar herramientas sin ensuciar el host
- [`guides/curl.md`](../guides/curl.md) — descargar paquetes manualmente
- [`guides/wget.md`](../guides/wget.md) — alternativa a curl para descargas
- [`guides/tar.md`](../guides/tar.md) — extraer tarballs manuales
- [`reference/disk-layout.md`](disk-layout.md) — FHS: `/var/cache/apt/`, `/etc/apt/`, `/var/lib/pacman/`
- [`scenarios/system/03-new-server-provisioning.md`](../scenarios/system/03-new-server-provisioning.md) — provisioning de servidor nuevo
- [`scenarios/system/16-package-dependencies-broken.md`](../scenarios/system/16-package-dependencies-broken.md) — dependencias rotas: runbook completo
