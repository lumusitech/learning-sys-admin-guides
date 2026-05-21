# wc — Guía completa

## Índice
1. [¿Qué es wc?](#qué-es-wc)
2. [Sintaxis básica](#sintaxis-básica)
3. [Contar líneas (-l)](#contar-líneas--l)
4. [Contar palabras (-w)](#contar-palabras--w)
5. [Contar caracteres (-m) vs bytes (-c)](#contar-caracteres--m-vs-bytes--c)
6. [Contar todo (sin opciones)](#contar-todo-sin-opciones)
7. [Contar desde entrada estándar (stdin)](#contar-desde-entrada-estándar-stdin)
8. [Contar la línea más larga (-L)](#contar-la-línea-más-larga--l)
9. [Escenarios reales](#escenarios-reales)
10. [Combinación con otras herramientas](#combinación-con-otras-herramientas)
11. [Uno-liners imprescindibles](#uno-liners-imprescindibles)

---

## ¿Qué es wc?

**wc** (word count) cuenta líneas, palabras, caracteres y bytes en archivos o desde la entrada estándar. Es la herramienta fundamental para medir tamaño de archivos de texto en términos de contenido, no de disco.

---

## Sintaxis básica

```bash
wc [opciones] [archivo...]
```

```bash
# Contar todo (líneas, palabras, bytes)
wc archivo.txt

# Solo líneas
wc -l archivo.txt

# Múltiples archivos (total al final)
wc archivo1.txt archivo2.txt
```

### Salida por defecto (sin opciones)

```bash
$ wc archivo.txt
  10   50  300 archivo.txt
```

| Columna | Significado |
|---------|-------------|
| `10` | Número de líneas |
| `50` | Número de palabras |
| `300` | Número de bytes |

---

## Contar líneas (-l)

`-l` (lines) cuenta el número de líneas. Es la opción más usada. Una línea termina con un carácter `\n` (nueva línea).

```bash
# Líneas en un archivo
wc -l archivo.txt

# Líneas en múltiples archivos
wc -l *.txt

# Contar archivos que cumplan una condición (con grep)
grep -l "error" *.log | wc -l
```

> **Nota**: `wc -l` cuenta el número de saltos de línea. Si la última línea no tiene salto de línea, no se cuenta. Un archivo vacío tiene 0 líneas.

---

## Contar palabras (-w)

`-w` (words) cuenta el número de palabras. Una palabra es cualquier secuencia de caracteres delimitada por espacios, tabs o saltos de línea.

```bash
# Palabras en un archivo
wc -w archivo.txt

# Palabras en todos los .py
wc -w *.py | tail -1
```

### Qué cuenta como "palabra"

wc considera palabra cualquier conjunto de caracteres separado por espacios en blanco:

```bash
# Esto tiene 5 palabras: "hola", "mundo", "123", "#$%", "test"
echo "hola mundo 123 #$% test" | wc -w
# Resultado: 5
```

---

## Contar caracteres (-m) vs bytes (-c)

### -c (bytes)

Cuenta el número de **bytes** del archivo (tamaño real en disco sin metadatos).

```bash
# Bytes del archivo
wc -c archivo.txt

# Equivalente a: stat --format=%s archivo.txt
```

### -m (characters)

Cuenta el número de **caracteres**. Diferente de `-c` en archivos con codificación multibyte (UTF-8).

```bash
# Caracteres (respeta UTF-8)
wc -m archivo.txt

# Diferencia en caracteres acentuados o emojis
echo "ñandú" | wc -c    # 6 bytes (UTF-8)
echo "ñandú" | wc -m    # 5 caracteres
echo "😀" | wc -c       # 4 bytes
echo "😀" | wc -m       # 1 carácter
```

> **Diferencia clave**: `-c` cuenta bytes (tamaño en almacenamiento), `-m` cuenta caracteres (lo que ve el usuario). En ASCII son iguales. En UTF-8 difieren para caracteres acentuados, emojis, caracteres asiáticos, etc.

---

## Contar todo (sin opciones)

Sin opciones, wc imprime: **líneas, palabras, bytes**.

```bash
# Equivalente a: wc -l -w -c
wc archivo.txt

# Formato: líneas palabras bytes nombre
```

---

## Contar desde entrada estándar (stdin)

```bash
# Contar líneas de la salida de un comando
grep -r "error" /var/log/ | wc -l

# Contar palabras en una cadena
echo "hola mundo" | wc -w

# Contar caracteres de entrada del usuario
read -p "Escribe algo: "; echo "$REPLY" | wc -m
```

---

## Contar la línea más larga (-L)

`-L` (max line length) muestra la longitud en caracteres de la **línea más larga** del archivo.

```bash
# Longitud de la línea más larga
wc -L archivo.txt

# Saber qué línea es la más larga (con awk)
awk 'length > max { max = length; linea = NR; texto = $0 } END { print linea, max, texto }' archivo.txt

# Verificar que las líneas no excedan 80 caracteres
[ $(wc -L < archivo.txt) -le 80 ] && echo "OK" || echo "Línea demasiado larga"
```

> **Nota**: `wc -L` con archivos UTF-8 cuenta caracteres (no bytes), y no necesariamente coincide con el ancho visual si hay tabs.

---

## Escenarios reales

### 1. Medir tamaño de proyectos

```bash
# Líneas de código en proyecto Python
find . -name "*.py" -exec wc -l {} + | tail -1

# Líneas totales excluyendo vacías y comentarios
find . -name "*.py" -exec cat {} + | grep -v '^\s*$\|^\s*#' | wc -l

# Archivos en un directorio
ls | wc -l

# Archivos recursivamente (sin directorios)
find . -type f | wc -l
```

### 2. Análisis de logs

```bash
# Cuántos errores hay
grep -c "ERROR" app.log

# Cuántas IPs únicas
cut -d' ' -f1 access.log | sort -u | wc -l

# Peticiones totales
wc -l < access.log

# Líneas por hora (últimas 24h)
grep "2024-01-15" app.log | wc -l

# Tamaño de log en bytes
wc -c < access.log
du -h access.log  # para humanos
```

### 3. Monitoreo de sistema

```bash
# Usuarios conectados
who | wc -l

# Procesos de un usuario
ps -u carludev | wc -l

# Puertos abiertos
ss -tuna | wc -l

# Paquetes instalados
dpkg -l | wc -l

# Tareas cron activas
crontab -l | wc -l
```

### 4. Validación de datos

```bash
# Verificar que un CSV tiene el mismo número de líneas que otro
[ $(wc -l < archivo1.csv) -eq $(wc -l < archivo2.csv) ] && echo "Mismas líneas"

# Verificar que todas las líneas tienen el mismo número de campos
awk '{print NF}' archivo.txt | sort -u
# Si solo sale un número, todas las líneas tienen la misma cantidad de campos

# Contar registros vs cabeceras
total=$(wc -l < datos.csv)
datos=$((total - 1))  # asumiendo cabecera
echo "$datos registros"
```

### 5. Productividad

```bash
# Contar commits en git
git log --oneline | wc -l

# Palabras escritas en documentación
wc -w docs/*.md

# Caracteres en un mensaje
echo -n "$mensaje" | wc -c

# Líneas modificadas en un diff
git diff --stat | tail -1
```

---

## Combinación con otras herramientas

### wc + find

```bash
# Contar archivos por tipo
find . -type f | wc -l
find . -type d | wc -l
find . -type l | wc -l

# Contar archivos por extensión
find . -name "*.py" | wc -l
find . -name "*.js" | wc -l

# Contar líneas de código en un proyecto
find . -name "*.py" -exec cat {} + | wc -l
```

### wc + grep

```bash
# g -c cuenta coincidencias internamente (más eficiente)
grep -c "error" app.log          # mejor que grep "error" | wc -l

# grep -c: cuenta líneas con coincidencias
# grep -o | wc -l: cuenta ocurrencias totales (puede haber varias por línea)
grep -o "error" app.log | wc -l  # cuenta cada ocurrencia

# Archivos que contienen un patrón
grep -rl "TODO" src/ | wc -l
```

### wc + xargs

```bash
# Total de líneas en archivos específicos
find . -name "*.py" | xargs wc -l

# Tamaño total de archivos en bytes
find . -name "*.log" | xargs wc -c

# Suma de archivos grandes (find ya ordena)
find . -name "*.py" -size +10k | xargs wc -l
```

### wc + sort

```bash
# Archivos por número de líneas (top 10)
wc -l *.py | sort -rn | head -10

# Archivos por tamaño (bytes)
wc -c *.log | sort -rn
```

---

## Tips y trucos

### wc sin nombre de archivo

Usando redirección `<` o pipe `|`, wc omite el nombre del archivo en la salida:

```bash
wc -l < archivo.txt     # solo el número
cat archivo.txt | wc -l # solo el número
wc -l archivo.txt       # número + nombre
```

### Contar archivos sin wc (alternativas)

```bash
# find ya puede contar con printf
find . -type f | wc -l         # común
find . -type f -printf '.' | wc -c  # más rápido en árboles grandes

# bash glob con dotglob
shopt -s dotglob
files=(*)
echo "${#files[@]}"
```

### Contar caracteres de una variable

```bash
mensaje="hola mundo"
echo -n "$mensaje" | wc -c    # con echo -n (sin salto de línea)

# En bash puro (más rápido)
echo "${#mensaje}"             # longitud de string en bash
```

---

## Uno-liners imprescindibles

```bash
# Líneas en un archivo
wc -l archivo.txt

# Palabras en un archivo
wc -w archivo.txt

# Caracteres en un archivo
wc -m archivo.txt

# Bytes en un archivo
wc -c archivo.txt

# Línea más larga
wc -L archivo.txt

# Todo (líneas, palabras, bytes)
wc archivo.txt

# Líneas de todos los .py en este directorio
wc -l *.py

# Total de líneas en proyecto
find . -type f -exec cat {} + | wc -l

# Número de archivos
find . -type f | wc -l

# Número de directorios
find . -type d | wc -l

# Cuántos errores en log
grep -c "ERROR" app.log

# Cuántas IPs únicas
cut -d' ' -f1 access.log | sort -u | wc -l

# Cuántos usuarios conectados
who | wc -l

# Cuántos procesos de apache
ps aux | grep apache | grep -v grep | wc -l

# Tamaño de archivo (bytes sin prefijo)
wc -c < archivo.bin

# Verificar que archivo no está vacío
[ $(wc -c < archivo.txt) -gt 0 ] && echo "no vacío"

# Contar palabras en una variable
echo "$var" | wc -w

# Total de líneas en archivos .log del sistema
find /var/log -name "*.log" -exec wc -l {} + | tail -1

# Comparar líneas entre dos archivos
diff <(wc -l < a.txt) <(wc -l < b.txt)
```
