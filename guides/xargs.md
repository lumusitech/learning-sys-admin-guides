# xargs — Guía completa

**Nivel:** 🟡 Intermedio
**Archivos de práctica:** Sistema de archivos (`/`)
**Ver escenarios relacionados:** [`security/02-suid-audit`](../scenarios/security/02-suid-audit-and-file-permissions.md)

**Quick command:** `xargs -I {} echo "Item: {}" < labs/datos.txt`

## ⚡ Quick run

```bash
find /tmp -type f -mtime +7 -print | xargs rm -f
```

---

## Índice
1. [¿Qué es xargs?](#qué-es-xargs)
2. [Sintaxis básica](#sintaxis-básica)
3. [Cómo funciona](#cómo-funciona)
4. [Agrupar argumentos (-n, -L)](#agrupar-argumentos)
5. [Paralelizar (-P)](#paralelizar--p)
6. [Reemplazar posición (-I)](#reemplazar-posición--i)
7. [Manejar espacios y caracteres especiales (-0)](#manejar-espacios-y-caracteres-especiales--0)
8. [Confirmar antes de ejecutar (-p)](#confirmar-antes-de-ejecutar--p)
9. [Modo verbose (-t)](#modo-verbose--t)
10. [Combinación con find](#combinación-con-find)
11. [Escenarios reales](#escenarios-reales)
12. [Uno-liners imprescindibles](#uno-liners-imprescindibles)

---

## ¿Qué es xargs?

**xargs** construye y ejecuta comandos a partir de la entrada estándar. Toma elementos de stdin y los pasa como argumentos a otro comando. Es el puente entre la salida de un comando y los argumentos de otro.

Sin xargs, comandos como `rm`, `grep`, `chmod` no pueden recibir argumentos desde stdin directamente:

```bash
# Esto NO funciona: rm no lee de stdin
find . -name "*.tmp" | rm
# Esto SÍ funciona: xargs convierte stdin en argumentos para rm
find . -name "*.tmp" | xargs rm
```

---

## Sintaxis básica

```bash
comando | xargs [opciones] [comando_a_ejecutar [argumentos_iniciales]]
```

```bash
# Convertir stdin en argumentos
echo "uno dos tres" | xargs mkdir
# = mkdir uno dos tres

# Especificar comando explícito
echo "1 2 3" | xargs touch
# = touch 1 2 3
```

Si no se especifica comando, xargs usa `echo` por defecto.

---

## Cómo funciona

xargs lee de stdin, divide la entrada en elementos (por defecto separados por espacios o nuevas líneas), y ejecuta el comando con tantos elementos como quepan en una línea de comandos.

### Límite de argumentos

El kernel impone un límite máximo de tamaño para una línea de comandos (getconf ARG_MAX, típicamente ~2MB). xargs respeta ese límite automáticamente, partiendo la entrada en **lotes** si es necesario.

```bash
# Si hay 10000 archivos, xargs ejecutará rm varias veces
find . -name "*.log" | xargs rm
```

---

## Agrupar argumentos (-n, -L)

### -n (max-args)

Máximo número de argumentos por ejecución.

```bash
# Ejecutar echo 2 argumentos a la vez
echo "a b c d e f" | xargs -n 2
# Resultado:
# a b
# c d
# e f

# touch: 2 archivos por invocación
echo "1 2 3 4 5" | xargs -n 2 touch
# = touch 1 2
# = touch 3 4
# = touch 5
```

### -L (max-lines)

Máximo número de líneas de entrada por ejecución.

```bash
# Una línea de entrada por ejecución
cat archivos.txt | xargs -L 1 wc -l

# 3 líneas por ejecución
cat archivos.txt | xargs -L 3 echo "Procesando:"
```

---

## Paralelizar (-P)

`-P N` ejecuta hasta N procesos en paralelo.

```bash
# Comprimir archivos en paralelo (hasta 4 simultáneos)
find . -name "*.log" | xargs -P 4 -I {} gzip {}

# Ping a múltiples IPs en paralelo
cat ips.txt | xargs -P 10 -I {} ping -c 1 {}

# Descargas paralelas
cat urls.txt | xargs -P 5 -I {} wget {}

# Convertir imágenes en paralelo
find . -name "*.jpg" | xargs -P $(nproc) -I {} convert {} -resize 50% {}
```

> **-P N**: N es el número de procesos simultáneos. Usa `$(nproc)` para usar todos los CPUs disponibles.

---

## Reemplazar posición (-I)

`-I` define un marcador (placeholder) que se reemplaza por cada argumento. Permite especificar exactamente dónde va el argumento en el comando.

```bash
# {} es el marcador (por convenio, puede ser cualquier texto)
find . -name "*.txt" | xargs -I {} cp {} /backup/

# Usando otro marcador
find . -name "*.txt" | xargs -I ARCH cp ARCH /backup/

# Múltiples usos del marcador
echo "foto.jpg" | xargs -I {} convert {} -resize 50% {%.*}_thumb.jpg
```

> **Explicación**: `{%.*}` es expansión de bash que elimina la extensión. Solo funciona si xargs invoca al shell. Con `xargs -I {} sh -c 'convert "$1" -resize 50% "${1%.*}_thumb.jpg"' _ {}` es más robusto.

---

## Manejar espacios y caracteres especiales (-0)

Por defecto xargs divide la entrada por espacios y nuevas líneas. Esto causa problemas con nombres que contienen espacios.

### El problema

```bash
# Si hay un archivo "mi archivo.txt", xargs lo divide en "mi" y "archivo.txt"
find . -name "*.txt" | xargs rm  # PELIGRO: puede borrar archivos equivocados
```

### La solución: -0 (null separator)

Usa `\0` (carácter nulo) como delimitador. Se combina con `find -print0` o `grep -Z`.

```bash
# SEGURO: maneja espacios, comillas, saltos de línea en nombres
find . -name "*.txt" -print0 | xargs -0 rm

# grep -Z produce salida separada por nulos
grep -rlZ "patron" . | xargs -0 sed -i 's/foo/bar/g'
```

> **REGLAS DE ORO**:
> 1. SIEMPRE usa `-print0` con `xargs -0` para archivos
> 2. NUNCA uses `find ... | xargs` sin `-0`
> 3. `xargs -0` + `find -print0` es la combinación más segura

---

## Confirmar antes de ejecutar (-p)

`-p` (interactive) muestra cada comando y pide confirmación (`y`/`n`) antes de ejecutarlo.

```bash
# Preguntar antes de borrar
find . -name "*.tmp" -print0 | xargs -0 -p rm

# Simular borrado (ver qué se ejecutaría)
find . -name "*.tmp" -print0 | xargs -0 -p echo "Borrando:"
```

---

## Modo verbose (-t)

`-t` (verbose) imprime cada comando antes de ejecutarlo (sin preguntar, a diferencia de `-p`).

```bash
# Mostrar qué se ejecuta
find . -name "*.log" | xargs -t rm -f

# Útil para depurar
echo "archivo1 archivo2" | xargs -t -I {} cp {} /backup/
```

---

## Combinación con find

Esta es la combinación más potente y común. find encuentra archivos, xargs ejecuta comandos sobre ellos.

### Comparación: -exec vs xargs

```bash
# find -exec: un proceso por archivo (lento)
find . -name "*.jpg" -exec convert {} -resize 50% {} \;

# xargs: agrupa argumentos (mucho más eficiente)
find . -name "*.jpg" -print0 | xargs -0 -P4 -I {} convert {} -resize 50% {}

# find -exec +: agrupa como xargs (eficiente, pero menos flexible)
find . -name "*.jpg" -exec convert {} -resize 50% {} +
```

> **find -exec {} +** agrupa argumentos como xargs, pero no permite `-P` (paralelo) ni `-I` (reemplazo posicional).

---

## Escenarios reales

### 1. Gestión de archivos masiva

```bash
# Borrar archivos .tmp recursivamente
find /tmp -name "*.tmp" -type f -print0 | xargs -0 rm -f

# Mover archivos por extensión
find . -name "*.log" -print0 | xargs -0 -I {} mv {} /var/log/archive/

# Cambiar permisos en masa
find /var/www -type f -print0 | xargs -0 chmod 644
find /var/www -type d -print0 | xargs -0 chmod 755

# Copiar archivos de un proyecto a otro
find src/ -name "*.py" -print0 | xargs -0 -I {} cp {} /backup/src/
```

### 2. Procesamiento con grep

```bash
# Buscar patrón en archivos específicos
find . -name "*.conf" -print0 | xargs -0 grep -l "Listen"

# Reemplazar texto en archivos encontrados
grep -rlZ "old_text" . | xargs -0 sed -i 's/old_text/new_text/g'

# Contar líneas de archivos que contienen un patrón
grep -rlZ "TODO" . | xargs -0 wc -l
```

### 3. Operaciones en lote con control

```bash
# Comprimir archivos (uno por invocación, con barra de progreso)
find . -name "*.log" -print0 | xargs -0 -I {} sh -c 'gzip {}; echo "Comprimido: {}"'

# Crear backups individuales
find . -name "*.conf" -print0 | xargs -0 -I {} cp {} {}.bak

# Renombrar extensión
find . -name "*.txt" -print0 | xargs -0 -I {} sh -c 'mv "$1" "${1%.txt}.md"' _ {}
```

### 4. Paralelo para rendimiento

```bash
# Ping masivo (10 paralelo)
cat ips.txt | xargs -P 10 -I {} ping -c 1 {} 2>&1 | grep "bytes from"

# Escaneo de puertos con nc (paralelo)
echo "22 80 443 8080 3306" | xargs -P 5 -I {} sh -c 'nc -zv 192.168.1.1 {} 2>&1 | grep -v "refused"'

# Descarga paralela de URLs
cat urls.txt | xargs -P 10 -I {} wget -q {}
```

### 5. Auditoría y seguridad

```bash
# Calcular hash de archivos críticos
find /etc -type f -print0 | xargs -0 -I {} sh -c 'echo "{}: $(sha256sum "{}")"'

# Verificar integridad con md5sum
find . -type f -print0 | xargs -0 md5sum > checksums.md5

# Buscar archivos SUID
find / -type f -perm -4000 -print0 | xargs -0 -L 1 ls -la
```

---

## xargs + tee

**tee** no merece una guía completa, pero merece mención aquí porque se usa en pipelines:

```bash
# tee: copia stdin a archivo(s) Y a stdout
comando | tee archivo.log
# = comando > archivo.log + mostrar en pantalla

# Añadir (no sobrescribir)
comando | tee -a archivo.log

# Múltiples archivos
comando | tee archivo1.log archivo2.log

# Usar con sudo para escribir archivos protegidos
echo "config" | sudo tee /etc/config.conf > /dev/null

# Redirigir stdout a archivo y stderr a otro
comando 2>&1 | tee salida.log

# Añadir timestamp a cada línea
comando | tee >(sed 's/^/[LOG] /' > log_con_prefijo.txt)
```

---

## Uno-liners imprescindibles

```bash
# Borrar archivos encontrados
find . -name "*.tmp" -print0 | xargs -0 rm

# Mover archivos
find . -name "*.log" -print0 | xargs -0 -I {} mv {} /backup/

# Buscar y reemplazar en archivos
grep -rlZ "old" . | xargs -0 sed -i 's/old/new/g'

# Cambiar permisos
find . -type f -print0 | xargs -0 chmod 644

# Comprimir en paralelo (4 procesos)
find . -name "*.log" -print0 | xargs -0 -P 4 gzip

# Contar líneas de archivos
find . -name "*.py" -print0 | xargs -0 wc -l

# Confirmar antes de borrar
find . -name "*.tmp" -print0 | xargs -0 -p rm

# Verbose (mostrar comando)
find . -name "*.log" -print0 | xargs -0 -t rm

# Ejecutar con máximo de argumentos
echo "1 2 3 4 5" | xargs -n 2 echo

# Usar placeholder personalizado
echo "archivo.txt" | xargs -I ARCH echo "cp ARCH /backup/ARCH"

# Paralelo con límite de procesos
cat urls.txt | xargs -P 10 -I {} wget {}

# Pasar argumentos al final (sin -I)
find . -name "*.txt" -print0 | xargs -0 cp -t /backup/

# Ejecutar con sh para procesamiento complejo
find . -name "*.txt" -print0 | xargs -0 -I {} sh -c 'echo "{}"; wc -l "{}"'

# Test: mostrar qué haría (con echo)
find . -name "*.tmp" -print0 | xargs -0 echo rm

# wget en paralelo desde archivo
xargs -P 10 -a urls.txt wget -q

# Leer argumentos desde archivo (no stdin)
xargs -a archivos.txt -I {} cp {} /destino/

# Kill procesos por nombre
ps aux | grep apache | awk '{print $2}' | xargs kill -9
```
