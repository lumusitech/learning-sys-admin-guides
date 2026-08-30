# pacman — Guía completa

**Nivel:** 🟡 Intermedio
**Archivos de práctica:** Sistema Arch Linux en vivo
**Ver escenarios relacionados:** [`system/03-new-server-provisioning`](../scenarios/system/03-new-server-provisioning.md), [`infrastructure/02-build-pyme-infrastructure`](../scenarios/infrastructure/02-build-pyme-infrastructure.md), [`system/16-package-dependencies-broken`](../scenarios/system/16-package-dependencies-broken.md)

---

## ⚡ Quick command

`pacman -S <paquete>`

---

## ⚡ Quick run

```bash
pacman -Syu
```

---

## 📑 Índice

1. [¿Qué es pacman?](#qué-es-pacman)
2. [Modelo mental](#modelo-mental)
3. [Sintaxis básica](#sintaxis-básica)
4. [Salida clave](#salida-clave)
5. [Opciones principales](#opciones-principales)
6. [Bases de datos locales](#bases-de-datos-locales)
7. [Repositorios locales y remotos](#repositorios-locales-y-remotos)
8. [Dependencias](#dependencias)
9. [Verificación e integridad (checksum)](#verificación-e-integridad-checksum)
10. [yay — wrapper AUR](#yay--wrapper-aur)
11. [Uso en troubleshooting](#uso-en-troubleshooting)
12. [Combinación con otras herramientas](#combinación-con-otras-herramientas)
13. [Uno-liners imprescindibles](#uno-liners-imprescindibles)
14. [Errores comunes](#errores-comunes)
15. [Buenas prácticas](#buenas-prácticas)
16. [Referencias internas](#referencias-internas)

---

## 🧠 ¿Qué es pacman?

**pacman** es el gestor de paquetes de Arch Linux y sus derivados (EndeavourOS, Manjaro, Garuda). Sigue un modelo *rolling release*: el sistema se actualiza de forma continua, sin versiones discretas.

A diferencia de `apt` (Debian), pacman es un solo binario que integra todas las operaciones mediante flags de operación:

- `-S` (sync) — operar con repositorios remotos;
- `-Q` (query) — consultar la base de datos local;
- `-R` (remove) — eliminar paquetes;
- `-U` (upgrade) — instalar desde un archivo `.pkg.tar.zst`.

Los paquetes son binarios comprimidos con zstd (`.pkg.tar.zst`) y firmados con PGP.

Se usa para:

- instalar, actualizar y eliminar paquetes;
- buscar qué paquete provee un binario o archivo;
- auditar qué está instalado y por qué;
- verificar la integridad del sistema (checksums y firmas);
- instalar paquetes desde repos locales o archivos sueltos.

---

## 🧠 Modelo mental

pacman trabaja con tres mundos:

```text
sync  → repositorios remotos (índices en /var/lib/pacman/sync/)
local → lo que está instalado (BD en /var/lib/pacman/local/)
files → base de datos de archivos remotos (pacman -F)
```

- `-S` = traer algo de remoto al local.
- `-Q` = preguntarle al local.
- `-U` = meter un archivo directo al local.
- Todo lo descargado queda en caché (`/var/cache/pacman/pkg/`), que además permite downgrades.

> Pensá en pacman como un almacén con un catálogo (`sync`), un depósito con lo que compraste (`local`) y un registro de qué caja contiene cada pieza (`files`).

---

## 📝 Sintaxis básica

```bash
pacman <operación> [opciones] [paquete...]
```

```bash
pacman -S nginx                # Instalar desde repos
pacman -Syu                    # Actualizar índices + todo el sistema
pacman -Ss nginx               # Buscar en repos
pacman -Si nginx               # Info de paquete remoto
pacman -Qi nginx               # Info de paquete instalado
pacman -Rns nginx              # Eliminar + dependencias no usadas + config
pacman -U ./nginx-1.26.2-1-x86_64.pkg.tar.zst   # Instalar archivo local
pacman -Ql nginx               # Archivos que instala
pacman -Qo /usr/bin/nginx      # Qué paquete provee ese archivo
```

La diferencia principal con `apt`: pacman no separa el refresh de índices (`apt update`) del upgrade. `pacman -Syu` hace refresh + upgrade en un solo paso y es el comando estándar de actualización.

---

## 🔑 Salida clave

`pacman -Qi nginx` (paquete instalado):

```text
Name            : nginx
Version         : 1.26.2-1
Description     : ...
Architecture    : x86_64
URL             : ...
Licenses        : ...
Depends On      : glibc  libxcrypt  openssl  pcre2  zlib
Required By     : None
Conflicts With  : None
Installed Size  : 6,78 MiB
Install Date    : ...
Install Reason  : Explicitly installed
Validated By    : Signature
```

Interpretación:

- **Depends On** — dependencias directas. Si una falla, este paquete deja de funcionar.
- **Required By** — reverse dependencies: qué paquetes dependen de este. `None` significa que se puede eliminar sin romper nada.
- **Install Reason** — `Explicitly installed` (lo instalaste vos) vs `Installed as a dependency for another package` (vino arrastrado por otro).
- **Validated By** — `Signature` indica que la firma PGP se validó al instalar.

---

## 🎛️ Opciones principales

| Operación | Flag | Descripción |
|-----------|------|-------------|
| Sync | `-S` | Instalar o buscar en repositorios |
| Sync refresh | `-Sy` | Actualizar solo los índices (sin upgrade) |
| Full upgrade | `-Syu` | Refresh + actualizar todo el sistema (estándar) |
| Remove | `-R` | Eliminar paquete |
| Remove recursive | `-Rns` | Eliminar + dependencias no usadas + archivos de config |
| Query | `-Q` | Consultar la base de datos local |
| Upgrade local | `-U` | Instalar desde un archivo `.pkg.tar.zst` |
| Files | `-F` | Buscar en la base de datos de archivos remota |

| Opción | Descripción |
|--------|-------------|
| `-s` | Buscar (con `-S` o `-Q`) |
| `-i` | Información detallada |
| `-l` | Listar archivos del paquete |
| `-o` | Qué paquete posee un archivo (`-Qo`) |
| `-e` | Paquetes instalados explícitamente (`-Qe`) |
| `-d` | Paquetes instalados como dependencia (`-Qd`) |
| `-t` | Solo paquetes no requeridos por otros (`-Qdt`) |
| `-k` | Verificar checksums (`-Qk`, `-Qkk`) |
| `-y` | Refrescar índices |
| `-u` | Actualizar paquetes |
| `--noconfirm` | No preguntar confirmación |
| `--needed` | No reinstalar si ya está en la misma versión |
| `--overwrite` | Sobrescribir archivos en conflicto |
| `--ignore <paq>` | Omitir un paquete en la actualización |

---

## Bases de datos locales

| Ruta | Contiene |
|------|----------|
| `/var/lib/pacman/sync/*.db` | Índices descargados de cada repositorio remoto |
| `/var/lib/pacman/local/` | Base de datos de paquetes instalados (un directorio por paquete) |
| `/var/cache/pacman/pkg/` | Caché de paquetes descargados (`.pkg.tar.zst`) |
| `/var/lib/pacman/db.lck` | Lock de base de datos (si existe, pacman no puede correr) |
| `/etc/pacman.conf` | Configuración global y repositorios habilitados |
| `/etc/pacman.d/mirrorlist` | Mirrors remotos por país |
| `/etc/pacman.d/gnupg/` | Anillo de claves PGP de pacman-key |

### Caché y downgrades

La caché permite volver a una versión anterior sin descargar nada:

```bash
pacman -U /var/cache/pacman/pkg/nginx-1.26.1-1-x86_64.pkg.tar.zst
```

```bash
pacman -Sc      # Limpiar caché conservando las versiones instaladas
pacman -Scc     # Vaciar la caché por completo (perdés los downgrades)
```

### Lock de base de datos

Si aparece `error: unable to lock database`, existe `/var/lib/pacman/db.lck`. Primero verificar que no haya otro pacman corriendo y recién entonces borrarlo:

```bash
ps aux | grep -i pacman
rm /var/lib/pacman/db.lck
```

---

## Repositorios locales y remotos

### Remotos

Los repos se declaran en `/etc/pacman.conf`:

```text
[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

[multilib]
Include = /etc/pacman.d/mirrorlist
```

- `Include` trae la lista de mirrors desde `mirrorlist`.
- `pacman -Syu` refresca los índices de los repos habilitados.
- Si un paquete no aparece, puede estar en un repo no habilitado (ej. `multilib`).

### Locales

Tres formas de trabajar sin depender de internet:

1. **Instalar un archivo suelto:** `pacman -U ./paquete.pkg.tar.zst` (descargado manualmente o traído desde otra máquina).
2. **Repo local por path:** agregar en `pacman.conf` un repo con `Server = file:///ruta/al/repo`.
3. **Crear un repo local** con `repo-add`:

```bash
repo-add /ruta/repo.db.tar.gz /ruta/*.pkg.tar.zst
```

Esto es útil para mirrors internos, entornos offline o preparar un set de paquetes para otra máquina.

---

## Dependencias

| Comando | Qué muestra |
|---------|-------------|
| `pacman -Qi <paq>` | Dependencias directas (Depends On) y reverse (Required By) |
| `pacman -Qd` | Instalados como dependencia de otro |
| `pacman -Qe` | Instalados explícitamente |
| `pacman -Qdt` | Dependencias huérfanas (candidatas a eliminar) |
| `pacman -Qm` | Instalados que no están en repos oficiales (ej. AUR) |
| `pacman -D --asdeps <paq>` | Re-marcar como dependencia |
| `pacman -D --asexplicit <paq>` | Re-marcar como instalación explícita |

### Huérfanas

```bash
pacman -Qdt     # listar huérfanas
pacman -Rns <paquete-1> <paquete-2>   # eliminar las que confirmaste
```

> Revisar la lista antes de borrar: una huérfana puede ser un paquete que instalaste a mano y pacman no sabe que lo querés.

---

## Verificación e integridad (checksum)

### Integridad de archivos instalados

```bash
pacman -Qk <paq>      # Verifica que los archivos existan (rápido)
pacman -Qkk <paq>     # Verifica checksums MD5 y tamaños vs la BD local
pacman -Qkk           # Todo el sistema
pacman -Qkkk          # Fuerza checksum aun si el paquete lo deshabilitó
```

`pacman -Qkk` es el equivalente a `debsums -c` (Debian) o `apk audit` (Alpine): detecta archivos modificados o corruptos comparando contra lo registrado al instalar.

### Firmas PGP

Todos los paquetes de los repos oficiales llegan firmados. Si la firma no valida, la transacción aborta:

```bash
pacman-key --verify <archivo.pkg.tar.zst>   # Verificar firma de un paquete
pacman-key --refresh-keys                   # Actualizar el anillo de claves
pacman-key --populate archlinux             # Restaurar claves maestras
```

Causas típicas de fallo de firma: hora del sistema incorrecta o claves desactualizadas.

### Checksums en descargas manuales

Para cualquier archivo bajado a mano (tarball, `.deb`, `.rpm`, `.pkg.tar.zst`):

```bash
sha256sum archivo        # comparar con el valor publicado
md5sum archivo
```

### PKGBUILD (AUR)

Los paquetes de AUR se compilan con `makepkg` desde un `PKGBUILD`, que declara los checksums esperados de las fuentes:

```text
sha256sums=('a1b2c3...')
```

`makepkg` aborta si el checksum de la fuente descargada no coincide con el declarado. Si editás el PKGBUILD, regenerás los checksums con:

```bash
makepkg -g
```

---

## yay — wrapper AUR

**yay** es un wrapper de pacman que agrega acceso a AUR (Arch User Repository) manteniendo la misma sintaxis. Cualquier comando de pacman funciona igual, y si el paquete no está en los repos oficiales, busca en AUR.

```bash
yay -Syu                        # Actualizar sistema (repos + AUR)
yay -S <paquete>                # Instalar desde repos o AUR
yay -Ss <termino>               # Buscar en repos oficiales + AUR
yay -Qs <termino>               # Buscar entre los instalados
yay -Qi <paquete>               # Info de paquete instalado (BD local)
yay -Si <paquete>               # Info de paquete remoto (repos + AUR)
yay -G <paquete>                # Clonar el PKGBUILD al directorio actual
yay -P                          # Mostrar diffs del PKGBUILD vs lo instalado
```

Detalles:

- `yay -Qi` y `yay -Si` consultan las mismas bases de datos locales que pacman (`/var/lib/pacman/local/` y `/var/lib/pacman/sync/`).
- Los PKGBUILD descargados para compilar quedan en `~/.cache/yay/`.
- Al instalar de AUR, yay compila con `makepkg` y verifica los `sha256sums=` del PKGBUILD antes de compilar.

> ⚠️ Seguridad AUR: cualquiera puede publicar un PKGBUILD. Leerlo antes de instalar (`yay -G`) y preferir paquetes con buena reputación y mantenimiento.

### Practicá yay/AUR (instalar yay desde AUR)

yay no está en los repos oficiales: se instala compilando su PKGBUILD con `makepkg`. Flujo completo validado:

```bash
# 1. Dependencias de build (yay está escrito en Go)
pacman -S --needed --noconfirm git base-devel go

# 2. Crear un usuario de build: makepkg NO corre como root
useradd -m builder
echo "builder ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/builder

# 3. Clonar el PKGBUILD de yay y compilarlo como builder
git clone https://aur.archlinux.org/yay.git
chown -R builder:builder yay
cd yay && su builder -c "makepkg -si --noconfirm"
```

Verificar que quedó instalado y probar las consultas AUR (siempre como usuario normal, no root):

```bash
yay --version
yay -Ss google-chrome     # busca en AUR (resultados con prefijo aur/)
yay -Si google-chrome     # info remota: Repository: aur, Version, Popularity
```

Notas:

- `makepkg -si` necesita sudo sin password para instalar las dependencias de build y el paquete resultante.
- `makepkg` verifica los `sha256sums=` del PKGBUILD contra las fuentes descargadas antes de compilar.
- yay advierte con `Avoid running yay as root/sudo`: los builds de AUR no se hacen como root.

---

## 🔍 Uso en troubleshooting

### 1. Un binario no arranca o falla con error de librería

```bash
ldd /usr/bin/<binario> | grep "not found"
pacman -Qo /usr/bin/<binario>    # qué paquete lo instaló
pacman -Qkk <paquete>            # verificar integridad del paquete
pacman -S <paquete>              # reinstalar para restaurar archivos
```

### 2. Falta un archivo y no sabés de qué paquete es

```bash
pacman -Fy            # descargar la base de datos de archivos remota
pacman -F <archivo>   # buscar en repos sin instalar
```

### 3. Transacción falla por archivos en conflicto

```bash
pacman -S <paquete> --overwrite '/ruta/en/conflicto/*'
```

### 4. Transacción falla por dependencias

```bash
pacman -Syu           # actualizar todo primero (evita mezclar versiones)
pacman -Si <paquete>  # revisar Depends On
```

### 5. "target not found"

El paquete no existe o el repo no está habilitado:

```bash
pacman -Ss <termino>          # buscar el nombre correcto
grep -v '^#' /etc/pacman.conf | grep -E '^\[|Include'   # repos habilitados
```

### 6. Firma PGP inválida

```bash
timedatectl          # verificar que la hora del sistema sea correcta
pacman-key --refresh-keys
```

### 7. El gestor se rompe a sí mismo

pacman usa `libcurl` para descargar: si una librería de la que depende el propio gestor desaparece (borrada a mano o por corrupción), **pacman deja de funcionar** y no puede repararse solo:

```bash
pacman -S curl
# pacman: error while loading shared libraries: libcurl.so.4: cannot open shared object file
```

La recuperación es **desde la caché de paquetes** (`/var/cache/pacman/pkg/`), donde pacman deja los `.pkg.tar.zst` descargados. Con `bsdtar` (viene en la base de Arch, libarchive) se extrae el paquete sin necesidad de pacman:

```bash
ls /var/cache/pacman/pkg/ | grep curl       # curl-8.21.0-1-x86_64.pkg.tar.zst
bsdtar -xpf /var/cache/pacman/pkg/curl-*.pkg.tar.zst -C /
pacman -Qkk curl                            # verificar que todo quedó íntegro
```

> Moraleja: no vaciar la caché (`pacman -Scc`) si no hay otra fuente de paquetes: es la red de seguridad cuando el gestor se rompe. Ver [`scenario`](../scenarios/system/16-package-dependencies-broken.md) para el runbook completo con las tres distros.

---

## 🛠️ Combinación con otras herramientas

- `pacman -Ql nginx | grep /etc/` — archivos de configuración de un paquete.
- `pacman -Qo $(command -v curl)` — de qué paquete viene `curl`.
- `pacman -Ss nginx` + `pacman -Si nginx` — decidir antes de instalar.
- `pacman -Qe | sort` — auditar qué instalaste explícitamente.
- `pacman -Qdt` + `pacman -Rns` — limpiar dependencias huérfanas.
- `pactree nginx` y `pactree -r nginx` — árbol de dependencias directo e inverso (paquete `pacman-contrib`).
- `checkupdates` — listar actualizaciones disponibles sin modificar la BD (paquete `pacman-contrib`).
- `rankmirrors` — ordenar `mirrorlist` por velocidad (paquete `pacman-contrib`).

---

## 💡 Uno-liners imprescindibles

```bash
pacman -Syu                    # actualizar todo el sistema
pacman -Ss nginx               # buscar paquete
pacman -Qi nginx               # info del instalado
pacman -Si nginx               # info del remoto
pacman -Ql nginx               # archivos del paquete
pacman -Qo /usr/bin/curl       # quién provee un archivo
pacman -Qkk                    # verificar integridad de todo el sistema
pacman -Qdt                    # dependencias huérfanas
pacman -U /var/cache/pacman/pkg/nginx-1.26.1-1-x86_64.pkg.tar.zst  # downgrade
```

---

## ⚠️ Errores comunes

| Error | Causa | Acción |
|-------|-------|--------|
| `error: target not found: <paq>` | Paquete inexistente o repo no habilitado | `pacman -Ss <paq>`; verificar `pacman.conf` |
| `error: unable to lock database` | `db.lck` presente | Verificar que no haya pacman activo y borrar el lock |
| `failed to commit transaction (conflicting files)` | El paquete pisa archivos de otro | `pacman -S <paq> --overwrite` |
| `invalid or corrupted package (PGP signature)` | Firma inválida: hora o claves viejas | `timedatectl`; `pacman-key --refresh-keys` |
| `could not satisfy dependencies` | Dependencias en conflicto | `pacman -Syu` primero; revisar `Depends On` |
| `warning: downgrading package` | `-U` con versión anterior | Esperado en un downgrade |
| `error: failed retrieving file ... 404` | Paquete borrado del mirror | `pacman -Syu` para refrescar índices |

---

## ✅ Buenas prácticas

- Correr `pacman -Syu` completo antes de instalar cualquier cosa.
- Nunca usar `pacman -Sy <paquete>` sin upgrade: instala con índices parciales y genera dependencias rotas.
- Revisar `pacman -Qdt` antes de borrar huérfanas.
- No vaciar la caché con `-Scc` si querés poder hacer downgrades.
- Verificar integridad después de un fallo: `pacman -Qkk`.
- En Dockerfiles de Arch: `pacman -Syu --noconfirm` y cerrar con `pacman -Scc` para reducir el tamaño de imagen.
- En AUR: leer el PKGBUILD antes de compilar; desconfiar de paquetes nuevos sin mantenimiento.

---

## 🔗 Referencias internas

- [`package-managers`](../reference/package-managers.md) — equivalencias entre apt, apk, yum/dnf y pacman
- [`apk`](apk.md) — gestor de paquetes de Alpine (equivalente minimalista)
- [`curl`](curl.md) — descargar paquetes manualmente desde mirrors
- [`wget`](wget.md) — alternativa a curl para descargas
- [`tar`](tar.md) — extraer tarballs y fuentes de AUR
- [`scenario`](../scenarios/system/03-new-server-provisioning.md) — provisioning de servidor nuevo
- [`scenario`](../scenarios/infrastructure/02-build-pyme-infrastructure.md) — instalación de servicios en infraestructura PYME
