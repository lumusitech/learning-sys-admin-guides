# uniq — Guía completa

**Nivel:** 🟢 Básico
**Archivos de práctica:** `labs/auth.log`
**Ver escenarios relacionados:** [`networking/01-detect-ssh-brute-force`](../scenarios/networking/01-detect-ssh-brute-force.md)

**Quick command:** `uniq -c labs/auth.log | sort -rn | head`

## ⚡ Quick run

```bash
cut -d' ' -f1 labs/nginx_access.log | sort | uniq -c | sort -rn | head -5
```

---

## Índice
1. [¿Qué es uniq?](#qué-es-uniq)
2. [Sintaxis básica](#sintaxis-básica)
3. [Requisito: entrada ordenada](#requisito-entrada-ordenada)
4. [Contar ocurrencias (-c)](#contar-ocurrencias--c)
5. [Duplicados y únicos (-d, -u)](#duplicados-y-únicos--d--u)
6. [Ignorar campos (-f)](#ignorar-campos--f)
7. [Ignorar caracteres (-s, -w)](#ignorar-caracteres--s--w)
8. [Ignorar mayúsculas (-i)](#ignorar-mayúsculas--i)
9. [Escenarios reales](#escenarios-reales)
10. [Combinación con otras herramientas](#combinación-con-otras-herramientas)
11. [Uno-liners imprescindibles](#uno-liners-imprescindibles)

---

## ¿Qué es uniq?

**uniq** detecta y filtra líneas duplicadas **adyacentes** en un archivo ordenado. Puede contar ocurrencias, mostrar solo duplicados, o mostrar solo líneas únicas.

### Limitación fundamental

uniq solo compara líneas **consecutivas**. Si los duplicados no están juntos, no los detecta. Por eso siempre se usa DESPUÉS de `sort`:

```bash
# MAL: no encuentra duplicados si no están juntos
uniq archivo.txt

# BIEN: ordenar primero
sort archivo.txt | uniq
```

---

## Sintaxis básica

```bash
uniq [opciones] [archivo_entrada [archivo_salida]]
```

```bash
# Eliminar líneas duplicadas adyacentes (imprime cada línea una vez)
uniq archivo.txt

# Con entrada ordenada (elimina todos los duplicados)
sort archivo.txt | uniq

# Guardar resultado en archivo
sort archivo.txt | uniq > resultado.txt

# Como filter: equivalencia con sort -u
sort -u archivo.txt
# sort -u es un shortcut para sort | uniq
```

---

## Contar ocurrencias (-c)

`-c` (count) antepone el número de ocurrencias a cada línea.

```bash
# Contar frecuencias
sort archivo.txt | uniq -c

# Ordenar por frecuencia descendente (el clásico)
sort archivo.txt | uniq -c | sort -rn

# Con formato personalizado (usando awk)
sort archivo.txt | uniq -c | awk '{ print $1, $2 }'
```

### Formato de salida

```bash
$ sort archivo.txt | uniq -c
  5 apple
  3 banana
  2 orange
```

El conteo se alinea a la derecha con espacios. Para limpiarlo:

```bash
# Normalizar espacios
sort archivo.txt | uniq -c | sed 's/^ *//'

# Reordenar: valor, luego conteo
sort archivo.txt | uniq -c | awk '{ print $2, $1 }'

# Formato CSV
sort archivo.txt | uniq -c | awk '{ print $2 "," $1 }'
```

> **Explicación**: `sed 's/^ *//'` elimina los espacios iniciales que uniq pone antes del número.

---

## Duplicados y únicos (-d, -u)

### -d (repeated)

Muestra solo las líneas que aparecen **más de una vez**.

```bash
# Líneas duplicadas (cada una una vez, no todas las ocurrencias)
sort archivo.txt | uniq -d

# Mostrar todas las ocurrencias de duplicados (no solo una)
sort archivo.txt | uniq -d | grep -F -f - archivo.txt
```

### -D (print all duplicates, GNU)

Muestra **todas** las líneas que pertenecen a grupos duplicados (no una por grupo como `-d`).

```bash
# Mostrar todas las ocurrencias de líneas que aparecen más de una vez
sort archivo.txt | uniq -D
```

### -u (unique)

Muestra solo las líneas que aparecen **exactamente una vez**.

```bash
# Líneas que solo aparecen una vez
sort archivo.txt | uniq -u
```

---

## Ignorar campos (-f)

`-f N` (skip fields) omite los primeros N campos (separados por espacios/tabs) al comparar.

```bash
# Ignorar el primer campo (ej: timestamp) y comparar el resto
sort archivo.txt | uniq -f1

# Ignorar los primeros 3 campos
sort archivo.txt | uniq -f3

# Útil para logs donde el timestamp cambia pero el mensaje se repite
sort -k2 app.log | uniq -f1 -c
```

> **Ejemplo**: con líneas como "2024-01-15 ERROR timeout", `uniq -f1` ignora la fecha y solo mira "ERROR timeout".

---

## Ignorar caracteres (-s, -w)

### -s N (skip chars)

Omite los primeros N caracteres de cada línea al comparar.

```bash
# Ignorar los primeros 10 caracteres (ej: timestamp fijo)
sort archivo.txt | uniq -s10

# Ignorar prefijo "ERROR: "
sort archivo.txt | uniq -s7
```

### -w N (check chars)

Compara solo los primeros N caracteres de cada línea.

```bash
# Comparar solo primeras 10 letras
uniq -w10 archivo.txt

# Agrupar por código postal (primeros 5 caracteres)
sort archivo.txt | uniq -w5 -c
```

---

## Ignorar mayúsculas (-i)

`-i` (ignore case) ignora diferencias entre mayúsculas y minúsculas.

```bash
# Tratar "ERROR", "error", "Error" como iguales
sort archivo.txt | uniq -i -c
```

---

## Escenarios reales

### 1. Análisis de logs

```bash
# Mensajes de error más frecuentes
grep ERROR app.log | sort | uniq -c | sort -rn | head -10

# IPs únicas que hicieron peticiones
cut -d' ' -f1 access.log | sort -u | wc -l

# Horas con más peticiones (campo [10/Oct/2023:13:55:36)
cut -d' ' -f4 access.log | cut -d: -f2 | sort | uniq -c | sort -rn

# Códigos de estado HTTP
cut -d' ' -f9 access.log | sort | uniq -c | sort -rn

# User agents únicos
cut -d'"' -f6 access.log | sort -u | head -20
```

### 2. Monitoreo de sistema

```bash
# Usuarios únicos ejecutando procesos
ps aux | awk '{print $1}' | sort -u

# Terminales únicos de login
who | awk '{print $2}' | sort -u

# Paquetes únicos instalados (versiones)
dpkg -l | awk '{print $2}' | sort -u | wc -l
```

### 3. Seguridad

```bash
# IPs únicas que fallaron login SSH
grep "Failed password" /var/log/auth.log | grep -oP 'from \K[0-9.]+' | sort -u

# IPs que atacaron más de 10 veces
grep "Failed password" /var/log/auth.log | grep -oP 'from \K[0-9.]+' | sort | uniq -c | sort -rn | awk '$1 > 10'

# Puertos únicos escaneados (desde logs de firewall)
grep "DPT=" /var/log/kern.log | grep -oP 'DPT=\K[0-9]+' | sort -u

# Combinaciones IP + User-Agent únicas
awk '{print $1, $NF}' access.log | sort -u
```

### 4. Procesamiento de datos

```bash
# Contar ocurrencias de palabras
tr ' ' '\n' < archivo.txt | sort | uniq -c | sort -rn

# Contar extensiones de archivo
find . -type f -printf "%f\n" | grep -oP '\.[^.]+$' | sort | uniq -c | sort -rn

# Contar emails por dominio
cut -d@ -f2 emails.txt | sort | uniq -c | sort -rn

# Eliminar líneas duplicadas preservando orden (sin sort)
awk '!visto[$0]++' archivo.txt
```

---

## Combinación con otras herramientas

### uniq + sort (tándem obligatorio)

```bash
# El uso más común: frecuencia de valores
cut -d' ' -f1 access.log | sort | uniq -c | sort -rn

# Duplicados en un archivo (con sort)
sort archivo.txt | uniq -d

# Líneas que aparecen exactamente una vez
sort archivo.txt | uniq -u
```

### uniq + grep/cut/awk

```bash
# grep filtra, cut extrae, sort ordena, uniq cuenta
grep "ERROR" app.log | cut -d' ' -f5 | sort | uniq -c | sort -rn

# awk procesa campos, sort ordena, uniq cuenta
awk '{print $1, $9}' access.log | sort | uniq -c | sort -rn
```

### uniq + head

```bash
# Top 10 valores más frecuentes
cut -d' ' -f1 access.log | sort | uniq -c | sort -rn | head -10

# Top 10 valores menos frecuentes
cut -d' ' -f1 access.log | sort | uniq -c | sort -n | head -10
```

---

## Alternativas a uniq en otros comandos

### sort -u (unique sort)

```bash
# Equivalente a sort | uniq
sort -u archivo.txt

# Más eficiente: elimina duplicados durante el ordenamiento
```

### awk '!visto[$0]++'

```bash
# Eliminar duplicados preservando el orden original (sin sort)
awk '!visto[$0]++' archivo.txt
```

### bash / zsh (arrays asociativos)

```bash
# En shell puro (archivos pequeños)
while IFS= read -r line; do
  [[ -z ${lines[$line]} ]] && echo "$line"
  lines[$line]=1
done < archivo.txt
```

---

## Uno-liners imprescindibles

```bash
# Eliminar líneas duplicadas (entrada debe estar ordenada)
sort archivo.txt | uniq

# Contar ocurrencias
sort archivo.txt | uniq -c

# Ordenar por frecuencia (más común primero)
sort archivo.txt | uniq -c | sort -rn

# Solo líneas duplicadas (una por grupo)
sort archivo.txt | uniq -d

# Solo líneas únicas (no repetidas)
sort archivo.txt | uniq -u

# Todas las líneas de grupos duplicados
sort archivo.txt | uniq -D

# Ignorar mayúsculas
sort archivo.txt | uniq -i -c

# Ignorar primer campo
sort -k2 archivo.txt | uniq -f1 -c

# Ignorar primeros 10 caracteres
sort archivo.txt | uniq -s10 -c

# Comparar solo primeros 5 caracteres
sort archivo.txt | uniq -w5 -c

# Contar palabras
tr ' ' '\n' < archivo.txt | sort | uniq -c | sort -rn

# Contar IPs
cut -d' ' -f1 access.log | sort | uniq -c | sort -rn | head -10

# Contar extensiones de archivo
find . -type f -printf "%f\n" | awk -F. 'NF>1 {print $NF}' | sort | uniq -c | sort -rn

# Eliminar duplicados sin sort (preserva orden)
awk '!visto[$0]++' archivo.txt

# Contar ocurrencias en columna específica
awk '{print $2}' archivo.txt | sort | uniq -c | sort -rn

# Mostrar solo líneas que aparecen N veces (ej: exactamente 3)
sort archivo.txt | uniq -c | awk '$1 == 3'
```
