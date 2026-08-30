# dnf — Guía completa

**Nivel:** 🟡 Intermedio
**Archivos de práctica:** Sistema RHEL/Fedora en vivo
**Ver escenarios relacionados:** [`system/03-new-server-provisioning`](../scenarios/system/03-new-server-provisioning.md), [`infrastructure/02-build-pyme-infrastructure`](../scenarios/infrastructure/02-build-pyme-infrastructure.md)

---

## ⚡ Quick command

`dnf install <paquete>`

---

## ⚡ Quick run

```bash
dnf upgrade -y
```

---

## 📑 Índice

1. [¿Qué es dnf?](#qué-es-dnf)
2. [Modelo mental](#modelo-mental)
3. [Sintaxis básica](#sintaxis-básica)
4. [Salida clave](#salida-clave)
5. [Opciones principales](#opciones-principales)
6. [Bases de datos locales](#bases-de-datos-locales)
7. [Repositorios locales y remotos](#repositorios-locales-y-remotos)
8. [Dependencias](#dependencias)
9. [Verificación e integridad (checksum)](#verificación-e-integridad-checksum)
10. [Alternativa: probar sin instalar](#alternativa-probar-sin-instalar)
11. [Uso en troubleshooting](#uso-en-troubleshooting)
12. [Combinación con otras herramientas](#combinación-con-otras-herramientas)
13. [Uno-liners imprescindibles](#uno-liners-imprescindibles)
14. [Errores comunes](#errores-comunes)
15. [Buenas prácticas](#buenas-prácticas)
16. [Referencias internas](#referencias-internas)

---

## 🧠 ¿Qué es dnf?

**dnf** (Dandified Yum) es el gestor de paquetes de Fedora y RHEL 8+ (Rocky, AlmaLinux). Es el sucesor de **yum**, que sigue vigente en RHEL/CentOS 7. Ambos son *frontends* sobre **rpm**, el empaquetado de bajo nivel de la familia Red Hat.

Se usa para:

- instalar, actualizar y eliminar paquetes desde repositorios;
- resolver dependencias automáticamente;
- buscar qué paquete provee un binario o archivo;
- auditar el historial de transacciones y revertirlas;
- instalar archivos `.rpm` sueltos;
- verificar la integridad del sistema (rpmdb y checksums).

Tres niveles de herramientas:

- `dnf` / `yum` — alto nivel: resuelve dependencias y descarga.
- `rpm` — bajo nivel: instala `.rpm` individuales y mantiene la base de datos local.
- `repoquery` — consultas a la base de datos de repositorios.

---

## 🧠 Modelo mental

```text
repositorios remotos → dnf descarga → rpm instala → rpmdb registra
                          │                            │
              /var/cache/dnf/ (caché)     /var/lib/rpm/ (BD de instalados)
```

- `dnf` trae paquetes de los repos y resuelve dependencias.
- `rpm` es quien toca el sistema y registra todo en la **rpmdb** (`/var/lib/rpm/`).
- `dnf history` guarda cada transacción: podés revertir cualquier instalación.
- Los repos se declaran en archivos `.repo` en `/etc/yum.repos.d/`.

> Pensá en dnf como el gerente de compras y en rpm como el almacenero que guarda cada caja y anota su contenido en el inventario (rpmdb).

---

## 📝 Sintaxis básica

```bash
dnf install -y nginx                    # Instalar (resuelve dependencias)
dnf remove nginx                        # Eliminar
dnf search nginx                        # Buscar paquetes
dnf info nginx                          # Info detallada
dnf check-update                        # Listar actualizaciones disponibles
dnf upgrade -y                          # Actualizar todo el sistema
dnf history                             # Historial de transacciones
dnf autoremove                          # Eliminar dependencias huérfanas
```

Con rpm:

```bash
rpm -i ./paquete.rpm                    # Instalar un archivo .rpm (sin dependencias)
rpm -e nginx                            # Eliminar paquete
rpm -q nginx                            # Consultar si está instalado (versión)
rpm -ql nginx                           # Archivos que instala un paquete
rpm -qf /usr/sbin/nginx                 # Qué paquete provee un archivo
rpm -V nginx                            # Verificar integridad vs rpmdb
rpm -ivh ./paquete.rpm                  # Instalar con progreso (clásico)
```

> `dnf install ./paquete.rpm` (o `dnf localinstall`) instala un `.rpm` local **y** resuelve sus dependencias. `rpm -i` solo instala, y si faltan dependencias falla.

---

## 🔑 Salida clave

`dnf info nginx` (info de paquete):

```text
Name         : nginx
Version      : 1.24.0
Release      : 1.el9
Architecture : x86_64
Size         : 1.1 M
Source       : nginx-1.24.0-1.el9.src.rpm
Repository   : @System
Summary      : A high performance web server
URL          : https://nginx.org/
License      : BSD
Description  : ...
```

Interpretación:

- **Version / Release** — la versión completa es `1.24.0-1.el9` (versión-revisión.distribución).
- **Repository** — `@System` indica que está instalado; un nombre de repo indica que está disponible ahí.
- **Size** — tamaño comprimido del paquete (no instalado).

`dnf history` (transacciones):

```text
ID     | Command line                | Date and time    | Action(s)      | Altered
-------------------------------------------------------------------------------
10     | install nginx               | 2026-08-30 10:02 | Install        |    1
 9     | upgrade                     | 2026-08-29 22:40 | Upgrade        |   84
```

Cada ID se puede revertir con `dnf history undo <ID>` o `dnf history rollback <ID>`.

---

## 🎛️ Opciones principales

| Comando | Descripción |
|---------|-------------|
| `dnf install <paq>` | Instalar paquete |
| `dnf remove <paq>` | Eliminar paquete |
| `dnf upgrade` | Actualizar todo el sistema |
| `dnf check-update` | Listar actualizaciones disponibles (exit 100 = hay updates) |
| `dnf search <termino>` | Buscar por nombre/descripción |
| `dnf info <paq>` | Info detallada |
| `dnf history` | Historial de transacciones |
| `dnf history undo <ID>` | Revertir una transacción |
| `dnf history rollback <ID>` | Volver el sistema al estado de esa transacción |
| `dnf autoremove` | Eliminar dependencias huérfanas |
| `dnf provides <archivo>` | Qué paquete provee un archivo |
| `dnf repoquery --requires <paq>` | Dependencias de un paquete |
| `dnf check` | Verificar dependencias rotas en el sistema |
| `dnf list installed` | Paquetes instalados |

| Opción (rpm) | Descripción |
|--------------|-------------|
| `-i <file.rpm>` | Instalar un archivo |
| `-e <paq>` | Eliminar |
| `-q <paq>` | Consultar instalado (con `-a`: todos) |
| `-ql <paq>` | Listar archivos del paquete |
| `-qf <archivo>` | Qué paquete posee un archivo |
| `-qR <paq>` | Requisitos (dependencias) de un paquete |
| `-V <paq>` | Verificar checksums vs rpmdb |
| `--checksig <file.rpm>` | Verificar firma GPG de un archivo |
| `--rebuilddb` | Reconstruir la rpmdb dañada |

---

## Bases de datos locales

| Ruta | Contiene |
|------|----------|
| `/var/lib/rpm/` | **rpmdb**: registro maestro de paquetes instalados (archivos, checksums, dependencias) |
| `/var/cache/dnf/` | Índices descargados de los repos y caché de paquetes |
| `/var/lib/dnf/` | Historial de transacciones de dnf |
| `/etc/yum.repos.d/` | Repositorios habilitados (`.repo`) |
| `/etc/dnf/dnf.conf` | Configuración global de dnf |

### Caché

```bash
dnf clean all          # Vaciar caché e índices
dnf clean packages     # Solo paquetes descargados
dnf makecache          # Recargar índices (tras agregar un repo)
```

### rpmdb dañada

Si rpm falla con `rpmdb: damaged` o errores de BDB, se reconstruye (respaldando antes):

```bash
cp -a /var/lib/rpm /var/lib/rpm.bak
rpm --rebuilddb
```

---

## Repositorios locales y remotos

### Remotos

Cada repo es un archivo en `/etc/yum.repos.d/*.repo`:

```text
[nginx]
name=nginx repo
baseurl=https://nginx.org/packages/rhel/9/x86_64/
enabled=1
gpgcheck=1
gpgkey=https://nginx.org/keys/nginx_signing.key
```

- `baseurl` — URL del repo (http/https).
- `enabled=1` — habilitado; `gpgcheck=1` — validar firmas.
- Repos extra: EPEL para paquetes que no están en los repos base: `dnf install epel-release`.

Agregar un repo desde URL:

```bash
dnf config-manager --add-repo <url-del-.repo>   # requiere dnf-plugins-core
```

### Locales

1. **Instalar un `.rpm` suelto:** `dnf install ./paquete.rpm` (resuelve dependencias desde los repos configurados).
2. **Repo local por path** — un `.repo` con `baseurl=file://` (ejemplo abajo) y `dnf makecache` para cargar el índice.
3. **Descargar sin instalar** para llevar a otra máquina (offline) con `dnf install --downloadonly`.

```text
[local]
name=Repo local offline
baseurl=file:///ruta/al/repo/
enabled=1
gpgcheck=0
```

```bash
dnf makecache
dnf install --downloadonly --downloaddir=/tmp/pkgs <paquete>
```

---

## Dependencias

| Comando | Qué muestra |
|---------|-------------|
| `dnf repoquery --requires <paq>` | Dependencias de un paquete |
| `dnf repoquery --whatrequires <paq>` | Reverse dependencies (quién depende de él) |
| `rpm -qR <paq>` | Requisitos de un paquete instalado |
| `rpm -q --whatrequires <dep>` | Instalados que dependen de una librería |
| `dnf check` | Detecta dependencias rotas en el sistema |
| `dnf mark remove <paq>` | Marcar paquete como instalado manualmente (evita autoremove) |

### Dependencias rotas

```bash
dnf check                       # reporta dependencias insatisfechas
dnf install -y <paquete>        # dnf re-resuelve y repara al instalar
dnf history                     # encontrar la transacción que rompió todo
```

`dnf` a diferencia de `apt` no tiene un `--fix-broken`: la reparación natural es reinstalar el paquete roto (`dnf reinstall <paq>`) o revertir la transacción con `dnf history undo`.

---

## Verificación e integridad (checksum)

### Integridad de archivos instalados

```bash
rpm -V <paq>        # Verifica checksums y atributos vs rpmdb
rpm -Va             # Todo el sistema (lento)
```

`rpm -V` compara cada archivo contra lo registrado al instalar. La salida usa códigos de atributo:

```text
S.5....T.  c /etc/nginx/nginx.conf
missing     /usr/lib64/libfoo.so.1
```

- `S` = tamaño distinto; `5` = checksum MD5 distinto; `T` = mtime distinto; `c` = archivo de configuración.
- `missing` = el archivo no existe en disco (borrado a mano).

### Firmas y checksums de `.rpm` descargados

```bash
rpm --checksig ./paquete.rpm     # verifica firma GPG del archivo
sha256sum ./paquete.rpm          # comparar con el valor publicado
md5sum ./paquete.rpm
```

### Repos con gpgcheck

`gpgcheck=1` en el `.repo` + `gpgkey` válida: dnf verifica la firma de cada paquete descargado. Deshabilitar (`gpgcheck=0`) solo para repos locales de confianza.

---

## Alternativa: probar sin instalar

Para probar una herramienta sin ensuciar el sistema con paquetes, se puede usar un contenedor efímero con herramientas preinstaladas:

```bash
docker run --rm -it --net=host --pid=host nicolaka/netshoot
```

Es especialmente útil para probar utilidades de red (curl, dig, tcpdump) que no querés instalar en el host. Ver [`docker_debug_container`](docker_debug_container.md) para qué se puede testear y qué solo funciona en el host nativo.

---

## 🔍 Uso en troubleshooting

### 1. La instalación falla con "nothing provides"

```bash
dnf provides <librería-o-archivo>   # qué paquete provee lo que falta
dnf install <paquete-propietario>
```

### 2. "No package available"

El paquete no está en los repos habilitados:

```bash
dnf search <termino>                 # verificar el nombre real
dnf repolist                         # repos habilitados
dnf install epel-release             # agregar EPEL si falta
```

### 3. Un binario no arranca por librería faltante

```bash
ldd /usr/bin/<binario> | grep "not found"
rpm -qf /usr/bin/<binario>           # qué paquete lo instaló
rpm -V <paquete>                     # verificar integridad
dnf reinstall <paquete>              # restaurar archivos originales
```

### 4. rpmdb dañada

```bash
cp -a /var/lib/rpm /var/lib/rpm.bak
rpm --rebuilddb
```

### 5. Una actualización rompió el sistema

```bash
dnf history                          # encontrar la transacción problemática
dnf history undo <ID>                # revertir esa transacción
dnf history rollback <ID>            # volver al estado de un punto anterior
```

> `rollback` revierte a un estado previo en el historial; `undo` deshace una transacción puntual. Ambos pueden fallar si hubo transacciones intermedias incompatibles: en ese caso usar `dnf reinstall` de los paquetes afectados.

---

## 🛠️ Combinación con otras herramientas

- `rpm -qf $(command -v curl)` — de qué paquete viene `curl`.
- `rpm -ql nginx | grep /etc/` — archivos de configuración de un paquete.
- `dnf repoquery --requires nginx` + `dnf repoquery --whatrequires nginx` — árbol de dependencias.
- `dnf list --upgrades` — paquetes con actualización disponible.
- `dnf history | head -20` — auditar qué se instaló y cuándo.
- `dnf provides '*/curl'` — buscar por nombre de archivo sin conocer la ruta completa.

---

## 💡 Uno-liners imprescindibles

```bash
dnf upgrade -y                      # actualizar todo el sistema
dnf search nginx                    # buscar paquete
dnf info nginx                      # info detallada
dnf install -y nginx                # instalar
rpm -ql nginx                       # archivos del paquete
rpm -qf /usr/bin/curl               # quién provee un archivo
rpm -V nginx                        # verificar integridad de un paquete
dnf history                         # historial de transacciones
dnf check                           # dependencias rotas
dnf provides '*/curl'               # buscar paquete por archivo
```

---

## ⚠️ Errores comunes

| Error | Causa | Acción |
|-------|-------|--------|
| `No package <paq> available` | Paquete no está en los repos habilitados | `dnf search`; `dnf install epel-release` |
| `nothing provides <dep>` | Dependencia insatisfecha (paquete de repo externo) | `dnf provides <dep>`; instalar el propietario |
| `Error: Failed to synchronize cache` | Repo caído o URL inválida | `dnf repolist`; revisar `baseurl` del `.repo` |
| `rpmdb: BDB0091 ... damaged` | rpmdb corrupta | `cp -a /var/lib/rpm /var/lib/rpm.bak && rpm --rebuilddb` |
| `error: Failed dependencies` | `rpm -i` sin dependencias | Usar `dnf install ./file.rpm` |
| `GPG key retrieval failed` | `gpgkey` inaccesible o firmas no verificadas | Corregir `gpgkey` del repo; `gpgcheck=0` solo en repos locales |
| `transaction check error` | Conflicto de archivos entre paquetes | Revisar `dnf history`; revertir la transacción culpable |

---

## ✅ Buenas prácticas

- Correr `dnf check-update` y `dnf upgrade -y` periódicamente; en producción, usar `dnf --security upgrade` para solo parches de seguridad.
- Preferir `dnf install ./file.rpm` sobre `rpm -i` para archivos locales (resuelve dependencias).
- No mezclar repos de terceros: usar `gpgcheck=1` y auditar con `dnf repolist`.
- Revisar `dnf history` antes y después de grandes cambios: es tu red de seguridad.
- No tocar `/var/lib/rpm/` a mano: si se daña, usar `rpm --rebuilddb` (con backup previo).
- Tras un incidente de seguridad, correr `rpm -Va` para detectar binarios alterados.

---

## 🔗 Referencias internas

- [`package-managers`](../reference/package-managers.md) — equivalencias entre apt, apk, pacman y yum/dnf
- [`apt`](apt.md) — gestor de Debian/Ubuntu (equivalente con sección dpkg)
- [`pacman`](pacman.md) — gestor de Arch Linux (equivalente con BDs locales)
- [`apk`](apk.md) — gestor de Alpine (equivalente minimalista)
- [`docker_debug_container`](docker_debug_container.md) — probar herramientas sin ensuciar el host
- [`curl`](curl.md) — descargar paquetes manualmente
- [`wget`](wget.md) — alternativa a curl para descargas
- [`tar`](tar.md) — extraer tarballs con fuentes
- [`scenario`](../scenarios/system/03-new-server-provisioning.md) — provisioning de servidor nuevo
- [`scenario`](../scenarios/infrastructure/02-build-pyme-infrastructure.md) — instalación de servicios en infraestructura PYME
