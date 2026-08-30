# 🧩 Escenario: Dependencias de paquetes rotas — binario que no arranca

**Dominio:** system
**Nivel:** 🟡 Intermedio
**Herramientas:** `ldd`, `apt`, `dpkg`, `apk`, `debsums`
**Archivos:** `labs/docker-compose.system-packages.yml`

---

## 🎯 Problema

Un binario que funcionaba ayer hoy no arranca con `error while loading shared libraries`. Los gestores de paquetes muestran estados raros o dependencias insatisfechas. Necesitás:

- identificar qué paquete está roto y qué librería falta;
- verificar si es corrupción (checksum) o simple ausencia;
- reparar sin reinstalar todo el sistema;
- dejar el sistema verificado y reproducible.

---

## ⚡ Quick command (SRE)

```bash
ldd /usr/bin/curl | grep "not found"
```

---

## ✅ Salida esperada

```text
libssl.so.3 => not found
```

Interpretación:

- **Un solo `not found`** → falta una librería puntual: el paquete que la provee se corrompió o se borró el archivo a mano.
- **Varios `not found` seguidos** → daño mayor (glibc/libc dañada o sistema comprometido): no parches, restaura desde backup.
- **Sin salida** → el binario está sano a nivel de enlace dinámico; el problema es otro (config, permisos, dependencia de servicio).

---

## 🧠 Diagnóstico

Una "dependencia rota" es un paquete cuyo estado registrado no coincide con lo que hay en disco o con lo que requieren otros paquetes. Causas típicas:

- archivo borrado a mano (liberar espacio, "limpieza" manual);
- instalación interrumpida (energía, kill del proceso, disco lleno);
- upgrade parcial o mezcla de repositorios;
- paquete de fuente externa con versiones incompatibles.

El diagnóstico se hace en tres capas:

```text
capa 1: enlace dinámico  → ldd <binario>          (qué librería falta)
capa 2: estado del gestor → dpkg -l / apk info     (qué dice la base de datos)
capa 3: checksums        → dpkg -V / debsums / pacman -Qkk
```

Si la capa 1 muestra `not found`, la capa 3 confirma si el archivo fue borrado o modificado: el checksum registrado al instalar no coincide con el disco. En Alpine, `apk audit` no detecta archivos borrados a mano: la confirmación es `apk info -L` del paquete propietario más el error de `ldd` (musl).

---

## 🛠️ Procedimiento (runbook)

### 1. Levantar el laboratorio

```bash
cd labs
docker compose -f docker-compose.system-packages.yml up -d
docker compose -f docker-compose.system-packages.yml ps
```

### 2. Confirmar el síntoma

```bash
docker exec -it pkg-debian sh
curl -v https://example.com
```

Salida esperada:

```text
curl: error while loading shared libraries: libssl.so.3: cannot open shared object file
```

### 3. Identificar la librería faltante con ldd

```bash
ldd /usr/bin/curl | grep "not found"
```

Salida esperada:

```text
libssl.so.3 => not found
```

### 4. Identificar qué paquete la provee

```bash
dpkg -S libssl.so.3
```

Salida esperada:

```text
libssl3:amd64: /usr/lib/x86_64-linux-gnu/libssl.so.3
```

El paquete propietario es `libssl3`, pero el binario roto es `curl`: ambos se reinstalan juntos.

### 5. Verificar el estado y la integridad del paquete

```bash
dpkg -l | grep -E 'curl|libssl'
dpkg -V curl libssl3
```

Salida esperada (extracto):

```text
missing     /usr/lib/x86_64-linux-gnu/libssl.so.3
```

Interpretación: `missing` indica que el archivo ya no existe en disco, mientras que el registro del paquete dice que debería estar. Otras marcas posibles: `5` (checksum distinto), `S` (tamaño), `M` (permisos).

Alternativa más legible con `debsums`:

```bash
apt install -y debsums
debsums -c curl libssl3
```

### 6. Reparar reinstalando el paquete

```bash
apt install --reinstall -y curl libssl3
```

O en un solo paso con `apt --fix-broken install` si dpkg reporta dependencias insatisfechas:

```bash
apt --fix-broken install
```

### 7. Verificar la reparación

```bash
ldd /usr/bin/curl | grep "not found"   # sin salida = OK
curl -v https://example.com            # responde
dpkg -V curl libssl3                   # sin líneas = checksums correctos
```

---

## 🧯 Mitigación

**Verificar:**

- `ldd <binario> | grep "not found"` sin salida.
- `dpkg -l | grep <paquete>` en estado `ii`.
- `dpkg -V <paquete>` sin diferencias.

**Acción:**

- Reinstalar el paquete propietario: `apt install --reinstall <paquete>`.
- Si hay dependencias insatisfechas: `apt --fix-broken install` + `dpkg --configure -a`.
- Si fue un incidente de seguridad, auditar todo el sistema con `debsums -c` y verificar la integridad antes de confiar en el host.

**Rollback:**

- Si un upgrade dejó versiones incompatibles: `apt-cache policy <paquete>` para ver versiones, instalar la anterior con `apt install <paquete>=<version>` y congelar con `apt-mark hold <paquete>`.
- En Arch Linux, el equivalente es reinstalar con `pacman -S <paquete> --overwrite` o volver a una versión de la caché con `pacman -U /var/cache/pacman/pkg/<paquete>-<version>.pkg.tar.zst`.

---

## ✅ Interpretación

- Un solo `not found` resuelto con un reinstall → corrupción puntual, sistema sano.
- Checksums distintos en varios paquetes → posible compromiso: auditar completo.
- `apt --fix-broken install` no termina → conflicto de repositorios: revisar `sources.list` y `apt-cache policy`.
- La verificación final con checksum (`dpkg -V` / `debsums`) es la que cierra el caso: sin ella solo sabés que el binario corre, no que el sistema quedó íntegro.

---

## 🐧 Variante Alpine (OpenRC)

El lab incluye `pkg-alpine` (misma falla con `apk`). En Alpine la libc es musl y `ldd` no imprime `not found`: reporta `Error loading shared library`. La detección y reparación:

```bash
docker exec -it pkg-alpine sh
ldd /usr/bin/curl 2>&1 | grep -i "error loading"              # qué librería falta
apk info -R curl                                             # dependencias (libcurl)
apk info -L libcurl                                          # archivos del paquete propietario
apk del curl && apk add curl                                 # reinstalar limpio (restaura archivos)
ldd /usr/bin/curl 2>&1 | grep -i "error loading"             # sin salida = OK
```

Nota: en musl la línea que importa es `Error loading shared library libcurl.so.4`; las líneas `Error relocating ... symbol not found` son ruido del mismo fallo. `apk fix` repara transacciones interrumpidas (estados rotos en la base de datos), pero **no restaura archivos borrados a mano**: para eso hay que reinstalar el paquete (`apk del` + `apk add`).

En Alpine no existe systemctl; los servicios se administran con `rc-service` y `rc-update`. Para paquetes que no están en los repos habilitados, verificar `/etc/apk/repositories` (repo `community` suele estar comentado).

---

## 🐧 Variante Arch Linux (pacman)

El lab incluye `pkg-arch` (misma falla con pacman). Arch usa glibc, así que `ldd` imprime `not found` igual que Debian. Pero hay un giro: **en Arch, pacman mismo depende de libcurl**, así que borrar `libcurl.so.4` rompe también al gestor.

```bash
docker exec -it pkg-arch sh
ldd /usr/bin/curl | grep "not found"        # libcurl.so.4 => not found
pacman -S curl                              # FALLA: error while loading shared libraries
```

No podés reparar con el gestor porque el gestor está roto: hay que restaurar el archivo **desde la caché de paquetes** (`/var/cache/pacman/pkg/`), donde pacman dejó el `.pkg.tar.zst` al instalar:

```bash
ls /var/cache/pacman/pkg/ | grep curl       # curl-8.21.0-1-x86_64.pkg.tar.zst
bsdtar -xpf /var/cache/pacman/pkg/curl-*.pkg.tar.zst -C /
```

Verificar que el gestor y el binario volvieron:

```bash
ldd /usr/bin/curl | grep "not found"        # sin salida = OK
pacman -Qkk curl                            # 565 total files, 0 altered files
pacman -Qo /usr/lib/libcurl.so.4            # owned by curl 8.21.0-1
curl -s -o /dev/null -w "%{http_code}" https://example.com
```

Notas:

- `pacman -Qkk` compara checksums contra la BD local (`/var/lib/pacman/local/`) y reporta archivos faltantes o modificados.
- `bsdtar` viene en la base de Arch (libarchive): extrae el paquete sin necesidad de pacman.
- Si la caché no tuviera el paquete, la alternativa es descargarlo del mirror con cualquier medio disponible (wget/curl desde otra máquina) y extraerlo igual.
- Si otro paquete pisa archivos, reinstalar con `pacman -S <paquete> --overwrite '*'`.

---

## 🔗 Referencias

- [`guides/apt.md`](../../guides/apt.md) — dependencias rotas y checksums en Debian/Ubuntu
- [`guides/apk.md`](../../guides/apk.md) — dependencias y reinstalación con `apk`
- [`guides/pacman.md`](../../guides/pacman.md) — `pacman -Qkk` y reparación en Arch Linux
- [`guides/docker_debug_container.md`](../../guides/docker_debug_container.md) — diagnosticar sin ensuciar el host
- [`reference/package-managers.md`](../../reference/package-managers.md) — equivalencias entre gestores de paquetes
- [`labs/README.md`](../../labs/README.md) — instrucciones de los laboratorios
