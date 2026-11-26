# diff — Guía completa de comparación de archivos

**Nivel:** 🟡 Intermedio
**Archivos de práctica:** Funciona en cualquier sistema; los ejemplos usan snapshots de `/etc` (no requiere lab)
**Ver escenarios relacionados:** [`system/15-config-drift`](../scenarios/system/15-config-drift.md), [`security/02-suid-audit-and-file-permissions`](../scenarios/security/02-suid-audit-and-file-permissions.md), [`infrastructure/10-backup-restore-drill`](../scenarios/infrastructure/10-backup-restore-drill.md)

---

## ⚡ Quick command

`diff -u /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak`

> ⚠️ `diff` devuelve **exit code 1 cuando hay diferencias**. En scripts con `set -e` eso aborta la ejecución: tratalo explícitamente.

---

## ⚡ Quick run

```bash
cp -a /etc /tmp/etc-antes
# ... pasa el tiempo, alguien toca la configuración ...
diff -rq /tmp/etc-antes /etc
```

---

## 📑 Índice

1. [¿Qué es diff?](#qué-es-diff)
2. [Modelo mental](#modelo-mental)
3. [Sintaxis básica](#sintaxis-básica)
4. [Salida clave](#salida-clave)
5. [Opciones principales](#opciones-principales)
6. [Patrones de uso](#patrones-de-uso)
7. [Uso en troubleshooting](#uso-en-troubleshooting)
8. [Combinación con otras herramientas](#combinación-con-otras-herramientas)
9. [Uno-liners imprescindibles](#uno-liners-imprescindibles)
10. [Errores comunes](#errores-comunes)
11. [Buenas prácticas](#buenas-prácticas)
12. [Referencias internas](#referencias-internas)

---

## 🧠 ¿Qué es diff?

`diff` compara dos archivos —o dos árboles de directorios— **línea por línea** y reporta los bloques que no coinciden. No dice si el cambio es correcto: dice **qué cambió**.

Es la herramienta base de tres tareas cotidianas:

- **detectar config drift**: comparar la configuración actual contra una copia conocida como buena
- **auditar**: comparar un inventario (SUID, claves SSH, cron) contra la baseline
- **verificar backups**: comprobar que el destino tiene el mismo contenido que el origen

Y es la mitad de un ciclo de parcheo: `diff -u` genera el parche, `patch` lo aplica.

Lo que `diff` **no** hace:

- no compara permisos, propietario ni timestamps (solo contenido y nombres)
- no compara bien archivos binarios (para eso, `cmp` o `sha256sum`)
- no resuelve conflictos de merge (para eso, `git diff`/`git merge`)

---

## 🧠 Modelo mental

Pensá en `diff` como **superponer dos fotos de la misma configuración** y quedarte solo con los píxeles que no coinciden.

- La foto A es la referencia: el backup, la baseline, el paquete original.
- La foto B es el presente: el archivo en producción.
- `diff` te muestra las zonas donde A y B no se solapan.

El **exit code** es la respuesta para una máquina; el texto es la respuesta para un humano:

| Exit code | Significado | Qué hacer |
|-----------|-------------|-----------|
| `0` | Sin diferencias | Nada |
| `1` | Hay diferencias | Leer el detalle |
| `2` | Error (archivo inexistente, sin permisos) | Revisar rutas y permisos |

La regla mental: **`diff` no juzga, informa**. Si el resultado te sorprende, la pregunta correcta no es "¿por qué diff dice esto?" sino "¿quién cambió B y cuándo?".

---

## 📝 Sintaxis básica

```text
diff [opciones] archivo1 archivo2
diff [opciones] directorio1 directorio2
comando | diff - archivo
```

Casos típicos:

```bash
diff /etc/hosts /etc/hosts.bak                  # formato normal
diff -u /etc/hosts /etc/hosts.bak               # formato unificado (el más legible)
diff -r /etc/nginx /etc/nginx.bak               # árbol de directorios
diff -q /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak   # solo "difieren o no"
```

Comparar contra stdin con `-`:

```bash
ps aux | diff - /tmp/ps-ayer.txt
```

---

## 🔑 Salida clave

### Formato normal (por defecto)

```text
3c3,4
< proxy_pass http://10.0.0.5:8080;
---
> proxy_pass http://10.0.0.9:8080;
> client_max_body_size 10m;
```

- `3c3,4` → línea 3 del primer archivo **cambia** (`c`) por las líneas 3-4 del segundo.
- `<` → contenido del primer archivo; `>` → contenido del segundo.
- Otros operadores: `a` (agregado), `d` (borrado).

### Formato unificado (`-u`)

```text
--- old.conf 2026-11-26 00:25:02.188133939 +0000
+++ new.conf 2026-11-26 00:25:02.188133939 +0000
@@ -1,3 +1,4 @@
 listen 80;
 server_name app.local;
-proxy_pass http://10.0.0.5:8080;
+proxy_pass http://10.0.0.9:8080;
+client_max_body_size 10m;
```

- `@@ -1,3 +1,4 @@` → desde la línea 1, 3 líneas en A y 4 líneas en B.
- `-` → solo en A; `+` → solo en B; espacio → contexto igual en ambos.
- Es el formato que consumen `patch` y los revisores de código.

### Formato contexto (`-c`)

```text
*** old.conf 2026-11-26 00:25:02.188133939 +0000
--- new.conf 2026-11-26 00:25:02.188133939 +0000
***************
*** 1,3 ****
  listen 80;
  server_name app.local;
! proxy_pass http://10.0.0.5:8080;
--- 1,4 ----
  listen 80;
  server_name app.local;
! proxy_pass http://10.0.0.9:8080;
! client_max_body_size 10m;
```

Más verboso que `-u`, pero es POSIX y sirve en sistemas muy antiguos.

### Mensajes de resumen

| Salida | Significado |
|--------|-------------|
| `Files a.conf and b.conf differ` | `-q`: el contenido difiere |
| `Files a.conf and b.conf are identical` | `-s`: son iguales |
| `Only in d2: f2` | El archivo existe en un árbol y no en el otro |
| `Binary files a and b differ` | Son binarios: usar `cmp` o checksums |

> ⚠️ Las cabeceras `---`/`+++` incluyen la fecha del archivo. Dos ejecuciones del mismo `diff -u` producen parches con cabeceras distintas. `patch` las ignora, pero si comparás parches entre sí, usá `--label` (GNU/BSD) o filtrá las dos primeras líneas.

---

## 🎛️ Opciones principales

| Opción | Qué hace | Cuándo usarla |
|--------|----------|---------------|
| `-u` | Formato unificado con 3 líneas de contexto | Leer cambios y generar parches |
| `-c` | Formato contexto (POSIX) | Compatibilidad con sistemas antiguos |
| `-q` | Solo informa si difieren | Scripts y chequeos rápidos |
| `-r` | Recorre directorios recursivamente | Comparar árboles completos |
| `-N` | Trata un archivo ausente como vacío | Verificar backups y árboles con archivos nuevos |
| `-i` | Ignora mayúsculas/minúsculas | Configs con casing inconsistente |
| `-w` | Ignora todo el espacio en blanco | Ruido de indentación |
| `-b` | Ignora cambios en la cantidad de espacios | Reformatting sin cambio semántico |
| `-B` | Ignora líneas en blanco | Archivos con separadores distintos |
| `-a` | Trata binarios como texto | Inspeccionar un binario con cuidado |
| `-s` | Reporta también los archivos idénticos | Inventario completo de un árbol |
| `-x patrón` | Excluye archivos que coincidan | Comparar árboles con logs o caché |
| `-y` | Comparación lado a lado | Leer cambios en pantalla ancha |
| `--label` | Reemplaza el nombre/fecha en la cabecera | Parches reproducibles |

> ⚠️ **Compatibilidad**: en Alpine/BusyBox funcionan `-u`, `-c`, `-q`, `-r`, `-N`, `-i`, `-w`, `-b`, `-B`, `-a`, `-s`. **No** están disponibles `-y`, `-x`, `--label` ni `--color`. Si escribís un script para Alpine, evitá esas opciones.

---

## 📋 Patrones de uso

### 1. Config drift: detectar cambios no autorizados

Guardá una baseline y compará después:

```bash
cp -a /etc /var/backups/etc-$(date +%F)
# ... días después ...
diff -rq /var/backups/etc-2026-11-20 /etc
```

Salida típica:

```text
Files /var/backups/etc-2026-11-20/nginx/nginx.conf and /etc/nginx/nginx.conf differ
Only in /etc/cron.d: backup-rogue
```

`-rq` te da el mapa; después abrís el detalle con `-u`:

```bash
diff -u /var/backups/etc-2026-11-20/nginx/nginx.conf /etc/nginx/nginx.conf
```

### 2. Auditoría SUID: comparar contra la baseline

```bash
find / -xdev -perm -4000 -type f 2>/dev/null | sort > /var/lib/baseline/suid.txt
# ... después ...
find / -xdev -perm -4000 -type f 2>/dev/null | sort > /tmp/suid-ahora.txt
diff -u /var/lib/baseline/suid.txt /tmp/suid-ahora.txt
```

Un `>` en la salida es un binario SUID nuevo: investigalo antes de cualquier otra cosa.

### 3. Verificar un backup

```bash
diff -rq /srv/data /mnt/backup/data
```

Si el backup está incompleto (faltan archivos), `-N` los muestra como altas:

```bash
diff -rN /srv/data /mnt/backup/data | grep '^Only in /srv/data'
```

> Para backups grandes, primero `rsync --dry-run --itemize-changes` es más rápido; `diff` confirma contenido.

### 4. Comparar inventarios entre dos servidores

```bash
ssh web01 'rpm -qa | sort' > /tmp/web01.txt
ssh web02 'rpm -qa | sort' > /tmp/web02.txt
diff -u /tmp/web01.txt /tmp/web02.txt
```

Lo mismo sirve para paquetes (`dpkg -l`), usuarios (`cut -d: -f1 /etc/passwd`), cron o módulos del kernel.

### 5. Generar y aplicar un parche

```bash
diff -u nginx.conf nginx.conf.nuevo > nginx.patch
cp nginx.conf nginx.conf.aplicado
patch -p0 nginx.conf.aplicado < nginx.patch
diff -q nginx.conf.aplicado nginx.conf.nuevo    # sin salida = idéntico
```

Rollback del parche:

```bash
patch -R -p0 nginx.conf.aplicado < nginx.patch
```

> `-p0` usa la ruta tal como está en el parche. Si el parche viene de un repo con rutas `a/` y `b/`, usá `-p1`.

### 6. Filtrar ruido de formato

```bash
diff -w old.conf new.conf      # ignora todo el espacio
diff -b old.conf new.conf      # ignora cambios de cantidad de espacios
diff -i old.conf new.conf      # ignora mayúsculas
diff -B old.conf new.conf      # ignora líneas en blanco
```

Si con `-w` sigue habiendo diferencias, el cambio es real.

### 7. Comparar contra un comando en vivo

```bash
ss -tlnp | diff - /tmp/ss-ayer.txt
```

El `-` le dice a `diff` que uno de los lados viene de stdin. Útil para comparar el estado actual contra una foto guardada.

### 8. Qué cambió desde una fecha

```bash
find /etc -newer /var/backups/etc-stamp -type f > /tmp/tocados.txt
diff -rq /var/backups/etc-2026-11-20 /etc | grep -F -f /tmp/tocados.txt
```

---

## 🔍 Uso en troubleshooting

### "Funcionaba ayer y hoy no"

1. Comparar la config actual contra el backup:

   ```bash
   diff -u /var/backups/nginx.conf /etc/nginx/nginx.conf
   ```

2. Si el archivo no tiene backup, comparar contra el paquete original:

   ```bash
   dpkg -V nginx                    # Debian/Ubuntu: archivos alterados
   rpm -Va --nofiledigest | grep nginx   # RHEL/Fedora
   ```

3. Revisar también archivos nuevos que el servicio lee sin que los busques:

   ```bash
   diff -rq /var/backups/etc-2026-11-20 /etc
   ```

### "¿Alguien tocó `/etc`?"

```bash
diff -rq /var/backups/etc-2026-11-20 /etc | grep -v '^Files .* differ$'
```

Filtrar los "differ" deja solo los archivos nuevos o eliminados: la señal más fuerte de un cambio manual.

### "¿El backup está completo?"

```bash
diff -rN /srv/data /mnt/backup/data | grep '^Only in /srv/data'
```

Si no hay salida, el backup tiene todos los archivos del origen.

### "¿Dos servidores están configurados igual?"

```bash
ssh web01 'cat /etc/nginx/nginx.conf' > /tmp/a.conf
ssh web02 'cat /etc/nginx/nginx.conf' > /tmp/b.conf
diff -u /tmp/a.conf /tmp/b.conf
```

### "¿Este binario cambió?"

`diff` no es la herramienta. Usá checksums:

```bash
sha256sum /usr/local/bin/app
# comparar contra el valor publicado o el de la baseline
```

### "Hay demasiadas diferencias y no veo nada"

Reducir el ruido antes de leer:

```bash
diff -u -w old new | grep '^[+-]' | grep -v '^[+-][+-]'
```

O comparar solo las líneas activas (sin comentarios):

```bash
grep -v '^[[:space:]]*#' old.conf > /tmp/a
grep -v '^[[:space:]]*#' new.conf > /tmp/b
diff -u /tmp/a /tmp/b
```

---

## 🛠️ Combinación con otras herramientas

| Combinación | Para qué |
|-------------|----------|
| `diff` + `find` | Comparar solo archivos modificados desde cierta fecha |
| `diff` + `sort` | Normalizar listas (paquetes, usuarios, SUID) antes de comparar |
| `diff` + `ssh` | Comparar configuración entre servidores |
| `diff` + `patch` | Ciclo completo: detectar, parchear, revertir |
| `diff` + `grep` | Filtrar el resultado a las líneas `+`/`-` |
| `diff` + `cmp` | Texto con `diff`, binarios con `cmp` |
| `diff` + `sha256sum` | Integridad de binarios y descargas |
| `diff` + `rsync --dry-run` | Ver qué transferiría un backup antes de ejecutarlo |

Ejemplo de `cmp` para binarios:

```bash
cmp -l /usr/local/bin/app /usr/local/bin/app.bak | head
```

`cmp` corta en el primer byte distinto y muestra el offset.

---

## 💡 Uno-liners imprescindibles

```bash
# ¿Difiere? (exit code 0 = igual, 1 = distinto)
diff -q a.conf b.conf

# Detalle legible de un archivo
diff -u /var/backups/nginx.conf /etc/nginx/nginx.conf

# Mapa de un árbol completo
diff -rq /var/backups/etc-2026-11-20 /etc

# Archivos que faltan en el backup
diff -rN /srv/data /mnt/backup/data | grep '^Only in /srv/data'

# SUID nuevo desde la baseline
find / -xdev -perm -4000 -type f 2>/dev/null | sort > /tmp/suid-ahora.txt
diff -u /var/lib/baseline/suid.txt /tmp/suid-ahora.txt

# Cambios en un archivo sin el ruido de espacios
diff -u -w old.conf new.conf

# Generar parche reproducible
diff -u --label a/nginx.conf --label b/nginx.conf nginx.conf nginx.conf.nuevo > nginx.patch

# Aplicar y verificar
patch -p1 < nginx.patch && diff -q nginx.conf nginx.conf.nuevo

# Comparar inventario de paquetes entre hosts
ssh web01 'rpm -qa | sort' > /tmp/web01.txt
ssh web02 'rpm -qa | sort' > /tmp/web02.txt
diff -u /tmp/web01.txt /tmp/web02.txt
```

> ⚠️ `--label` es GNU/BSD: en Alpine/BusyBox no existe. Para parches portables, quitá las dos primeras líneas del parche con `sed '1,2d'` o aceptá cabeceras con fecha.

---

## ⚠️ Errores comunes

### 1. `set -e` aborta cuando `diff` encuentra diferencias

```bash
set -e
diff -q a.conf b.conf     # exit 1 → el script muere acá
```

Correcto:

```bash
if diff -q a.conf b.conf >/dev/null; then
  echo "sin cambios"
else
  echo "hay cambios"
fi
```

### 2. Usar `diff` con binarios

```bash
diff app app.bak
# Binary files app and app.bak differ   ← no dice nada útil
```

Usá `cmp -l` o `sha256sum`.

### 3. Olvidar `-N` y creer que el backup está completo

Sin `-N`, un archivo que existe en el origen y no en el destino aparece como `Only in`, pero `diff` igual devuelve 1. `-N` convierte el ausente en vacío y muestra el contenido completo: útil para parches y para verificar.

### 4. Comparar directorios sin `-r`

```bash
diff /etc/nginx /etc/nginx.bak
# Common subdirectories: /etc/nginx/nginx.d and ...
```

No compara el contenido. Agregá `-r`.

### 5. Esperar que `diff` detecte cambios de permisos

`diff` compara contenido. Un `chmod 777` no aparece. Para metadata:

```bash
find /etc -type f -exec stat -c '%a %U %G %n' {} + | sort > /var/lib/baseline/etc-meta.txt
# ... después ...
find /etc -type f -exec stat -c '%a %U %G %n' {} + | sort > /tmp/etc-meta-ahora.txt
diff -u /var/lib/baseline/etc-meta.txt /tmp/etc-meta-ahora.txt
```

> `stat -c` es GNU/BusyBox; en BSD/macOS usá `stat -f '%Lp %Su %Sg %N'`. Lo que importa es normalizar el formato antes de comparar.

### 6. Aplicar un parche en el nivel de ruta equivocado

```bash
patch -p1 < nginx.patch
# can't find file to patch
```

Contá los componentes de la ruta en la cabecera: `a/nginx.conf` → `-p1`; `nginx.conf` → `-p0`.

### 7. Confiar en el orden de líneas

`diff` compara por posición. Si el archivo se regeneró con las líneas en otro orden, todo aparece como cambiado. Normalizá con `sort` antes de comparar listas.

### 8. Ignorar el exit code 2

Un `2` no es "hay diferencias": es un error (archivo inexistente, permisos). Un script que trata `2` como `1` va a reportar drift donde en realidad hay un problema de acceso.

---

## ✅ Buenas prácticas

- **Guardá la baseline fuera del árbol que comparás**: `/var/lib/baseline/`, no `/etc/baseline/`.
- **Nombrá la baseline con fecha**: `etc-2026-11-20` permite saber contra qué comparás.
- **Normalizá antes de comparar**: `sort`, quitar comentarios, quitar timestamps.
- **`-q` para scripts, `-u` para humanos**: no parsees la salida normal si solo necesitás el veredicto.
- **Tratá los exit codes como contrato**: `0` igual, `1` distinto, `2` error.
- **Para binarios, checksums**: `sha256sum` antes y después.
- **Verificá el parche antes de aplicarlo**: `patch --dry-run` (GNU/BSD) o aplicar sobre una copia.
- **Un parche por cambio lógico**: parches enormes son imposibles de revisar y de revertir.
- **Documentá el rollback**: `patch -R` con el mismo archivo de parche.

---

## 🔗 Referencias internas

- [`find`](find.md) — seleccionar archivos por fecha, permisos o tipo antes de comparar
- [`stat`](stat.md) — metadatos que `diff` no compara (permisos, propietario, timestamps)
- [`grep`](grep.md) — filtrar la salida de `diff` a las líneas relevantes
- [`sort`](sort.md) — normalizar listas antes de comparar
- [`ssh`](ssh.md) — traer la configuración de otro servidor para comparar
- [`rsync`](rsync.md) — sincronización incremental y verificación previa con `--dry-run`
- [`tar`](tar.md) — empaquetar una baseline antes de archivarla
- [`storage_backup`](storage_backup.md) — estrategia de backups y restauración
- [`scenario`](../scenarios/system/15-config-drift.md) — detección de cambios no autorizados
- [`scenario`](../scenarios/system/11-cron-failure.md) — cron roto tras un cambio de configuración
- [`scenario`](../scenarios/security/04-suspicious-cron.md) — cron sospechoso comparado contra la baseline
- [`scenario`](../scenarios/security/02-suid-audit-and-file-permissions.md) — auditoría SUID
- [`scenario`](../scenarios/security/03-unauthorized-ssh-keys.md) — claves SSH no autorizadas
- [`scenario`](../scenarios/infrastructure/10-backup-restore-drill.md) — verificar que el backup se restaura
- [`scenario`](../scenarios/infrastructure/03-disaster-recovery.md) — recuperación y comparación post-incidente
