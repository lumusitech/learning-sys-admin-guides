# apt — Guía completa

**Nivel:** 🟢 Básico
**Archivos de práctica:** Sistema Debian/Ubuntu en vivo
**Ver escenarios relacionados:** [`system/03-new-server-provisioning`](../scenarios/system/03-new-server-provisioning.md), [`infrastructure/01-migrate-to-production`](../scenarios/infrastructure/01-migrate-to-production.md), [`infrastructure/02-build-pyme-infrastructure`](../scenarios/infrastructure/02-build-pyme-infrastructure.md)

---

## ⚡ Quick command

`apt install <paquete>`

---

## ⚡ Quick run

```bash
apt update && apt upgrade -y
```

---

## 📑 Índice

1. [¿Qué es apt?](#qué-es-apt)
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

## 🧠 ¿Qué es apt?

**apt** (Advanced Package Tool) es el gestor de paquetes de Debian y derivados (Ubuntu, Mint, Raspbian). Es un *frontend* sobre **dpkg**: apt resuelve dependencias, descarga de repositorios y orquesta, mientras dpkg es quien realmente instala, configura y registra cada paquete `.deb`.

Se usa para:

- instalar, actualizar y eliminar paquetes desde repositorios;
- resolver dependencias automáticamente;
- buscar qué paquete provee un binario o archivo;
- instalar archivos `.deb` sueltos;
- auditar el estado del sistema de paquetes.

Tres niveles de herramientas:

- `apt` / `apt-get` — alto nivel: resuelve dependencias y descarga.
- `apt-cache` — consultas a la base de datos de paquetes (info, búsqueda).
- `dpkg` — bajo nivel: instala `.deb` individuales y mantiene la base de datos local.

---

## 🧠 Modelo mental

```text
repositorios remotos → apt download → /var/cache/apt/archives/ → dpkg -i → sistema
                                            |
                                     /var/lib/dpkg/status   (registro de lo instalado)
```

- `apt update` baja los *índices* de los repos (qué versiones existen) a `/var/lib/apt/lists/`.
- `apt install` resuelve dependencias, descarga los `.deb` a la caché y llama a dpkg para instalarlos.
- dpkg registra todo en `/var/lib/dpkg/status` (estado de cada paquete, checksums incluidos).
- El sistema "no se rompe" si los índices están desactualizados, pero `apt` no encuentra paquetes nuevos hasta hacer `apt update`.

> Pensá en apt como un proveedor que trae la mercadería y en dpkg como el estante donde se guarda cada caja con su inventario.

---

## 📝 Sintaxis básica

```bash
apt update                                # Actualizar índices de repositorios
apt upgrade -y                            # Actualizar paquetes instalados
apt install -y nginx                      # Instalar (resuelve dependencias)
apt remove nginx                          # Eliminar (deja la config)
apt purge nginx                           # Eliminar + archivos de configuración
apt autoremove                            # Eliminar dependencias no usadas
apt search nginx                          # Buscar paquetes
apt show nginx                            # Info detallada de un paquete
apt list --installed                      # Paquetes instalados
apt list --upgradable                     # Paquetes con actualización pendiente
```

Con dpkg:

```bash
dpkg -i ./paquete.deb                     # Instalar un archivo .deb (sin dependencias)
dpkg -r nginx                             # Eliminar paquete
dpkg -L nginx                             # Archivos que instala un paquete
dpkg -S /usr/bin/ls                       # Qué paquete provee un archivo
dpkg -l | less                            # Listado con estados
dpkg --configure -a                       # Reparar configuraciones pendientes
```

> `apt install ./paquete.deb` instala un `.deb` local **y** resuelve sus dependencias desde los repos. `dpkg -i` solo instala, y si faltan dependencias deja el paquete en estado roto.

---

## 🔑 Salida clave

`dpkg -l | grep nginx` (estado de paquetes):

```text
Desired=Unknown/Install/Remove/Purge/Hold
| Status=Not/Inst/Conf-files/Unpacked/half-conf/Half-inst/trig-aWait/Trig-pend
|/ Err?=(none)/Reinst-required (Status,Err: uppercase=bad)
||/ Name           Version           Architecture Description
+++-==============-=================-============-=================================
ii  nginx          1.24.0-1          amd64        small, powerful ...
```

El primer campo (dos letras) es el estado:

| Estado | Significado |
|--------|-------------|
| `ii` | Instalado y configurado correctamente |
| `iU` | Desempaquetado pero sin configurar (instalación a medias) |
| `iF` | Half-configured: falló la configuración |
| `iH` | Half-installed: falló el desempaquetado |
| `rc` | Eliminado, pero quedan archivos de configuración |
| `un` | Desconocido: registrado pero nunca instalado |

Cualquier estado que no sea `ii` o `rc` indica un paquete roto que hay que reparar.

`apt show nginx` (info de paquete):

```text
Package: nginx
Version: 1.24.0-1
Priority: optional
Section: httpd
Installed-Size: 760 kB
Depends: libc6 (>= 2.34), libssl3, zlib1g
Recommends: nginx-common
```

Interpretación:

- **Depends** — dependencias duras. Si no se pueden satisfacer, la instalación falla.
- **Recommends** — dependencias suaves (se instalan por defecto salvo `--no-install-recommends`).

---

## 🎛️ Opciones principales

| Comando | Descripción |
|---------|-------------|
| `apt update` | Refrescar índices de repositorios |
| `apt upgrade` | Actualizar paquetes instalados |
| `apt full-upgrade` | Upgrade con resolución de cambios de dependencias |
| `apt install <paq>` | Instalar paquete |
| `apt remove <paq>` | Eliminar paquete |
| `apt purge <paq>` | Eliminar + config |
| `apt autoremove` | Eliminar dependencias huérfanas |
| `apt search <termino>` | Buscar por nombre/descripción |
| `apt show <paq>` | Info detallada |
| `apt list --installed` | Listar instalados |
| `apt list --upgradable` | Listar actualizables |
| `apt-file search <ruta>` | Qué paquete provee un archivo (instalar `apt-file` antes) |

| Opción (dpkg) | Descripción |
|---------------|-------------|
| `-i <file.deb>` | Instalar un archivo |
| `-r <paq>` | Eliminar |
| `-P <paq>` | Purge (eliminar + config) |
| `-L <paq>` | Listar archivos del paquete |
| `-S <archivo>` | Qué paquete posee un archivo |
| `-l` | Listar con estados |
| `-V` | Verificar checksums de archivos instalados |
| `--configure -a` | Configurar todos los paquetes pendientes |

---

## Bases de datos locales

| Ruta | Contiene |
|------|----------|
| `/var/lib/dpkg/status` | Registro maestro: estado, versión, dependencias y checksums de cada paquete |
| `/var/lib/dpkg/info/` | Scripts de instalación (`*.postinst`, `*.prerm`) y listas de archivos (`*.list`) |
| `/var/lib/dpkg/updates/` | Cambios pendientes de aplicar (si quedan archivos, hay un estado a medio aplicar) |
| `/var/lib/apt/lists/` | Índices descargados de los repositorios (`*Packages`, `*Release`) |
| `/var/cache/apt/archives/` | Caché de `.deb` descargados |
| `/var/lib/apt/extended_states` | Registro de paquetes auto-instalados (para `autoremove`) |

### Caché

```bash
apt clean        # Vaciar /var/cache/apt/archives/
apt autoclean    # Borrar solo los .deb que ya no se pueden descargar
```

### Estado a medio aplicar

Si `/var/lib/dpkg/updates/` tiene archivos, dpkg quedó a mitad de una operación. Se reanuda con:

```bash
dpkg --configure -a
```

---

## Repositorios locales y remotos

### Remotos

Los repos se declaran en `/etc/apt/sources.list` y `/etc/apt/sources.list.d/*.list`:

```text
deb http://deb.debian.org/debian bookworm main contrib non-free
deb [signed-by=/etc/apt/keyrings/nginx.gpg] https://nginx.org/packages/debian/ bookworm nginx
```

- `deb` = binarios; `deb-src` = fuentes.
- `main`, `contrib`, `non-free` = secciones del repo (Debian). En Ubuntu: `main`, `universe`, `multiverse`, `restricted`.
- `signed-by` firma las descargas con una clave GPG específica (recomendado sobre agregar claves globalmente).

Verificar repos habilitados:

```bash
apt-cache policy
grep -r '^deb ' /etc/apt/sources.list /etc/apt/sources.list.d/
```

### Locales

1. **Instalar un `.deb` suelto:** `apt install ./paquete.deb` (resuelve dependencias desde los repos configurados).
2. **Repo local por path** en `sources.list.d`, ej. `deb [trusted=yes] file:///ruta/al/repo ./`.
3. **Descargar sin instalar** para llevar a otra máquina (offline):

```bash
apt-get download nginx          # descarga el .deb al directorio actual
apt-get download $(apt-cache depends --recurse --no-recommends --no-suggests --no-conflicts --no-breaks --no-replaces --no-enhances nginx | grep '^\w' | sort -u)
```

### Firmas GPG

- Claves de repos oficiales: `/etc/apt/trusted.gpg.d/` y `/etc/apt/trusted.gpg`.
- Repos propios: clave en `/etc/apt/keyrings/` referenciada con `signed-by`.
- `apt-key` está deprecado; no usar para repos nuevos.

---

## Dependencias

| Comando | Qué muestra |
|---------|-------------|
| `apt depends <paq>` | Dependencias de un paquete |
| `apt rdepends <paq>` | Reverse dependencies (quién depende de él) |
| `apt-cache show <paq>` | Depends/Recommends declarados |
| `apt-mark hold <paq>` | Congelar un paquete en su versión |
| `apt-mark unhold <paq>` | Descongelar |
| `apt-mark showhold` | Listar congelados |
| `apt autoremove --dry-run` | Ver qué dependencias huérfanas se eliminarían |

### Dependencias rotas

El estado de dependencias se evalúa contra `/var/lib/dpkg/status`:

```bash
apt install -f        # equivalente a apt --fix-broken install
apt --fix-broken install
```

Esto repara paquetes con dependencias insatisfechas (estados `iF`, `iH`, `iU`).

---

## Verificación e integridad (checksum)

### Integridad de archivos instalados

```bash
dpkg -V <paq>        # Verifica checksums de los archivos del paquete vs la BD
dpkg -V              # Todo el sistema (lento, requiere lectura completa)
debsums -c           # Igual pero con el paquete debsums instalado (más flexible)
```

`dpkg -V` compara los archivos en disco contra los checksums MD5/SHA registrados en `/var/lib/dpkg/status`. Archivos modificados aparecen con la letra del atributo alterado (`5` = MD5 distinto, `S` = tamaño, `M` = permisos).

### Integridad de un `.deb` antes de instalarlo

```bash
dpkg-deb --info ./paquete.deb        # Metadatos (dependencias, versión)
dpkg-deb --contents ./paquete.deb    # Lista de archivos del paquete
dpkg-deb --field ./paquete.deb MD5sum  # Checksum declarado (paquetes viejos)
```

### Checksums en descargas manuales

Para cualquier archivo bajado a mano (`.deb`, `.tar.gz`, `.rpm`):

```bash
sha256sum archivo        # comparar con el valor publicado
md5sum archivo
```

---

## Alternativa: probar sin instalar

Para probar una herramienta sin ensuciar el sistema con paquetes, se puede usar un contenedor efímero con herramientas preinstaladas:

```bash
docker run --rm -it --net=host --pid=host nicolaka/netshoot
```

Es especialmente útil para probar utilidades de red (curl, dig, tcpdump) que no querés instalar en el host. Ver la guía `docker_debug_container` para qué se puede testear y qué solo funciona en el host nativo.

---

## 🔍 Uso en troubleshooting

### 1. La instalación falla con dependencias insatisfechas

```bash
apt update && apt install -f
dpkg --configure -a
```

Si un paquete quedó a medias (`iU`, `iF`, `iH`):

```bash
dpkg --audit          # lista paquetes en estado inconsistente
dpkg --configure -a   # reanudar configuraciones pendientes
apt --fix-broken install
```

### 2. "E: Unable to locate package"

Índices viejos o repo no configurado:

```bash
apt update
apt search <termino>                 # verificar el nombre real
grep -r '^deb ' /etc/apt/sources.list /etc/apt/sources.list.d/
```

### 3. "E: Unmet dependencies" con paquetes de fuentes externas

Mezclar repos con versiones incompatibles rompe el árbol de dependencias:

```bash
apt --fix-broken install
apt policy <paquete>        # ver qué versiones vienen de qué repo
apt-mark hold <paquete>     # congelar si la versión del repo es la que rompe
```

### 4. Un binario no arranca por librería faltante

```bash
ldd /usr/bin/<binario> | grep "not found"
dpkg -S /usr/bin/<binario>          # qué paquete lo instaló
dpkg -V <paquete>                   # verificar integridad
apt install --reinstall <paquete>   # restaurar archivos originales
```

### 5. Falló un `dpkg -i` de un `.deb` manual

```bash
dpkg --audit
apt install -f          # dejar que apt repare lo que dpkg dejó a medias
```

### 6. Paquete con estado raro en `dpkg -l`

Cualquier estado que no sea `ii`/`rc` requiere acción:

```bash
dpkg --configure -a
apt --fix-broken install
apt install --reinstall <paquete>
```

---

## 🛠️ Combinación con otras herramientas

- `dpkg -S $(command -v curl)` — de qué paquete viene `curl`.
- `dpkg -L nginx | grep /etc/` — archivos de configuración de un paquete.
- `apt-cache policy nginx` — versiones disponibles por repo.
- `apt list --upgradable` + `apt upgrade --dry-run` — ver el impacto antes de actualizar.
- `apt-get download <paq>` + `dpkg-deb --contents` — inspeccionar un paquete sin instalarlo.
- `debsums -c 2>/dev/null | head` — detectar archivos alterados (incidentes de seguridad).
- `apt-mark hold` + `apt-mark showhold` — congelar versiones en producción.

---

## 💡 Uno-liners imprescindibles

```bash
apt update && apt upgrade -y        # actualizar sistema
apt search nginx                    # buscar paquete
apt show nginx                      # info detallada
apt install -y nginx                # instalar
dpkg -L nginx                       # archivos del paquete
dpkg -S /usr/bin/ls                 # quién provee un archivo
dpkg -l | grep -v '^ii'             # paquetes que NO están bien instalados
apt --fix-broken install            # reparar dependencias rotas
dpkg --configure -a                 # reanudar instalaciones a medias
dpkg -V nginx                       # verificar integridad de un paquete
```

---

## ⚠️ Errores comunes

| Error | Causa | Acción |
|-------|-------|--------|
| `E: Unable to locate package` | Índices viejos o repo no configurado | `apt update`; verificar `sources.list` |
| `E: Unmet dependencies` | Dependencias insatisfechas (paquete roto) | `apt --fix-broken install` |
| `dpkg: error processing package` | Instalación interrumpida | `dpkg --configure -a` |
| `E: Sub-process /usr/bin/dpkg returned an error code` | Un script de mantenimiento falló | Ver `dpkg --audit`; `apt install -f` |
| `E: Could not open lock file /var/lib/dpkg/lock` | Otro apt/dpkg corriendo | Esperar; verificar con `ps aux \| grep apt` |
| `held broken packages` | Conflicto de versiones entre repos | `apt-cache policy`; `apt-mark hold` |
| `W: GPG error: ... NO_PUBKEY` | Clave del repo no instalada | Agregar la clave del repo con `signed-by` |
| `E: The repository ... does not have a Release file` | Repo deshabilitado en el mirror | Corregir `sources.list`; `apt update` |

---

## ✅ Buenas prácticas

- Correr `apt update` antes de `apt install` en un sistema que no se toca hace tiempo.
- Preferir `apt install ./paquete.deb` sobre `dpkg -i` para archivos locales (resuelve dependencias).
- No mezclar repos de terceros con versiones incompatibles: usar `signed-by` y `apt-cache policy` para auditar.
- Usar `--dry-run` (o `-s`) en upgrades grandes: `apt upgrade --dry-run`.
- Congelar con `apt-mark hold` paquetes críticos en producción.
- Tras un incidente de seguridad, correr `debsums -c` para detectar binarios alterados.
- No borrar `/var/lib/dpkg/status` ni `/var/lib/apt/lists/` a mano: rompés el inventario del sistema.

---

## 🔗 Referencias internas

- [`package-managers`](../reference/package-managers.md) — equivalencias entre apt, apk, yum/dnf y pacman
- [`apk`](apk.md) — gestor de paquetes de Alpine (equivalente minimalista)
- guía `docker_debug_container` — probar herramientas sin ensuciar el host
- [`curl`](curl.md) — descargar paquetes manualmente
- [`wget`](wget.md) — alternativa a curl para descargas
- [`tar`](tar.md) — extraer tarballs con fuentes
- [`scenario`](../scenarios/system/03-new-server-provisioning.md) — provisioning de servidor nuevo
- [`scenario`](../scenarios/infrastructure/02-build-pyme-infrastructure.md) — instalación de servicios en infraestructura PYME
