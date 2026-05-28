# awk — Guía completa

**Nivel:** 🟡 Intermedio
**Archivos de práctica:** `labs/datos.txt`, `labs/employees_data.txt`
**Ver escenarios relacionados:** [`networking/01-detect-ssh-brute-force`](../scenarios/networking/01-detect-ssh-brute-force.md), [`web/01-performance`](../scenarios/web/01-performance-and-error-analysis.md)

## ⚡ Quick command

`awk '{print $1}' labs/datos.txt`

## ⚡ Quick run

```bash
awk '{ print $1, $3 }' labs/datos.txt | column -t
```

---

## Índice

1. [¿Qué es awk?](#qué-es-awk)
2. [Estructura básica](#estructura-básica)
3. [Campos y separadores](#campos-y-separadores)
4. [Patrones y acciones](#patrones-y-acciones)
5. [Variables internas](#variables-internas)
6. [Operadores](#operadores)
7. [Expresiones regulares](#expresiones-regulares)
8. [Variables definidas por el usuario](#variables-definidas-por-el-usuario)
9. [Arrays asociativos](#arrays-asociativos)
10. [Estructuras de control](#estructuras-de-control)
11. [Funciones integradas](#funciones-integradas)
12. [Formato de salida (printf)](#formato-de-salida-printf)
13. [BEGIN y END](#begin-y-end)
14. [getline — leer líneas adicionales](#getline)
15. [Archivos múltiples](#archivos-múltiples)
16. [Combinación con otras herramientas](#combinación-con-otras-herramientas)
17. [Ejemplos profesionales reales](#ejemplos-profesionales-reales)
18. [awk uno-liners imprescindibles](#awk-uno-liners-imprescindibles)

---

## ¿Qué es awk?

awk es un lenguaje de procesamiento de texto orientado a registros (líneas) y campos (columnas). Fue diseñado para **escaneo de patrones y procesamiento por campos**. No es un simple comando: es un lenguaje completo con variables, arrays, estructuras de control y funciones.

awk procesa archivos línea por línea, divide cada línea en campos, y ejecuta acciones sobre las líneas que cumplen un patrón.

> **Nota sobre implementaciones**: Las distintas implementaciones de awk (gawk, mawk, nawk) a menudo hacen del binario `awk` un symlink a su propio binario. Lo más común en Linux es que `awk` sea un symlink a `gawk` (GNU awk) o a `mawk`. Referencia: <https://github.com/onetrueawk/awk>

### ¿Por qué usar awk y no cut/grep/sed?

- awk maneja **campos delimitados** de forma nativa y flexible
- awk permite **condiciones y operaciones aritméticas** sobre los campos
- awk tiene **printf** para formatear salida exacta
- awk trabaja con **variables, arrays, bucles**

---

## Estructura básica

```text
awk 'patrón { acción }' archivo
```

- `patrón`: condición que debe cumplir la línea para ejecutar la acción (puede omitirse: aplica a todas)
- `acción`: bloque de código entre llaves
- `archivo`: archivo de entrada (puede omitirse para leer de stdin)

Si solo hay acción sin patrón, se ejecuta para TODAS las líneas.

```bash
# Imprimir todas las líneas (cat-like)
awk '{ print }' archivo.txt

# Imprimir solo líneas que contengan "error"
awk '/error/ { print }' archivo.txt
```

---

## Campos y separadores

### $0, $1, $2, ..., $NF

- `$0`: la línea completa
- `$1`: primer campo
- `$2`: segundo campo
- `$NF`: último campo
- `$(NF-1)`: penúltimo campo

```bash
# Imprimir primer y tercer campo
awk '{ print $1, $3 }' archivo.txt
```

### -F — opción para definir separador de campos (field separator)

`-F` especifica el delimitador de campos. Por defecto awk separa por **espacios en blanco** (uno o más espacios/tabs).

```bash
# Separador: dos puntos (típico de /etc/passwd)
awk -F: '{ print $1, $6 }' /etc/passwd

# Separador: coma (archivos CSV)
awk -F, '{ print $1, $2 }' datos.csv
```

### FS — variable interna de separador de campos (field separator)

Equivalente a `-F` pero se define dentro del script awk, normalmente en el bloque `BEGIN`.

```bash
awk 'BEGIN { FS = ":" } { print $1, $6 }' /etc/passwd
```

### RS — separador de registros (record separator)

Por defecto es `\n` (salto de línea). Se puede cambiar para procesar registros multilínea.

```bash
# Procesar párrafos separados por línea vacía
awk 'BEGIN { RS = "" } { print $1 }' archivo.txt
```

### OFS — separador de salida de campos (output field separator)

Por defecto es un espacio. Controla cómo se separan los campos al imprimir con `print`.

```bash
# Imprimir campos separados por coma
awk 'BEGIN { OFS = "," } { print $1, $2 }' archivo.txt
```

### ORS — separador de salida de registros (output record separator)

Por defecto es `\n`. Controla el separador entre registros al imprimir.

```bash
# Unir todas las líneas separadas por espacio
awk 'BEGIN { ORS = " " } { print $1 }' archivo.txt
```

---

## Patrones y acciones

### Patrones por contenido (regex)

```bash
# Líneas que contengan "error"
awk '/error/ { print }' archivo.txt

# Líneas que empiecen por "192.168"
awk '/^192\.168/ { print }' archivo.log
```

### Patrones por comparación de campos

```bash
# Segundo campo mayor que 100
awk '$2 > 100 { print }' archivo.txt

# Primer campo igual a "root"
awk '$1 == "root" { print }' /etc/passwd

# Segundo campo NO vacío
awk '$2 != "" { print }' archivo.txt
```

### Rangos de líneas

```bash
# Desde la línea que contenga "start" hasta la que contenga "end"
awk '/start/, /end/ { print }' archivo.txt
```

### Combinación de patrones

```bash
# AND: campo1 > 10 Y campo2 < 5
awk '$1 > 10 && $2 < 5 { print }'

# OR: campo1 == "ERROR" O campo1 == "WARN"
awk '$1 == "ERROR" || $1 == "WARN" { print }'

# NOT: líneas que NO contengan "debug"
awk '!/debug/ { print }'
```

---

## Variables internas

| Variable | Significado |
|----------|-------------|
| `FS` | Separador de campos de entrada (Field Separator) |
| `OFS` | Separador de campos de salida (Output Field Separator) |
| `RS` | Separador de registros de entrada (Record Separator) |
| `ORS` | Separador de registros de salida (Output Record Separator) |
| `NF` | Número de campos en la línea actual (Number of Fields) |
| `NR` | Número de registro actual (línea actual) (Number of Record) |
| `FNR` | Número de registro dentro del archivo actual (File Number of Record) |
| `FILENAME` | Nombre del archivo actual |
| `ARGC` | Número de argumentos (Argument Count) |
| `ARGV` | Array de argumentos (Argument Vector) |
| `RLENGTH` | Longitud del texto emparejado en match() |
| `RSTART` | Posición inicial del texto emparejado en match() |

```bash
# Imprimir número de línea y contenido
awk '{ print NR, $0 }' archivo.txt

# Imprimir número de campos por línea
awk '{ print NF, $0 }' archivo.txt

# Ignorar cabeceras (saltar primera línea)
awk 'NR > 1 { print }' archivo.csv

# Procesar solo líneas de la 10 a la 20
awk 'NR >= 10 && NR <= 20 { print }' archivo.txt
```

---

## Operadores

### Aritméticos

| Operador | Significado |
|----------|-------------|
| `+` | Suma |
| `-` | Resta |
| `*` | Multiplicación |
| `/` | División |
| `%` | Módulo (resto) |
| `^` o `**` | Potenciación |
| `++` | Incremento |
| `--` | Decremento |

```bash
# Calcular IVA (21%) sobre el precio en $3
awk '{ print $1, $2, $3 * 1.21 }' productos.txt

# Sumar dos campos
awk '{ total = $2 + $3; print $1, total }' archivo.txt
```

### Asignación

| Operador | Ejemplo | Equivale a |
|----------|---------|------------|
| `=` | `a = 5` | asignación simple |
| `+=` | `a += 5` | `a = a + 5` |
| `-=` | `a -= 5` | `a = a - 5` |
| `*=` | `a *= 2` | `a = a * 2` |
| `/=` | `a /= 2` | `a = a / 2` |
| `%=` | `a %= 2` | `a = a % 2` |

### Comparación

| Operador | Significado |
|----------|-------------|
| `==` | Igual que |
| `!=` | Distinto de |
| `<` | Menor que |
| `>` | Mayor que |
| `<=` | Menor o igual que |
| `>=` | Mayor o igual que |
| `~` | Coincide con regex |
| `!~` | No coincide con regex |

```bash
# Campo que contenga dígitos
awk '$1 ~ /[0-9]/ { print }' archivo.txt

# Campo que NO empiece por A
awk '$1 !~ /^A/ { print }' archivo.txt
```

### Lógicos

| Operador | Significado |
|----------|-------------|
| `&&` | AND (y) |
| `\|\|` | OR (o) |
| `!` | NOT (no) |

---

## Expresiones regulares

awk usa regex estilo **ERE** (Extended Regular Expressions), similar a grep -E o egrep.

### Sintaxis básica

| Símbolo | Significado |
|---------|-------------|
| `.` | Cualquier carácter excepto nueva línea |
| `^` | Inicio de línea |
| `$` | Fin de línea |
| `*` | Cero o más repeticiones del carácter anterior |
| `+` | Una o más repeticiones |
| `?` | Cero o una repetición |
| `[abc]` | Uno de los caracteres a, b, c |
| `[^abc]` | Ninguno de a, b, c |
| `[a-z]` | Rango de a a z |
| `\|` | Alternancia (OR) |
| `()` | Agrupación |
| `{n,m}` | Entre n y m repeticiones |

```bash
# Direcciones IP (octetos de 1-3 dígitos)
awk '/^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/' archivo.log

# Correos electrónicos
awk '/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/' archivo.txt
```

### Regex dinámica con ~ y !~

```bash
# Campo $1 coincide con patrón "error" (insensible a mayúsculas con IGNORECASE)
awk 'BEGIN { IGNORECASE = 1 } $1 ~ /error/ { print }' archivo.log
```

> **IGNORECASE**: variable que, si es distinta de cero, hace que toda la comparación de regex ignore mayúsculas/minúsculas.

---

## Variables definidas por el usuario

Se crean en el momento de asignarlas. No requieren declaración. Por defecto son **0** (numéricas) o **cadena vacía** (string). Son sensibles a mayúsculas.

```bash
awk '{
  contador++
  suma += $2
  promedio = suma / contador
  print contador, suma, promedio
}' archivo.txt
```

### Variables de tipo string

```bash
awk '{
  nombre = $1
  apellido = $2
  nombre_completo = nombre " " apellido   # concatenación sin operador
  print nombre_completo
}' archivo.txt
```

### Variables de tipo numérico

```bash
# Contar, acumular, promediar
awk '{ suma += $2 } END { print "Total:", suma }' ventas.txt
```

---

## Arrays asociativos

awk permite arrays donde los índices no son numéricos, sino **strings** (hash maps / diccionarios).

### Sintaxis básica

```bash
awk '{ count[$1]++ } END { for (k in count) print k, count[k] }' archivo.txt
```

### Ejemplos útiles

```bash
# Contar ocurrencias de cada valor en $1
awk '{ ips[$1]++ } END { for (ip in ips) print ip, ips[ip] }' access.log

# Acumular valores por categoría
awk '{ total[$1] += $2 } END { for (cat in total) print cat, total[cat] }' ventas.txt

# Eliminar duplicados preservando orden (solo primera ocurrencia)
awk '!visto[$0]++ { print }' archivo.txt
```

> **Explicación de `!visto[$0]++`**: `visto[$0]` es 0 la primera vez (falso), `!0` es verdadero, imprime. Luego `++` lo incrementa a 1. Las siguientes veces `visto[$0]` es >=1, `!` lo vuelve falso, no imprime.

### Eliminar un elemento

```bash
delete array[indice]

# Eliminar todo el array
delete array
```

### Recorrer arrays

```bash
# for...in — orden no garantizado
for (clave in array) {
  print clave, array[clave]
}

# Recorrer por índices numéricos (si los índices son números)
for (i = 1; i <= max; i++) {
  print array[i]
}
```

### Ordenar arrays con asort / asorti

```bash
# asort: ordena por valor (descarta los índices originales)
n = asort(array, destino)

# asorti: ordena por índice (descarta los valores originales)
n = asorti(array, destino)

# Ejemplo: ordenar valores numéricos
awk '{ valores[NR] = $2 } END { n = asort(valores); for (i = 1; i <= n; i++) print valores[i] }' archivo.txt
```

---

## Estructuras de control

### if / else

```bash
awk '{
  if ($2 > 100) {
    print $1, "ALTO"
  } else if ($2 > 50) {
    print $1, "MEDIO"
  } else {
    print $1, "BAJO"
  }
}' archivo.txt
```

### while

```bash
# Recorrer todos los campos de una línea
awk '{
  i = 1
  while (i <= NF) {
    print $i
    i++
  }
}' archivo.txt
```

### do / while

```bash
awk '{
  i = 1
  do {
    print $i
    i++
  } while (i <= NF)
}' archivo.txt
```

### for

```bash
# Bucle tradicional
awk '{
  for (i = 1; i <= NF; i++) {
    print $i
  }
}'

# Bucle sobre array
awk '{ count[$1]++ } END { for (k in count) print k, count[k] }'
```

### break / continue

```bash
# break: sale del bucle
awk '{
  for (i = 1; i <= NF; i++) {
    if ($i == "stop") break
    print $i
  }
}'

# continue: salta a la siguiente iteración
awk '{
  for (i = 1; i <= NF; i++) {
    if ($i ~ /^#/) continue
    print $i
  }
}'
```

### next / exit

- `next`: salta al siguiente registro (línea), ignora el resto del bloque
- `exit`: termina el procesamiento completamente

```bash
# Saltar líneas comentadas
awk '/^#/ { next } { print }' config.conf

# Salir después de la primera coincidencia
awk '/root/ { print; exit }' /etc/passwd
```

---

## Funciones integradas

### Funciones numéricas

| Función | Descripción |
|---------|-------------|
| `int(x)` | Parte entera de x |
| `sqrt(x)` | Raíz cuadrada |
| `exp(x)` | e elevado a x |
| `log(x)` | Logaritmo natural |
| `sin(x)` | Seno |
| `cos(x)` | Coseno |
| `atan2(y, x)` | Arco tangente de y/x |
| `rand()` | Número aleatorio entre 0 y 1 |
| `srand(x)` | Inicializa generador aleatorio |

### Funciones de string

| Función | Descripción |
|---------|-------------|
| `length(s)` | Longitud de la string s |
| `index(s, sub)` | Posición de sub en s (0 si no está) |
| `substr(s, i, n)` | Substring de s desde i, n caracteres |
| `split(s, a, sep)` | Divide s en array a usando sep |
| `match(s, regex)` | Busca regex en s (establece RSTART y RLENGTH) |
| `sub(regex, reemp, s)` | Reemplaza primera ocurrencia de regex en s |
| `gsub(regex, reemp, s)` | Reemplaza TODAS las ocurrencias de regex en s |
| `gensub(regex, reemp, g, s)` | Reemplazo avanzado con grupos (gawk) |
| `tolower(s)` | Convierte a minúsculas |
| `toupper(s)` | Convierte a mayúsculas |
| `sprintf(fmt, lista)` | Formatea string como printf pero lo devuelve |

```bash
# Longitud de cada línea
awk '{ print length($0), $0 }' archivo.txt

# Extraer extensión de archivo
awk '{ ext = substr($1, length($1) - 2); print ext }' archivos.txt

# Dividir una línea por comas
awk '{ split($0, arr, ","); print arr[1], arr[2] }' archivo.csv

# A mayúsculas
awk '{ print toupper($1) }' archivo.txt

# Reemplazar todas las comas por punto y coma
awk '{ gsub(/,/, ";"); print }' archivo.csv

# Reemplazar solo la primera coma
awk '{ sub(/,/, ";"); print }' archivo.csv

# match + substr: extraer texto entre paréntesis
awk 'match($0, /\(([^)]+)\)/, a) { print a[1] }' archivo.txt
```

#### gensub — la función más potente para reemplazos

`gensub(regex, reemplazo, modo, target)` es una extensión de gawk.

- `modo == "g"` o `modo == 1` etc.: "g" para global, número para ocurrencia específica
- Permite referencias `\\1`, `\\2` para grupos de captura

```bash
# Invertir primer y segundo campo
awk '{ print gensub(/([^ ]+) ([^ ]+)/, "\\2 \\1", "g") }' archivo.txt

# Extraer dígitos después de "ID:"
awk 'match($0, /ID: ([0-9]+)/, a) { print a[1] }' archivo.txt
```

### Funciones de tiempo (gawk)

| Función | Descripción |
|---------|-------------|
| `systime()` | Timestamp Unix actual (segundos desde 1970) |
| `strftime(formato, timestamp)` | Formatea timestamp como fecha |

```bash
awk 'BEGIN { print strftime("%Y-%m-%d %H:%M:%S", systime()) }'
```

### Funciones de información

| Función | Descripción |
|---------|-------------|
| `typeof(x)` | Devuelve el tipo de x ("string", "number", "array", etc.) |

---

## Formato de salida (printf)

Mucho más potente que `print`. Permite controlar ancho, alineación, decimales.

### Sintaxis

```awk
printf "formato", valor1, valor2, ...
```

### Especificadores

| Especificador | Significado |
|---------------|-------------|
| `%s` | String |
| `%d` | Entero decimal |
| `%f` | Número flotante |
| `%e` | Notación científica |
| `%x` | Hexadecimal |
| `%o` | Octal |
| `%%` | Signo % literal |

### Modificadores

```bash
# Ancho mínimo de 10 caracteres
printf "%10s", $1

# Alineación izquierda (con -)
printf "%-10s", $1

# Decimales (2 dígitos)
printf "%.2f", $2

# Combinado: ancho 8, 2 decimales
printf "%8.2f", $3

# Ceros a la izquierda
printf "%05d", $1
```

```bash
# Ejemplo: tabla formateada
awk '{ printf "%-20s %8.2f %5d\n", $1, $2, $3 }' archivo.txt

# Registro de log con timestamp
awk '{ printf "[%s] %-5s %s\n", strftime("%H:%M:%S"), $1, $2 }' archivo.log
```

---

## BEGIN y END

### BEGIN — se ejecuta ANTES de procesar la primera línea

Útil para inicializar variables, establecer separadores, imprimir cabeceras.

```bash
awk 'BEGIN {
  FS = ":"
  OFS = "\t"
  print "Usuario", "Shell"
  print "------", "-----"
}
{
  print $1, $7
}' /etc/passwd
```

### END — se ejecuta DESPUÉS de procesar la última línea

Útil para totales, promedios, resúmenes.

```bash
awk '{
  suma += $2
  count++
}
END {
  print "Suma:", suma
  print "Promedio:", suma / count
  print "Registros:", count
}' archivo.txt
```

### BEGINFILE y ENDFILE (gawk)

Se ejecutan al comenzar/terminar cada archivo (en procesamiento de múltiples archivos).

```bash
awk 'BEGINFILE { print "Procesando:", FILENAME }
     { count++ }
     ENDFILE { print "Líneas:", count; count = 0 }' archivo1.txt archivo2.txt
```

---

## getline

getline permite leer una línea de forma explícita desde varias fuentes.

### Sintaxis

```awk
getline                         # lee siguiente línea del archivo actual
getline var                     # lo mismo, pero guarda en var
getline var < "archivo"         # lee de un archivo específico
"comando" | getline var         # lee salida de un comando externo
```

### Códigos de retorno

| Valor | Significado |
|-------|-------------|
| `1` | Línea leída correctamente |
| `0` | Fin de archivo |
| `-1` | Error |

```bash
# Imprimir pares de líneas
awk '{ if (getline segunda) print $0, segunda }' archivo.txt

# Leer primera línea como cabecera y luego procesar
awk 'BEGIN { getline header; print "HEADER:", header } { print $0 }' archivo.csv

# Comparar línea actual con la anterior
awk '{ if (NR > 1 && $1 != anterior) print "Cambio:", $1; anterior = $1 }' archivo.txt

# Leer de un archivo de configuración
awk 'BEGIN { while ((getline linea < "/etc/hosts") > 0) print linea }'

# Leer salida de un comando externo
awk 'BEGIN { "date" | getline fecha; print "Hoy es:", fecha }'
```

### getline con pipes a comandos externos

```bash
# Obtener resolución DNS de cada IP
awk '{
  cmd = "host " $1
  cmd | getline resultado
  close(cmd)
  print $1, resultado
}' ips.txt
```

> **close()**: es obligatorio cerrar pipes y archivos abiertos con getline para evitar agotar los descriptores de archivo del sistema.

---

## Archivos múltiples

awk procesa varios archivos secuencialmente. `FILENAME` indica el archivo actual, `FNR` el número de línea dentro del archivo actual.

```bash
# Saber de qué archivo viene cada línea
awk '{ print FILENAME, FNR, $0 }' archivo1.txt archivo2.txt

# Saltar cabeceras de cada archivo
awk 'FNR > 1 { print }' archivo1.csv archivo2.csv

# Procesar diferente según el archivo
awk 'FILENAME == "clientes.txt" { print "Cliente:", $1 }
     FILENAME == "ventas.txt"   { print "Venta:", $1, $2 }' clientes.txt ventas.txt
```

### Combinar archivos por clave (join-like)

```bash
# Cargar primer archivo en un array, usar en el segundo
awk 'NR == FNR { precios[$1] = $2; next }
     { print $0, precios[$1] }' precios.txt ventas.txt
```

> **Explicación**: `NR == FNR` se cumple solo mientras se lee el primer archivo (porque NR global == FNR del archivo actual). Ahí cargamos precios. `next` salta al siguiente registro. Cuando termina el primer archivo, NR > FNR, y pasamos al bloque que imprime ventas con precio.

---

## Combinación con otras herramientas

### awk + sort

```bash
# Los acumuladores de awk no ordenan, así que se combina con sort
awk '{ ips[$1]++ } END { for (ip in ips) print ips[ip], ip }' access.log | sort -rn

# Ordenar por valor numérico (segundo campo) descendente
awk '{ print $1, $2 }' archivo.txt | sort -k2 -rn
```

### awk + uniq

```bash
# Contar y mostrar ocurrencias únicas
awk '{ print $1 }' archivo.log | sort | uniq -c | sort -rn
```

### awk + head / tail

```bash
# Top 10 IPs por número de peticiones
awk '{ ips[$1]++ } END { for (i in ips) print ips[i], i }' access.log | sort -rn | head -10

# Últimas 5 líneas de un log, extrayendo campos
tail -5 app.log | awk '{ print $1, $5 }'
```

### awk + cut

```bash
# Cuando necesitas cortar antes de awk
cut -d' ' -f1-3 access.log | awk '{ print $1, $3 }'

# O al revés, awk para seleccionar campos y cut para columnas fijas
awk '{ print $1, $6 }' archivo.txt | cut -c1-20
```

### awk + grep

```bash
# grep filtra líneas, awk procesa campos
grep "ERROR" app.log | awk '{ print $1, $2, $NF }'

# awk ya tiene su propio filtrado, pero a veces grep es más rápido para preseleccionar
```

### awk + sed

```bash
# sed limpia/preprocesa, awk analiza
sed 's/\[//g; s/\]//g' access.log | awk '{ print $1, $4 }'

# awk procesa, sed da formato final
awk '{ print $1, $NF }' archivo.txt | sed 's/^/IP: /'
```

### awk + xargs

```bash
# awk genera argumentos para otro comando
awk '{ print $1 }' ips.txt | xargs -I{} ping -c1 {} 2>/dev/null

# Matar procesos por nombre
ps aux | awk '/apache/ { print $2 }' | xargs kill
```

### awk + bc (calculadora)

```bash
# awk genera expresiones matemáticas para bc
awk '{ print $2, "+", $3 }' numeros.txt | bc
```

---

## Ejemplos profesionales reales

### 1. Analizar access.log de nginx/apache

Formato típico:

```text
192.168.1.1 - - [10/Oct/2023:13:55:36 +0000] "GET /index.html HTTP/1.1" 200 2326
```

```bash
# IPs únicas que devolvieron 404
awk '$9 == "404" { ips[$1]++ } END { for (i in ips) print i }' access.log

# Top 10 URL más solicitadas (campo $7 es la ruta)
awk '{ urls[$7]++ } END { for (u in urls) print urls[u], u }' access.log | sort -rn | head -10

# Total de bytes transferidos (campo $10)
awk '{ total += $10 } END { print "Total bytes:", total }' access.log

# Peticiones por hora (extrayendo la hora del timestamp)
awk '{
  split($4, t, /[/:]/)
  hora = t[4]
  horas[hora]++
}
END {
  for (h in horas) printf "%02d:00 %d peticiones\n", h, horas[h]
}' access.log | sort

# Respuestas 5xx
awk '$9 ~ /^5/ { print $1, $7, $9 }' access.log

# Tasa de error (peticiones 4xx+5xx / total)
awk '{ total++ } $9 ~ /^[45]/ { errores++ } END { print "Tasa error:", errores/total*100, "%" }' access.log

# Usuarios con más peticiones simultáneas (basado en timestamp + IP)
awk '{ print $4, $1 }' access.log | sort | uniq -c | sort -rn | head -10
```

### 2. Analizar /etc/passwd

```bash
# Usuarios con shell bash
awk -F: '$7 ~ /bash$/ { print $1 }' /etc/passwd

# UIDs mayores a 1000 (usuarios reales)
awk -F: '$3 >= 1000 { print $1, $3 }' /etc/passwd

# Listar shell y cantidad de usuarios que la usan
awk -F: '{ shells[$NF]++ } END { for (s in shells) print shells[s], s }' /etc/passwd
```

### 3. Analizar logs del sistema (syslog)

```bash
# Errores por hora
awk '/ERROR/ {
  split($3, t, ":")
  hora = t[1]
  errores[hora]++
}
END {
  for (h in errores) print "Hora " h ": " errores[h] " errores"
}' syslog.log

# Servicios que más errores generan
awk '/ERROR/ { servicios[$5]++ } END { for (s in servicios) print servicios[s], s }' syslog.log | sort -rn
```

### 4. Procesar CSV

```bash
# Promedio de columna numérica, saltando cabecera
awk -F, 'NR > 1 { suma += $3; n++ } END { print suma/n }' datos.csv

# Convertir CSV a TSV (Tabulator-Separated Values)
awk 'BEGIN { FS = ","; OFS = "\t" } { $1=$1; print }' datos.csv

# Filtrar filas por valor de columna
awk -F, '$5 > 1000 { print $1, $2, $5 }' ventas.csv

# Añadir columna calculada
awk -F, '{ print $0, $2 * $3 }' OFS=, inventario.csv

# Mostrar solo columnas 1, 3 y 5 de un CSV
awk -F, '{ print $1, $3, $5 }' OFS=, datos.csv
```

> **Explicación de `$1=$1`**: en awk, asignar un campo a sí mismo fuerza a awk a reensamblar `$0` usando `OFS` como separador. Así se convierte el separador de entrada al de salida.

### 5. Monitoreo de procesos

```bash
# Procesos de un usuario específico
ps aux | awk '$1 == "carludev" { print $11, $3, $4 }'

# Suma de memoria RSS de procesos de un usuario
ps aux | awk '$1 == "www-data" { suma += $6 } END { print suma " KB" }'

# Procesos con más de 10% de CPU
ps aux | awk '$3 > 10 { print $2, $11, $3 "%" }'
```

### 6. Análisis de tráfico de red

```bash
# Conexiones por estado (desde ss)
ss -tuna | awk 'NR > 1 { estados[$2]++ } END { for (e in estados) print e, estados[e] }'

# Puertos locales más usados
ss -tuna | awk 'NR > 1 { split($4, a, ":"); puertos[a[2]]++ } END { for (p in puertos) print p, puertos[p] }' | sort -rn

# Conexiones por IP remota
ss -tuna | awk 'NR > 1 { split($5, a, ":"); ips[a[1]]++ } END { for (i in ips) print ips[i], i }' | sort -rn | head -10
```

### 7. Análisis de archivos de log con fechas

```bash
# Eventos entre dos horas específicas
awk '$3 >= "14:00:00" && $3 <= "15:00:00" { print }' app.log

# Eventos de hoy
awk -v hoy=$(date +%b' '%d) '$1 == substr(hoy,1,3) && $2 == substr(hoy,5) { print }' app.log
```

### 8. Procesar archivos de configuración

```bash
# Extraer valores de un archivo clave=valor
awk -F= '$1 == "PORT" { print $2 }' config.ini

# Ignorar comentarios y líneas vacías en un config
awk '/^[^#]/ && NF > 0 { print }' config.conf

# Parsear bloques (configuración por secciones)
awk '/^\[/{ seccion = $0 } /^user =/{ print seccion, $0 }' config.ini
```

### 9. Scripts awk autocontenidos

```bash
#!/usr/bin/awk -f
BEGIN {
  FS = ":"
  print "=== REPORTE DE USUARIOS ==="
  printf "%-20s %-30s %s\n", "USUARIO", "HOME", "SHELL"
  printf "%-20s %-30s %s\n", "------", "----", "-----"
}
{
  printf "%-20s %-30s %s\n", $1, $6, $7
}
END {
  print "==========================="
}
```

Guardar como `usuarios.awk` y ejecutar:

```bash
chmod +x usuarios.awk
./usuarios.awk /etc/passwd
```

---

### Tabla formateada con cabecera y alineación

Ejemplo clásico: usuarios con UID >= 1000, usando `%-20s` (string alineada a izquierda con ancho 20) y `%6d` (entero alineado a derecha con ancho 6):

```bash
awk 'BEGIN {
  FS = ":"
  printf "%-20s %6s %25s\n", "Name", "UID", "Shell"
  print "-------------------- ------ -------------------------"
}
$3 >= 1000 {
  printf "%-20s %6d %25s\n", $1, $3, $7
}' /etc/passwd
```

## awk uno-liners imprescindibles

```bash
# Eliminar duplicados preservando orden
awk '!visto[$0]++' archivo.txt

# Imprimir líneas con más de N campos
awk 'NF > 10' archivo.txt

# Imprimir líneas no vacías
awk 'NF > 0' archivo.txt

# Sumar una columna
awk '{ suma += $1 } END { print suma }' archivo.txt

# Contar líneas
awk 'END { print NR }' archivo.txt

# Promedio de columna
awk '{ s += $2; c++ } END { print s/c }' archivo.txt

# Máximo de columna
awk '$2 > max { max = $2; linea = $0 } END { print max, linea }' archivo.txt

# Mínimo de columna
awk 'NR == 1 { min = $2 } $2 < min { min = $2 } END { print min }' archivo.txt

# Imprimir la línea más larga
awk 'length > max { max = length; linea = $0 } END { print linea }' archivo.txt

# Imprimir solo líneas impares
awk 'NR % 2 == 1' archivo.txt

# Imprimir solo líneas pares
awk 'NR % 2 == 0' archivo.txt

# Imprimir cada tercera línea empezando desde la primera
awk 'NR % 3 == 1' archivo.txt

# Transponer campos a registros
awk '{ for (i = 1; i <= NF; i++) print $i }' archivo.txt

# Unir líneas cada N registros
awk 'ORS = NR % 3 ? "," : "\n"' archivo.txt

# Reemplazar campo condicionalmente
awk '$3 == "ERROR" { $3 = "CRITICAL" } 1' archivo.txt

# Añadir número de línea
awk '{ print NR, $0 }' archivo.txt

# Calcular diferencias entre líneas consecutivas
awk 'NR > 1 { print $1 - anterior } { anterior = $1 }' numeros.txt

# Imprimir penúltimo campo
awk '{ print $(NF-1) }' archivo.txt

# Campos del 2 al último
awk '{ for (i = 2; i <= NF; i++) printf "%s ", $i; print "" }' archivo.txt

# Dar la vuelta a los campos de cada línea
awk '{ for (i = NF; i >= 1; i--) printf "%s ", $i; print "" }' archivo.txt

# Formatear números con separador de miles
awk '{ printf "%'"'"'d\n", $1 }' numeros.txt
```

> **Nota sobre `1` al final de un bloque awk**: en awk, `1` es una condición que siempre es verdadera (como `true`), y al no tener acción asociada, la acción por defecto es `{ print $0 }`. Es un atajo para imprimir la línea modificada tras las operaciones anteriores.

---

## Consejos y buenas prácticas

1. **Usa BEGIN para inicializar**: define FS, OFS, cabeceras, siempre en BEGIN.
2. **Usa END para resúmenes**: totales, promedios, reportes finales.
3. **Comillas simples para el script**: evita que el shell interprete `$1`, `$2`, etc.
4. **Usa -v para pasar variables del shell**: `awk -v umbral=100 '$2 > umbral' archivo.txt`.
5. **Cierra pipes con close()**: `close(cmd)` después de `cmd | getline`.
6. **Prefiere awk antes que sed para campos**: sed maneja regex, awk maneja columnas.
7. **Los arrays asociativos no tienen orden**: usa `asort`/`asorti` o pipea a `sort`.
8. **Verifica qué versión tienes**: `awk --version` — gawk tiene muchas funciones extra.
9. **Los rangos numéricos se comparan directamente**: no necesitas convertir, awk lo hace automático.
10. **Usa `--posix` o `--traditional`** si necesitas compatibilidad con otras versiones de awk.

---

> **See also**: `gawk` — la implementación GNU de awk, la más completa y la que recomendamos para uso profesional. Instálala con `sudo apt install gawk`.

## Diferencia entre awk, gawk, mawk, nawk

| Versión | Descripción |
|---------|-------------|
| **awk** (original) | Versión AT&T, rara vez instalada hoy |
| **nawk** | "New awk", versión mejorada de 1987 |
| **gawk** | GNU awk, la más común en Linux. Tiene `gensub`, `asort`, `strftime`, `IGNORECASE`, `BEGINFILE`/`ENDFILE` |
| **mawk** | awk rápido y ligero, común en Debian/Ubuntu. No tiene `gensub` ni `asort` |

```bash
# Ver qué awk tienes por defecto
ls -la $(which awk)

# Instalar gawk si no está
sudo apt install gawk
```
