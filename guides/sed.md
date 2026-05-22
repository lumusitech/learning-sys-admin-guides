# sed — Guía completa

**Nivel:** 🟡 Intermedio
**Archivos de práctica:** `labs/datos.txt`
**Ver escenarios relacionados:** [`system/02-log-analysis`](../scenarios/system/02-log-analysis-and-error-tracking.md)

## ⚡ Quick command

`sed 's/error/ERROR/g' labs/syslog.log`

## ⚡ Quick run

```bash
sed 's/error/ERROR/g' labs/syslog.log | head -10
```

---

## Índice
1. [¿Qué es sed?](#qué-es-sed)
2. [Sintaxis básica](#sintaxis-básica)
3. [Sustitución (s///)](#sustitución-s)
4. [Direcciones y rangos](#direcciones-y-rangos)
5. [Eliminación (d)](#eliminación-d)
6. [Impresión (p) y supresión de salida (-n)](#impresión-p-y-supresión-de-salida--n)
7. [Inserción y añadido (i, a)](#inserción-y-añadido-i-a)
8. [Cambio de línea (c)](#cambio-de-línea-c)
9. [Transformación (y///)](#transformación-y)
10. [Lectura y escritura (r, w)](#lectura-y-escritura-r-w)
11. [Múltiples comandos (-e, -f, ;)](#múltiples-comandos)
12. [Edición in-place (-i)](#edición-in-place--i)
13. [Espacio de patrones y espacio de espera](#espacio-de-patrones-y-espacio-de-espera)
14. [Bucles y etiquetas](#bucles-y-etiquetas)
15. [Casos de uso reales](#casos-de-uso-reales)
16. [sed en redes y seguridad](#sed-en-redes-y-seguridad)
17. [Combinación con otras herramientas](#combinación-con-otras-herramientas)
18. [Uno-liners imprescindibles](#uno-liners-imprescindibles)

---

## ¿Qué es sed?

**sed** (Stream Editor) es un editor de flujos de texto. Procesa texto línea por línea aplicando operaciones como sustitución, eliminación, inserción y transformación. No es interactivo: recibe instrucciones y las aplica automáticamente.

A diferencia de awk, sed se especializa en **transformaciones de texto** (buscar y reemplazar, eliminar líneas, insertar), mientras que awk se especializa en **procesamiento por campos**.

### Flujo de trabajo

1. Lee una línea del archivo o stdin al **espacio de patrones** (pattern space)
2. Aplica todos los comandos sed a esa línea
3. Imprime el resultado (por defecto)
4. Repite con la siguiente línea

---

## Sintaxis básica

```bash
sed [opciones] 'comando' archivo
sed [opciones] -e 'comando1' -e 'comando2' archivo
sed -f script.sed archivo
```

```bash
# Sustituir primera ocurrencia de "foo" por "bar" en cada línea
sed 's/foo/bar/' archivo.txt

# Leer de stdin
echo "hola mundo" | sed 's/mundo/amigo/'
```

---

## Sustitución (s///)

### Forma básica

```bash
sed 's/patrón/reemplazo/' archivo.txt
```

El comando `s` (substitute) busca el patrón y lo reemplaza por el texto de reemplazo.

### Flags de sustitución

| Flag | Descripción |
|------|-------------|
| (ninguno) | Reemplaza solo la primera ocurrencia en cada línea |
| `g` | Global: reemplaza **todas** las ocurrencias en cada línea |
| `N` | Reemplaza la ocurrencia número N (3 = tercera ocurrencia) |
| `p` | Imprime la línea si hubo sustitución (con -n) |
| `w archivo` | Escribe la línea a un archivo si hubo sustitución |
| `I` o `i` | Ignora mayúsculas/minúsculas en el patrón |
| `e` | Ejecuta el resultado como comando shell (GNU sed) |

```bash
# Reemplazar todas las ocurrencias
sed 's/foo/bar/g' archivo.txt

# Reemplazar solo la segunda ocurrencia
sed 's/foo/bar/2' archivo.txt

# Ignorar mayúsculas
sed 's/error/ERROR/I' app.log

# Reemplazar y guardar las líneas modificadas
sed -n 's/error/CRITICAL/w modificadas.txt' app.log

# Reemplazar y imprimir solo las líneas modificadas
sed -n 's/error/CRITICAL/p' app.log
```

> **Explicación de `w`**: escribe en un archivo las líneas donde se realizó la sustitución. Si no se usa `-n`, también imprime en pantalla; con `-n` solo escribe al archivo.

### Delimitadores alternativos

Puedes usar cualquier carácter como delimitador en lugar de `/`. Útil cuando el patrón contiene barras:

```bash
# Reemplazar rutas: usar # como delimitador
sed 's#/var/log#/var/log/backup#g' archivo.txt

# Usar | como delimitador
sed 's|http://|https://|g' urls.txt

# Usar _ como delimitador
sed 's_foo_bar_g' archivo.txt
```

### Referencias (backreferences)

`\1` a `\9` referencian grupos de captura del patrón:

```bash
# Invertir nombre y apellido
sed 's/\([a-zA-Z]*\) \([a-zA-Z]*\)/\2, \1/' nombres.txt

# Con -E (ERE) sin escapar paréntesis
sed -E 's/([a-zA-Z]*) ([a-zA-Z]*)/\2, \1/' nombres.txt

# Extraer dominio de un email
sed -E 's/.*@([^ ]+)/\1/' emails.txt

# Enmascarar tarjetas de crédito (mostrar solo últimos 4 dígitos)
sed -E 's/[0-9]{4} [0-9]{4} [0-9]{4} ([0-9]{4})/**** **** **** \1/g' datos.txt
```

### Ampersand (&) — toda la coincidencia

`&` representa todo el texto que coincidió con el patrón:

```bash
# Poner entre paréntesis todas las IPs
sed 's/[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3}/(&)/g' archivo.txt

# Rodear con asteriscos
sed 's/error/*** & ***/g' app.log

# Añadir prefijo a números
sed 's/[0-9]/ID-&/g' archivo.txt
```

> **Explicación**: `&` no necesita escape (a diferencia de `\1`). Se pone en el reemplazo y sed lo expande con todo el texto que casó con el patrón.

### Modificadores de regex en sed

| Símbolo | Efecto | Ejemplo |
|---------|--------|---------|
| `^` | Inicio de línea | `s/^/PREFIJO /` |
| `$` | Fin de línea | `s/$/ SUFIJO/` |
| `.*` | Cero o más caracteres | `s/^.*://` (borra todo hasta los dos puntos) |
| `\<` | Inicio de palabra | `s/\<foo/bar/` |
| `\>` | Fin de palabra | `s/foo\>/bar/` |
| `\+` | Una o más repeticiones (BRE) | `s/[0-9]\+/NUMERO/g` |

---

## Direcciones y rangos

Los comandos sed pueden ir precedidos de una **dirección** (address) que especifica a qué líneas aplicar el comando.

### Dirección por número de línea

```bash
# Solo línea 3
sed '3s/foo/bar/' archivo.txt

# Líneas 1 a 5
sed '1,5s/foo/bar/' archivo.txt

# De la línea 5 hasta el final
sed '5,$s/foo/bar/' archivo.txt

# Última línea
sed '$s/foo/bar/' archivo.txt
```

> **`$` en direcciones**: cuando se usa como dirección (no como patrón), `$` significa "última línea del archivo".

### Dirección por patrón (regex)

```bash
# Líneas que contengan "error"
sed '/error/s/timeout/TIMEOUT/' app.log

# Líneas que empiecen por "#"
sed '/^#/d' config.conf
```

### Rangos de direcciones

```bash
# Desde la línea que contiene "BEGIN" hasta la que contiene "END"
sed '/BEGIN/,/END/s/foo/bar/' archivo.txt

# De la línea 10 a la que contiene "STOP"
sed '10,/STOP/d' archivo.txt

# De la línea con "START" al final
sed '/START/,$s/activo/inactivo/' archivo.txt
```

### Negación (!)

Invierte la dirección: aplica el comando a las líneas que NO coinciden.

```bash
# Eliminar TODO excepto líneas con "error"
sed -n '/error/!d' app.log

# Sustituir en todas las líneas excepto en las que empiezan con #
sed '/^#!/s/foo/bar/g' config.conf
```

---

## Eliminación (d)

`d` elimina la línea completa del espacio de patrones.

```bash
# Eliminar líneas 3 a 6
sed '3,6d' archivo.txt

# Eliminar líneas vacías
sed '/^$/d' archivo.txt

# Eliminar líneas con comentarios
sed '/^#/d' archivo.conf

# Eliminar la última línea
sed '$d' archivo.txt

# Eliminar todo entre "START" y "END" (inclusive)
sed '/START/,/END/d' archivo.txt

# Eliminar líneas que NO contengan "activo"
sed '/activo/!d' archivo.txt

# Eliminar líneas duplicadas consecutivas (como uniq)
sed '$!N; /^\(.*\)\n\1$/d; P; D' archivo.txt
```

---

## Impresión (p) y supresión de salida (-n)

Por defecto sed imprime **todas** las líneas. `-n` suprime la impresión automática, y `p` imprime explícitamente.

### -n (--quiet, --silent)

Suprime la salida automática. Solo imprime lo que indiques con `p`.

```bash
# Imprimir solo líneas 5 a 10
sed -n '5,10p' archivo.txt

# Imprimir solo líneas que contengan "error"
sed -n '/error/p' app.log

# Imprimir líneas 1, 3, 5, 7...
sed -n '1~2p' archivo.txt

# Imprimir primera línea (como head -1)
sed -n '1p' archivo.txt

# Imprimir última línea (como tail -1)
sed -n '$p' archivo.txt
```

> **`~` (step) en GNU sed**: `primeiro~paso`. `1~2` = desde la línea 1 cada 2 líneas (impares). `2~3` = desde la 2 cada 3 líneas.

### Combinar p con s para depuración

```bash
# Mostrar solo líneas donde se hizo reemplazo
sed -n 's/error/CRITICAL/p' app.log

# Mostrar línea original y modificada
sed -n '/error/{p; s/error/CRITICAL/p}' app.log
```

---

## Inserción y añadido (i, a)

| Comando | Descripción |
|---------|-------------|
| `i\` | Inserta una línea **antes** de la línea actual (insert) |
| `a\` | Añade una línea **después** de la línea actual (append) |

```bash
# Insertar línea antes de la línea 3
sed '3i\Esta es la línea insertada' archivo.txt

# Añadir línea después de la línea 5
sed '5a\Esta es la línea añadida' archivo.txt

# Insertar antes de cada línea que contenga "error"
sed '/error/i\--- INICIO ERROR ---' app.log

# Añadir después de cada línea con "ERROR"
sed '/ERROR/a\--- FIN ERROR ---' app.log
```

### Múltiples líneas

```bash
sed '3i\Línea 1 insertada\
Línea 2 insertada\
Línea 3 insertada' archivo.txt
```

### Al inicio y final del archivo

```bash
# Al inicio (dirección 1)
sed '1i\<?xml version="1.0"?>' archivo.xml

# Al final (dirección $)
sed '$a\<!-- FIN -->' archivo.xml
```

---

## Cambio de línea (c)

`c` reemplaza la línea completa por el texto especificado.

```bash
# Reemplazar línea 3 por completo
sed '3c\NUEVA LÍNEA' archivo.txt

# Reemplazar líneas que contengan "error"
sed '/error/c\LÍNEA BLOQUEADA' archivo.txt

# Reemplazar un rango entero por un solo texto
sed '/BEGIN/,/END/c\BLOQUE COMPRIMIDO' archivo.txt
```

---

## Transformación (y///)

`y` transforma caracteres de forma uno-a-uno (como `tr`). No es regex, es traducción carácter por carácter.

```bash
# Convertir mayúsculas a minúsculas
sed 'y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/' archivo.txt

# Cambiar separadores
sed 'y/,;/;./' archivo.csv

# Cifrado ROT13 simple
sed 'y/ABCDEFGHIJKLMabcdefghijklmNOPQRSTUVWXYZnopqrstuvwxyz/NOPQRSTUVWXYZnopqrstuvwxyzABCDEFGHIJKLMabcdefghijklm/' mensaje.txt
```

> Nota: `y` requiere que ambos conjuntos tengan la misma longitud.

---

## Lectura y escritura (r, w)

| Comando | Descripción |
|---------|-------------|
| `r archivo` | Lee y **inserta el contenido** de otro archivo después de la línea actual |
| `w archivo` | Escribe la línea actual a un archivo |

```bash
# Insertar contenido de header.html antes de la primera línea
sed '1r header.html' pagina.html

# Insertar un aviso después de cada línea con "error"
sed '/error/r aviso.txt' app.log

# Guardar líneas que coinciden en un archivo
sed -n '/error/w errores.txt' app.log

# Guardar rango específico
sed -n '100,200w extracto.txt' archivo.txt
```

---

## Múltiples comandos

### -e (expresión)

```bash
sed -e 's/foo/bar/' -e 's/123/456/' archivo.txt
```

### Punto y coma (;)

```bash
sed 's/foo/bar/; s/123/456/' archivo.txt
```

### Bloques con llaves

```bash
# Múltiples comandos en un rango
sed -n '/error/{p; s/error/CRITICAL/p}' app.log

# Múltiples comandos con condiciones
sed '3,6{s/foo/bar/; s/123/456/; s/a/b/g}' archivo.txt
```

### -f (archivo de script)

```bash
# script.sed
s/foo/bar/
s/123/456/
/^#/d
$i\FIN DEL ARCHIVO

# Ejecutar
sed -f script.sed archivo.txt
```

---

## Edición in-place (-i)

`-i` modifica el archivo directamente en lugar de imprimir en stdout.

```bash
# Modificar archivo original (sin backup)
sed -i 's/foo/bar/g' archivo.txt

# Modificar con backup (crea archivo.txt.bak)
sed -i.bak 's/foo/bar/g' archivo.txt

# Backup con extensión personalizada
sed -i.backup 's/foo/bar/g' archivo.txt

# Sin backup pero explícito (GNU sed)
sed -i '' 's/foo/bar/g' archivo.txt   # BSD sed
sed --in-place 's/foo/bar/g' archivo.txt  # GNU sed explícito
```

> **Precaución con -i**: en macOS/BSD sed, `-i` requiere un argumento de extensión (puede ser cadena vacía: `-i ''`). En GNU sed la extensión es opcional.

---

## Espacio de patrones y espacio de espera (hold space)

sed tiene dos buffers de memoria:

| Buffer | Descripción |
|--------|-------------|
| **Pattern Space** | Buffer principal: una línea a la vez se procesa aquí |
| **Hold Space** | Buffer de respaldo: almacenamiento temporal |

### Comandos para manejar hold space

| Comando | Descripción |
|---------|-------------|
| `h` | Copia pattern space → hold space (sobrescribe) |
| `H` | Añade pattern space → hold space (append con \n) |
| `g` | Copia hold space → pattern space (sobrescribe) |
| `G` | Añade hold space → pattern space (append con \n) |
| `x` | Intercambia pattern space y hold space |

### Ejemplos prácticos

```bash
# Invertir orden de líneas (tac-like)
sed '1!G; h; $!d' archivo.txt
```

> **Explicación**: `1!G` = en todas las líneas excepto la primera, añade hold space al pattern space. `h` = guarda la línea actual en hold. `$!d` = excepto la última, elimina. Resultado: la primera línea queda al final, etc.

```bash
# Imprimir líneas pares e impares juntas
sed -n 'N; s/\n/ /p' archivo.txt

# Imprimir la línea anterior a cada "error"
sed -n '/error/{x; p; x; p}' app.log

# Imprimir líneas no consecutivas duplicadas
sed -n '$!N; /^\(.*\)\n\1$/!P; D' archivo.txt
```

### N, P, D — multilínea

| Comando | Descripción |
|---------|-------------|
| `N` | Añade la siguiente línea al pattern space (con \n) |
| `P` | Imprime hasta el primer \n del pattern space |
| `D` | Elimina hasta el primer \n del pattern space y vuelve a procesar |

```bash
# Unir cada dos líneas
sed 'N; s/\n/ /' archivo.txt

# Procesar párrafos
sed '/./{H; $!d}; x; s/^\n//; s/foo/bar/g' archivo.txt

# Imprimir líneas que no tienen duplicado consecutivo
sed '$!N; /^\(.*\)\n\1$/!P; D' archivo.txt
```

---

## Bucles y etiquetas (branching)

sed soporta etiquetas (`:etiqueta`) y bifurcaciones condicionales.

| Comando | Descripción |
|---------|-------------|
| `:label` | Define una etiqueta |
| `b label` | Salta incondicionalmente a la etiqueta |
| `t label` | Salta a la etiqueta si la última sustitución tuvo éxito |
| `T label` | Salta a la etiqueta si la última sustitución **no** tuvo éxito (GNU) |

```bash
# Reemplazar múltiples espacios por uno solo (hasta que no haya cambios)
sed ':a; s/  */ /g; ta' archivo.txt
```

> **Explicación**: `:a` define la etiqueta "a". `s/  */ /g` reemplaza dos o más espacios por uno. `ta` salta a "a" si se hizo algún reemplazo. Así que sigue reemplazando hasta que no queden espacios múltiples.

```bash
# Reemplazar globalmente con condicional
sed ':loop; s/foo/bar/g; t loop' archivo.txt

# Procesar solo si hay coincidencia, saltar si no
sed '/error/{s/error/CRITICAL/; H}; $!d; x; s/^\n//' app.log

# Añadir comas a números (1234567 → 1,234,567)
sed ':a; s/\(.*[0-9]\)\([0-9]\{3\}\)/\1,\2/; ta' numeros.txt
```

---

## Casos de uso reales

### 1. Archivos de log

```bash
# Anonimizar IPs en logs
sed -E 's/[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/XXX.XXX.XXX.XXX/g' access.log

# Añadir timestamp al inicio de cada línea (si no lo tiene)
sed -i 's/^/[2024-01-15] /' app.log

# Marcar líneas de error
sed -i '/ERROR/s/^/!!! /' app.log

# Quitar colores ANSI de logs
sed 's/\x1b\[[0-9;]*m//g' log_coloreado.txt

# Extraer solo horas de timestamps [14:30:22]
sed -n 's/.*\[\([0-9:]\{8\}\).*/\1/p' app.log | sort | uniq -c

# Compactar líneas de stack trace (que empiezan con espacio/tab) con la línea anterior
sed '/^[[:space:]]/{H; d}; x; s/\n//g' stacktrace.log
```

### 2. Archivos de configuración

```bash
# Descomentar líneas (quitar #)
sed -i 's/^#\(.*\)/\1/' config.conf

# Descomentar solo si es una directiva específica
sed -i '/^#Port/s/^#//' /etc/ssh/sshd_config

# Comentar líneas que contengan una palabra
sed -i '/PermitRootLogin/s/^/#/' /etc/ssh/sshd_config

# Cambiar valores en config (ej: cambiar puerto SSH)
sed -i 's/^Port 22/Port 2222/' /etc/ssh/sshd_config

# Añadir línea al final si no existe (idempotente)
grep -q "MaxAuthTries" /etc/ssh/sshd_config || sed -i '$a\MaxAuthTries 3' /etc/ssh/sshd_config
```

### 3. Procesamiento de archivos CSV/texto

```bash
# Eliminar BOM (Byte Order Mark) UTF-8 de CSV
sed -i '1s/^\xEF\xBB\xBF//' archivo.csv

# Normalizar saltos de línea Windows (CRLF) a Unix (LF)
sed -i 's/\r$//' archivo.txt

# Eliminar espacios al final de cada línea
sed -i 's/[[:space:]]*$//' archivo.txt

# Eliminar líneas en blanco al inicio y final
sed -e '/./,$!d' -e '/^$/d' -e :a -e '/^\n*$/{$d; N; ba' -e '}' archivo.txt
```

### 4. HTML/XML

```bash
# Eliminar tags HTML
sed 's/<[^>]*>//g' pagina.html

# Extraer contenido entre etiquetas específicas
sed -n '/<title>/,/<\/title>/{s/<[^>]*>//g; p}' pagina.html

# Comentar secciones de XML
sed '/<seccion>/,/<\/seccion>/s/^/<!-- /; /<\/seccion>/s/$/ -->/' archivo.xml
```

### 5. Cambios masivos en archivos

```bash
# Renombrar variable en todos los archivos .py
sed -i 's/old_variable/new_variable/g' *.py

# Cambiar versión en múltiples archivos
sed -i 's/version="1\.0\.0"/version="2.0.0"/g' setup.py package.json

# Añadir shebang a scripts que no lo tienen
sed -i '1s/^/#!\/usr\/bin\/env bash\n/' script.sh
```

### 6. Procesamiento de rutas

```bash
# Extraer nombre de archivo de ruta completa
echo "/home/user/docs/file.txt" | sed 's/.*\///'
# Resultado: file.txt

# Extraer directorio de ruta completa
echo "/home/user/docs/file.txt" | sed 's/\/[^/]*$//'
# Resultado: /home/user/docs

# Cambiar extensión de archivo
echo "imagen.jpg" | sed 's/\.[^.]*$/.png/'
# Resultado: imagen.png
```

---

## sed en redes y seguridad

### Parsear logs de red

```bash
# Extraer IPs únicas de un pcap (con tcpdump preprocesado)
tcpdump -nn -r captura.pcap | sed -n 's/.*IP \([0-9.]*\) >.*/\1/p' | sort -u

# Limpiar salida de ss para análisis
ss -tuna | sed '1d; s/  */ /g' | cut -d' ' -f5

# Formatear salida de traceroute
traceroute -n 8.8.8.8 | sed 's/  */ /g; s/ ms//g' | awk '{print $1, $2}'
```

### Anonimizar datos sensibles

```bash
# Anonimizar emails
sed -E 's/([a-zA-Z0-9]{2})[a-zA-Z0-9._%+-]+@/\1****@/g' contactos.txt

# Anonimizar números de tarjeta (mostrar últimos 4)
sed -E 's/[0-9]{4}[ -][0-9]{4}[ -][0-9]{4}[ -]([0-9]{4})/XXXX-XXXX-XXXX-\1/g' datos.txt

# Anonimizar contraseñas en logs (texto después de "password=")
sed -E 's/(password|pass|pwd)[=:]["'"'"']?[^& '"'"'"]+/\1=****/gi' app.log
```

### Detectar tráfico sospechoso

```bash
# Extraer consultas DNS (formato tcpdump)
tcpdump -n -r captura.pcap port 53 2>/dev/null | sed -n 's/.*A\? \([^ ]*\)\..*/\1/p' | sort -u

# Detectar intentos de path traversal en logs web
sed -n '/\.\.\/\|\.\.\\|%2e%2e%2f\|%2e%2e%5c/p' access.log
```

---

## Combinación con otras herramientas

### sed + grep

```bash
# grep filtra, sed transforma
grep "ERROR" app.log | sed 's/\[ERROR\]/!!!CRITICAL!!!/'

# sed como grep (no recomendado, más lento):
sed -n '/error/p' app.log       # = grep "error" app.log
sed -n '/error/!p' app.log      # = grep -v "error" app.log
```

### sed + awk

```bash
# sed limpia, awk procesa columnas
sed 's/\[//g; s/\]//g' app.log | awk '{ print $1, $5 }'

# awk selecciona, sed transforma
awk '{ print $1, $NF }' access.log | sed 's/^/IP: /; s/$/ FIN/'
```

### sed + sort

```bash
# sed para limpiar, sort para ordenar
sed 's/@.*//' emails.txt | sort -u
```

### sed + xargs

```bash
# Renombrar archivos en masa: foo1.txt → bar1.txt
ls foo*.txt | sed 's/foo/bar/' | xargs -I {} -n1 echo mv foo{}

# Reemplazar string en múltiples archivos (seguro: backup primero)
grep -rl "old_string" src/ | xargs sed -i.bak 's/old_string/new_string/g'
```

### sed + find

```bash
# Buscar y reemplazar en archivos específicos
find . -name "*.py" -exec sed -i 's/old_func/new_func/g' {} +

# Reemplazar solo en archivos que contienen el patrón
find . -type f -name "*.txt" -exec grep -q "foo" {} \; -exec sed -i 's/foo/bar/g' {} \;
```

### sed + cut

```bash
# sed selecciona líneas, cut extrae columnas
sed -n '/error/p' app.log | cut -d' ' -f1-5

# cut para posiciones fijas, sed para transformar
cut -c1-80 archivo.txt | sed 's/[[:space:]]*$//'
```

---

## Uno-liners imprescindibles

```bash
# Eliminar líneas en blanco
sed '/^$/d' archivo.txt

# Eliminar espacios al inicio
sed 's/^[[:space:]]*//' archivo.txt

# Eliminar espacios al final
sed 's/[[:space:]]*$//' archivo.txt

# Eliminar espacios al inicio y final
sed 's/^[[:space:]]*//; s/[[:space:]]*$//' archivo.txt

# Comprimir espacios múltiples a uno solo
sed 's/  */ /g' archivo.txt

# Comprimir espacios y tabs
sed 's/[[:space:]]\+/ /g' archivo.txt

# Invertir orden de líneas (tac)
sed '1!G; h; $!d' archivo.txt

# Duplicar cada línea
sed 'p' archivo.txt

# Numerar líneas (no vacías)
sed '/./=' archivo.txt | sed '/./N; s/\n/ /'

# Numerar todas las líneas
sed '=' archivo.txt | sed 'N; s/\n/ /'

# Mostrar solo líneas entre la 10 y la 20
sed -n '10,20p' archivo.txt

# Mostrar líneas pares
sed -n '2~2p' archivo.txt

# Mostrar líneas impares
sed -n '1~2p' archivo.txt

# Eliminar primera línea (cabecera)
sed '1d' archivo.csv

# Eliminar última línea
sed '$d' archivo.txt

# Eliminar desde la línea 10 hasta el final
sed '10,$d' archivo.txt

# Unir líneas cada N
sed 'N; s/\n/ /; N; s/\n/ /' archivo.txt  # unir de 3 en 3

# Insertar línea en blanco cada 5 líneas
sed '5G' archivo.txt

# Insertar línea en blanco después de cada línea
sed 'G' archivo.txt

# Convertir a mayúsculas
sed 'y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/' archivo.txt

# Convertir a minúsculas
sed 'y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/' archivo.txt

# Eliminar caracteres no imprimibles
sed 's/[^[:print:]\t]//g' archivo.txt

# Añadir línea después de línea 1
sed '1a\NUEVA LÍNEA' archivo.txt

# Añadir línea antes de línea 1
sed '1i\PRIMERA LÍNEA' archivo.txt

# Reemplazar saltos de línea (join all lines)
sed ':a; N; $!ba; s/\n/ /g' archivo.txt

# Imprimir secciones entre marcadores
sed -n '/START/,/END/p' archivo.txt

# Eliminar todo entre marcadores (sin incluirlos)
sed '/START/,/END/{//!d}' archivo.txt

# Quitar etiquetas HTML
sed 's/<[^>]*>//g' archivo.html

# Reemplazar comillas dobles escapadas
sed 's/\\"/"/g' archivo.json

# Extraer dominio de URL
sed -E 's|https?://([^/]+).*|\1|' urls.txt

# Contar líneas
sed -n '$=' archivo.txt

# Imprimir la línea más larga
sed -n '1h; /.\{$(wc -L < archivo.txt)\}/{p; q}' archivo.txt  # requiere cálculo externo
```

> **`sed -n '$='`**: `$` es la última línea, `=` imprime el número de línea. Es decir: en la última línea, imprime su número. Equivale a `wc -l`.

---

## Diferencias GNU sed vs BSD sed

| Característica | GNU sed (Linux) | BSD sed (macOS) |
|----------------|-----------------|-----------------|
| `-i` sin backup | `sed -i 's/foo/bar/g' f` | `sed -i '' 's/foo/bar/g' f` |
| `-i` con backup | `sed -i.bak 's/foo/bar/g' f` | `sed -i.bak 's/foo/bar/g' f` |
| `\t` en regex | Sí | No (usar tab literal o `[[:space:]]`) |
| `\n` en clase char | Sí | No |
| `~` (step) | Sí | No |
| `I` (ignore case) | Sí | `I` al final de s/// |
| `T` (branch no match) | Sí | No |
| `[[:alpha:]]` | Sí | Sí |

```bash
# Compatible: usar siempre [[:space:]] en vez de \t
sed 's/[[:space:]]/ /g' archivo.txt

# Compatible: -i con backup
sed -i.bak 's/foo/bar/g' archivo.txt
```
