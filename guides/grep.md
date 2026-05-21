# grep — Guía completa

**Nivel:** 🟢 Básico
**Archivos de práctica:** `labs/auth.log`, `labs/nginx_access.log`
**Ver escenarios relacionados:** [`networking/01-detect-ssh-brute-force`](../scenarios/networking/01-detect-ssh-brute-force.md), [`networking/03-port-scan`](../scenarios/networking/03-port-scan-detection.md)

**Quick command:** `grep "Failed password" labs/auth.log`

## ⚡ Quick run

```bash
grep "Failed password" labs/auth.log | head -10
```

---

## Índice
1. [¿Qué es grep?](#qué-es-grep)
2. [Sintaxis básica](#sintaxis-básica)
3. [Tipos de patrón](#tipos-de-patrón)
4. [Opciones principales](#opciones-principales)
5. [Expresiones regulares](#expresiones-regulares)
6. [Modos de expresión regular](#modos-de-expresión-regular)
7. [Contexto alrededor de coincidencias](#contexto-alrededor-de-coincidencias)
8. [Múltiples patrones](#múltiples-patrones)
9. [Archivos múltiples](#archivos-múltiples)
10. [Opciones de salida](#opciones-de-salida)
11. [Combinación con otras herramientas](#combinación-con-otras-herramientas)
12. [Escenarios reales](#escenarios-reales)
13. [grep en redes y seguridad](#grep-en-redes-y-seguridad)
14. [Grep vs alternatives](#grep-vs-alternatives)
15. [Uno-liners imprescindibles](#uno-liners-imprescindibles)

---

## ¿Qué es grep?

**grep** (Global Regular Expression Print) busca patrones en archivos o entrada estándar e imprime las líneas que coinciden. Es la herramienta fundamental para filtrar texto en Linux.

El nombre viene del comando `g/re/p` del editor `ed`: Globalmente busca una expresión regular, e imprime (print) las líneas.

---

## Sintaxis básica

```bash
grep [opciones] patrón [archivo...]
```

```bash
# Buscar "error" en un archivo
grep "error" app.log

# Leer de stdin (tubería)
cat app.log | grep "error"

# Buscar en múltiples archivos
grep "error" app.log syslog.log
```

---

## Tipos de patrón

### Patrón fijo (-F, --fixed-strings)

Interpreta el patrón como texto literal, no como regex. Útil cuando el patrón contiene caracteres especiales de regex (`.`, `*`, `[`, etc.) y no quieres escaparlos.

```bash
# Buscar literalmente "error(500)" — sin -F, los paréntesis serían grupo regex
grep -F "error(500)" app.log

# Buscar una IP literal (el punto sería "cualquier carácter" sin -F)
grep -F "192.168.1.1" access.log
```

### Patrón regex (por defecto)

```bash
# Regex básica: líneas que empiecen por "ERROR"
grep "^ERROR" app.log
```

### Archivo de patrones (-f, --file)

Lee patrones desde un archivo, uno por línea.

```bash
# Buscar múltiples patrones desde archivo
grep -f patrones.txt app.log
```

### Patrón perl (-P, --perl-regexp)

Usa expresiones regulares estilo Perl (PCRE). Mucho más potente: lookahead, lookbehind, backreferences, etc. Solo disponible en GNU grep.

```bash
# Lookahead: "error" seguido de dígitos
grep -P "error(?=.*[0-9])" app.log

# Lookbehind: después de "ERROR:" capturar todo
grep -P "(?<=ERROR:).*" app.log
```

---

## Opciones principales

### Control de búsqueda

| Opción | Nombre | Qué hace |
|--------|--------|----------|
| `-i` | `--ignore-case` | Ignora mayúsculas/minúsculas |
| `-w` | `--word-regexp` | Solo coincide palabras completas |
| `-x` | `--line-regexp` | Solo coincide líneas completas |
| `-v` | `--invert-match` | Invierte: muestra líneas que NO coinciden |
| `-e` | `--regexp` | Especifica un patrón (útil para patrones que empiezan con `-`) |
| `-f` | `--file` | Lee patrones de un archivo |

```bash
# Ignorar mayúsculas/minúsculas
grep -i "error" app.log

# Palabra completa "error" (no "terror" ni "error404")
grep -w "error" app.log

# Línea exacta "ERROR: timeout"
grep -x "ERROR: timeout" app.log

# Todo EXCEPTO lo que contenga "debug"
grep -v "debug" app.log

# Patrón que empieza con guión
grep -e "-k" -- opciones.txt
```

### Verbosidad y diagnóstico

| Opción | Qué hace |
|--------|----------|
| `-s` | Suprime errores de archivos no existentes o no legibles |
| `-q` | Modo silencioso: no imprime nada, solo código de salida |
| `--help` | Muestra ayuda |
| `-V` | Muestra versión |

```bash
# Modo silencioso: solo interesa el código de salida
if grep -q "root" /etc/passwd; then
  echo "root existe"
fi
```

### Control de recursividad

| Opción | Qué hace |
|--------|----------|
| `-r` o `-R` | Busca recursivamente en directorios |
| `-l` | Muestra solo nombres de archivo con coincidencia |
| `-L` | Muestra solo nombres de archivo SIN coincidencia |
| `--include` | Solo busca en archivos que coinciden con el patrón |
| `--exclude` | Excluye archivos que coinciden con el patrón |
| `--exclude-dir` | Excluye directorios |

```bash
# Buscar recursivamente en /var/log
grep -r "error" /var/log/

# Solo nombres de archivo
grep -rl "password" /etc/

# Solo archivos .log
grep -r --include="*.log" "timeout" /var/log/

# Excluir directorios
grep -r --exclude-dir=".git" "TODO" .
```

---

## Expresiones regulares

### Conceptos básicos (BRE - Basic Regular Expressions)

Por defecto grep usa BRE. Algunos metacaracteres necesitan escaparse con `\`:

| Símbolo | Significado |
|---------|-------------|
| `.` | Cualquier carácter excepto nueva línea |
| `^` | Inicio de línea |
| `$` | Fin de línea |
| `*` | Cero o más repeticiones del carácter anterior |
| `.*` | Cero o más caracteres (cualquier cosa) |
| `[abc]` | Uno de los caracteres a, b, c |
| `[^abc]` | Ninguno de a, b, c |
| `[a-z]` | Rango de a a z |
| `\(` `\)` | Agrupación (escapado) |
| `\{n,m\}` | Repetición entre n y m (escapado) |
| `\n` | Referencia a grupo n |

```bash
# BRE: agrupación con \( \)
grep "\(error\|fatal\)" app.log

# BRE: repetición con \{ \}
grep "[0-9]\{3\}\.[0-9]\{3\}" archivo.txt
```

### ERE - Extended Regular Expressions (-E)

Con `-E` no necesitas escapar `()`, `{}`, `|`, `+`, `?`:

```bash
# ERE: alternancia sin escapar
grep -E "error|fatal|critical" app.log

# ERE: más fácil para cuantificadores
grep -E "[0-9]{3}\.[0-9]{3}" archivo.txt

# ERE: una o más ocurrencias
grep -E "[0-9]+" archivo.txt

# ERE: opcional
grep -E "https?" archivo.txt
```

### Metacaracteres útiles

| Símbolo | Significado | Ejemplo |
|---------|-------------|---------|
| `\<` | Inicio de palabra | `\<error` |
| `\>` | Fin de palabra | `error\>` |
| `\b` | Límite de palabra | `\berror\b` |
| `\B` | No límite de palabra | `\Berror` |
| `\w` | Carácter de palabra `[a-zA-Z0-9_]` | `\w\+` |
| `\W` | No carácter de palabra | `\W` |
| `\s` | Espacio en blanco | `\s\+` |
| `\S` | No espacio en blanco | `\S\+` |

```bash
# Límite de palabra: "error" como palabra completa
grep "\berror\b" app.log

# Coincidir con espacios en blanco
grep -E "\s+" archivo.txt
```

---

## Contexto alrededor de coincidencias

| Opción | Qué hace |
|--------|----------|
| `-A N` | Muestra N líneas **después** (After) de la coincidencia |
| `-B N` | Muestra N líneas **antes** (Before) de la coincidencia |
| `-C N` | Muestra N líneas de **contexto** (antes y después) |

```bash
# 3 líneas después de cada "error"
grep -A 3 "error" app.log

# 2 líneas antes de cada "stack trace"
grep -B 2 "stack trace" app.log

# 5 líneas de contexto alrededor de "timeout"
grep -C 5 "timeout" app.log

# Útil para logs con stack traces
grep -A 10 "Exception" app.log
```

---

## Múltiples patrones

```bash
# AND lógico (dos grep encadenados)
grep "error" app.log | grep "2024-01-15"

# OR con -e
grep -e "error" -e "fatal" -e "critical" app.log

# OR con alternancia ERE
grep -E "error|fatal|critical" app.log

# AND en una sola línea con lookahead (PCRE)
grep -P "(?=.*error)(?=.*2024-01-15)" app.log
```

### Combinar grep + grep para AND

```bash
# Líneas que contienen "root" Y "/bin/bash"
grep "root" /etc/passwd | grep "/bin/bash"

# Líneas que NO contienen "root" Y contienen "bash"
grep -v "root" /etc/passwd | grep "bash"
```

---

## Archivos múltiples

Cuando grep busca en varios archivos, por defecto antepone el nombre del archivo:

```bash
# Buscar en todos los .log del directorio
grep "error" *.log
# Salida: archivo.log:linea con error

# Suprimir el nombre del archivo
grep -h "error" *.log

# Forzar mostrar nombre aunque sea un solo archivo
grep -H "error" app.log
```

| Opción | Qué hace |
|--------|----------|
| `-h` | No antepone el nombre del archivo |
| `-H` | Siempre antepone el nombre del archivo |
| `-l` | Solo nombres de archivos con coincidencias |
| `-L` | Solo nombres de archivos sin coincidencias |
| `-c` | Solo cuenta de coincidencias por archivo |

```bash
# Contar errores por archivo
grep -c "error" *.log

# Archivos que contienen "root"
grep -l "root" /etc/*

# Archivos que NO contienen "root"
grep -L "root" /etc/*
```

---

## Opciones de salida

| Opción | Qué hace |
|--------|----------|
| `-n` | Muestra el número de línea |
| `-b` | Muestra el offset en bytes desde el inicio del archivo |
| `-o` | Muestra solo la parte que coincide (no toda la línea) |
| `-c` | Solo cuenta de líneas coincidentes |
| `--color` | Colorea las coincidencias (auto/always/never) |
| `-T` | Añade tabulaciones entre separadores |

```bash
# Mostrar número de línea
grep -n "error" app.log

# Mostrar solo la coincidencia (útil para extraer valores)
grep -oP '"id": "\K[^"]+' data.json

# Colorear en salida a terminal
grep --color=auto "error" app.log

# Pasar a otro comando: desactivar color
grep --color=never "error" app.log | wc -l
```

### -o con entorno PCRE: extracción de datos

La combinación de `-o` con `-P` y `\K` permite extraer valores específicos sin necesidad de sed/awk:

```bash
# Extraer direcciones IP (solo la IP, no la línea completa)
grep -oP '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' access.log

# Extraer todo después de "ID: " hasta el primer espacio
grep -oP 'ID: \K[^ ]+' archivo.txt

# Extraer valores de JSON: "email": "user@example.com"
grep -oP '"email": "\K[^"]+' usuarios.json
```

> **Explicación de `\K`**: es un marcador de "keep out" en PCRE. Todo lo que esté antes de `\K` se usa para la coincidencia pero NO se incluye en el resultado. Es como un lookbehind sin limitación de longitud.

---

## Códigos de salida

| Código | Significado |
|--------|-------------|
| `0` | Se encontró al menos una coincidencia |
| `1` | No se encontró ninguna coincidencia |
| `2` | Ocurrió un error (archivo no existe, permiso denegado, etc.) |

```bash
if grep -q "root" /etc/passwd; then
  echo "root existe"
else
  echo "root NO existe (código: $?)"
fi
```

---

## Combinación con otras herramientas

### grep + cut

```bash
# IPs que hicieron peticiones 404 (campo $9=404, campo $1=IP)
grep " 404 " access.log | cut -d' ' -f1

# Extraer emails de un archivo
grep -oP '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' archivo.txt | cut -d'@' -f2 | sort | uniq -c
```

### grep + sort + uniq

```bash
# IPs únicas ordenadas por frecuencia
grep -oP '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' access.log | sort | uniq -c | sort -rn

# Top 10 IPs
grep -oP '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' access.log | sort | uniq -c | sort -rn | head -10
```

### grep + awk

```bash
# grep filtra líneas, awk procesa campos
grep "ERROR" app.log | awk '{ print $1, $2, $NF }'

# Equivalente en awk puro (evita el pipe)
awk '/ERROR/ { print $1, $2, $NF }' app.log
```

### grep + sed

```bash
# grep encuentra líneas, sed transforma
grep "IP:" archivo.txt | sed 's/IP: //'

# Lo mismo en sed puro
sed -n '/IP:/p; s/IP: //p' archivo.txt
```

### grep + find (o find + grep)

```bash
# Buscar archivos .conf que contengan "Listen"
find /etc -name "*.conf" -exec grep -l "Listen" {} \;

# Equivalente moderno con grep -r
grep -rl --include="*.conf" "Listen" /etc/
```

### grep + xargs

```bash
# Encontrar archivos con "TODO" y reemplazar
grep -rl "TODO" src/ | xargs sed -i 's/TODO/DONE/g'

# Matar procesos: buscar PID y matar
ps aux | grep "apache" | grep -v grep | awk '{print $2}' | xargs kill
```

### grep + tail/watch

```bash
# Monitorear log en tiempo real
tail -f app.log | grep --line-buffered "error"

# Watch cada 2 segundos buscando errores
watch -n 2 'grep -c "error" /var/log/app.log'
```

> **`--line-buffered`**: hace que grep vacíe su buffer línea por línea. Esencial en pipes en tiempo real (tail -f, watch) para no perder líneas.

---

## Escenarios reales

### 1. Análisis de logs de aplicación

```bash
# Errores en las últimas 24h (filtrar por fecha si el log tiene timestamp)
grep "$(date -d 'yesterday' '+%Y-%m-%d')" app.log | grep -i "error"

# Contar ocurrencias de cada tipo de error
grep -oP 'ERROR \K[A-Z]+' app.log | sort | uniq -c | sort -rn

# Stack traces completos (Exception + 15 líneas después)
grep -A 15 "Exception" app.log

# Buscar errores excluyendo los conocidos
grep -i "error" app.log | grep -v -E "known error|expected|timeout"

# Logs entre dos marcas de tiempo
grep "2024-01-15 14:3[0-9]\|2024-01-15 14:4[0-9]" app.log
```

### 2. Análisis de logs de servidor web

```bash
# Peticiones exitosas (2xx)
grep -E '"[A-Z]+ [^ ]+ HTTP/1.[01]" 2[0-9][0-9]' access.log

# Peticiones fallidas (4xx o 5xx)
grep -E '"[A-Z]+ [^ ]+ HTTP/1.[01]" [45][0-9][0-9]' access.log

# Ataques 404 (paths que no existen)
grep ' 404 ' access.log | grep -oP '"[A-Z]+ \K[^ ]+' | sort | uniq -c | sort -rn | head -20

# Escaneo de directorios (múltiples 404 de una IP)
grep ' 404 ' access.log | grep -oP '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | sort | uniq -c | sort -rn | head -10

# SQL Injection attempts
grep -iE "(union.*select|select.*from|drop table|or '1'='1'|-- )" access.log

# User agents sospechosos
grep -iE "(curl|wget|python-requests|nikto|nmap|sqlmap)" access.log | awk '{print $1, $NF}'
```

### 3. Monitoreo de sistema

```bash
# Particiones con uso > 80%
df -h | grep -E '[89][0-9]%|100%'

# Procesos de un usuario específico (excluyendo el propio grep)
ps aux | grep "^carludev" | grep -v grep

# Interfaces de red con errores
ip -s link | grep -A 2 -E "errors|dropped|overruns"
```

### 4. Seguridad: detectar actividad sospechosa en auth.log

```bash
# Intentos de login fallidos
grep "Failed password" /var/log/auth.log

# Contar intentos fallidos por IP
grep "Failed password" /var/log/auth.log | grep -oP 'from \K[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | sort | uniq -c | sort -rn

# Brute force: IPs con más de 10 intentos fallidos
grep "Failed password" /var/log/auth.log | grep -oP 'from \K[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | sort | uniq -c | sort -rn | awk '$1 > 10'

# Conexiones SSH exitosas
grep "Accepted publickey\|Accepted password" /var/log/auth.log

# Usuarios no existentes que intentan loguearse
grep "Failed password for invalid user" /var/log/auth.log | grep -oP 'invalid user \K\S+' | sort | uniq -c | sort -rn

# Sudor (intentos de sudo)
grep "sudo" /var/log/auth.log | grep -v "COMMAND="
```

### 5. Firewall logs (iptables/nftables)

```bash
# Paquetes bloqueados
grep "DPT=" /var/log/kern.log

# Puertos más escaneados
grep "DPT=" /var/log/kern.log | grep -oP 'DPT=\K[0-9]+' | sort | uniq -c | sort -rn | head -10

# IPs bloqueadas con más frecuencia
grep "IN=" /var/log/kern.log | grep -oP 'SRC=\K[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | sort | uniq -c | sort -rn | head -20
```

### 6. Análisis de configuraciones

```bash
# Buscar puertos Listen en Apache/Nginx
grep -r "Listen" /etc/apache2/ --include="*.conf"

# Buscar VirtualHosts por nombre de dominio
grep -r "ServerName\|server_name" /etc/apache2/ /etc/nginx/

# Buscar credenciales hardcodeadas (malas prácticas)
grep -r -E "(password|passwd|secret|PASS|PASSWORD)\s*[:=]" --include="*.{py,sh,js,yml,yaml,env}" .

# Buscar comentarios TODO/FIXME
grep -r -n "TODO\|FIXME\|XXX" --include="*.{py,js,sh,c,h,cpp}" .
```

### 7. Verificación de logs en tiempo real

```bash
# Monitor de errores en vivo
tail -f /var/log/syslog | grep --line-buffered -i "error\|fail\|critical\|oom"

# Detectar IPs haciendo escaneo de puertos (logs de firewall en vivo)
tail -f /var/log/kern.log | grep --line-buffered "DPT=" | grep -oP 'SRC=\K[0-9.]+' | sort | uniq -c | sort -rn
```

---

## grep en redes y seguridad

### Detectar escaneos de puertos en access.log

```bash
# Una IP que pide muchas URLs distintas en poco tiempo
grep -oP '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' access.log | sort | uniq -c | sort -rn | head -20

# Una IP contra muchos puertos (en log firewall)
grep "IN=" /var/log/kern.log | grep -oP 'SRC=\K[0-9.]+' | sort | uniq -c | sort -rn | head -10
```

### Detectar ataques web comunes

```bash
# Path traversal
grep -E '\.\./|\.\.\\|%2e%2e%2f|%2e%2e%5c' access.log

# XSS (Cross-Site Scripting)
grep -iE '<script|<iframe|onerror=|onload=|javascript:' access.log

# Inclusión de archivos locales (LFI)
grep -E 'include=|require=|file=|page=|doc=' access.log | grep -E '\.\./|/etc/passwd|/proc/self'

# Inyección de comandos
grep -E '; |\||`|%0a|%0d' access.log | grep -iE '(cat|ls|id|wget|curl|nc|bash|sh|python)'
```

### Verificar conectividad y DNS

```bash
# IPs que hacen peticiones a dominios específicos
grep "example.com" /var/log/named/query.log

# Consultas DNS de tipo AXFR (transferencia de zona, potencial ataque)
grep "AXFR" /var/log/named/transfer.log

# Conexiones a puertos no estándar
grep -v ':80\|:443' access.log
```

---

## Grep vs alternativas

| Herramienta | Cuándo usarla |
|-------------|---------------|
| **grep** | Para búsquedas rápidas simples o moderadamente complejas en archivos |
| **awk** | Cuando necesitas procesar campos, hacer cálculos, acumuladores |
| **sed** | Para transformar el contenido (reemplazar, eliminar, insertar) |
| **ack/ag/rg** | Alternativas más rápidas para buscar en grandes árboles de código |
| **grep -P** | Lo más cercano a PCRE, útil para extracciones complejas |

```bash
# ripgrep (rg) es mucho más rápido que grep -r en proyectos grandes
rg "error" --type py
# ag (The Silver Searcher) también es rápido
ag "error" src/
```

---

## Uno-liners imprescindibles

```bash
# Contar todas las líneas no vacías
grep -c '.' archivo.txt

# Contar líneas que NO son comentarios
grep -v '^#' archivo.conf | grep -c '.'

# Mostrar líneas duplicadas
sort archivo.txt | uniq -d

# Extraer todas las direcciones IP de un archivo
grep -oP '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' archivo.txt

# Extraer todas las URLs de un archivo
grep -oP 'https?://[^"<> ]+' archivo.txt

# Mostrar líneas entre 20 y 30 caracteres de longitud
grep -E '^.{20,30}$' archivo.txt

# Buscar líneas en blanco
grep -c '^$' archivo.txt

# Buscar líneas que empiezan con mayúscula
grep '^[A-Z]' archivo.txt

# Contar palabras específicas en un archivo
grep -o "palabra" archivo.txt | wc -l

# Mostrar cuántas veces aparece cada palabra
grep -oE '[a-zA-Z]+' archivo.txt | sort | uniq -c | sort -rn

# Archivos modificados hoy que contienen "TODO"
find . -name "*.py" -newer $(date -d 'today 00:00' +%s) -exec grep -l "TODO" {} \;

# Buscar IPs en un rango específico (192.168.1.x)
grep -P '192\.168\.1\.\d{1,3}' access.log

# Buscar MAC addresses
grep -oP '([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}' archivo.txt

# Buscar timestamps ISO 8601
grep -oP '\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}' archivo.log

# Líneas que contienen solo números
grep -x '[0-9]\+' archivo.txt

# Buscar palabras de exactamente N letras
grep -wE '[a-zA-Z]{5}' archivo.txt

# Excluir líneas en blanco y comentarios
grep -v '^\(#\|$\)' config.conf
```

---

## Rendimiento: optimizar grep

```bash
# Preferir -F para patrones fijos (mucho más rápido)
grep -F "texto literal" archivo.txt

# Limitar tamaño de archivo con find
find . -name "*.log" -size -10M -exec grep -l "error" {} \;

# Usar LC_ALL=C para acelerar (evita procesamiento de locale)
LC_ALL=C grep "error" archivo.txt

# Descartar salida si solo necesitas código
grep -q "patron" archivo.txt && echo "encontrado"

# Usar --mmap (obsoleto en GNU grep, el kernel lo hace solo ahora)
```

### Cuándo grep es lento

- Archivos muy grandes (>1GB): considera `rg`, `ag` o `LC_ALL=C grep`
- Patrones regex muy complejos con backtracking excesivo
- Buscar en archivos binarios: usa `-a` (tratar como texto) o evítalos con `-I`

---

## Notas sobre implementaciones

```bash
# Versión GNU (la común en Linux)
grep --version

# En sistemas BSD/macOS grep es diferente (no tiene -P)
# Instalar GNU grep en macOS:
brew install grep
# Usar como ggrep
```

> **grep -P** no está disponible en grep BSD/macOS. En entornos no Linux, considera instalar GNU grep o usar `awk`/`sed`/`perl` como alternativa.
