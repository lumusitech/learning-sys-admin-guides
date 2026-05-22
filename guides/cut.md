# cut — Guía completa

**Nivel:** 🟢 Básico
**Archivos de práctica:** `labs/datos.txt`
**Ver escenarios relacionados:** [`networking/02-web-traffic`](../scenarios/networking/02-analyze-web-traffic-patterns.md)

## ⚡ Quick command

`cut -d: -f1,3 /etc/passwd`

## ⚡ Quick run

```bash
cut -d: -f1,3 /etc/passwd | head -5
```

---

## Índice
1. [¿Qué es cut?](#qué-es-cut)
2. [Sintaxis básica](#sintaxis-básica)
3. [Selección por caracteres (-c)](#selección-por-caracteres--c)
4. [Selección por campos (-f, -d)](#selección-por-campos--f--d)
5. [Selección por bytes (-b)](#selección-por-bytes--b)
6. [Opción de complemento (--complement)](#opción-de-complemento---complement)
7. [Opción de delimitador de salida (--output-delimiter)](#opción-de-delimitador-de-salida---output-delimiter)
8. [Escenarios reales](#escenarios-reales)
9. [Combinación con otras herramientas](#combinación-con-otras-herramientas)
10. [Cut vs awk vs sed](#cut-vs-awk-vs-sed)
11. [Uno-liners imprescindibles](#uno-liners-imprescindibles)

---

## ¿Qué es cut?

**cut** extrae secciones de cada línea de un archivo. Puede seleccionar por:

- **Caracteres** (`-c`): columnas fijas (posición 1, 2, 3...)
- **Campos** (`-f`): columnas delimitadas por un separador (campos 1, 3, 5...)
- **Bytes** (`-b`): similar a caracteres pero trabaja a nivel de bytes

cut es la herramienta más simple para extraer columnas. Para algo más complejo (condiciones, transformaciones, reordenar), usa `awk`.

---

## Sintaxis básica

```bash
cut [opciones] archivo
```

```bash
# Primeros 5 caracteres de cada línea
cut -c1-5 archivo.txt

# Tercer campo delimitado por espacios (tab por defecto)
cut -d' ' -f3 archivo.txt
```

---

## Selección por caracteres (-c)

`-c` selecciona por posición de carácter (1-indexed).

### Rangos

| Sintaxis | Significado |
|----------|-------------|
| `-c1` | Carácter en posición 1 |
| `-c1-5` | Caracteres de la posición 1 a la 5 |
| `-c-5` | Desde el inicio hasta la posición 5 |
| `-c5-` | Desde la posición 5 hasta el final |
| `-c1,3,5` | Posiciones 1, 3 y 5 |
| `-c1-3,7-9` | Rangos combinados |
| `-c1-3,7-` | Rango fijo + hasta el final |

```bash
# Primeros 80 caracteres (útil para logs de líneas largas)
cut -c1-80 archivo.log

# Sin límite superior: desde el carácter 10 hasta el final
cut -c10- archivo.txt

# Solo caracteres 1, 3, 5
cut -c1,3,5 archivo.txt

# Primeros 10 caracteres de cada línea (como head -c por línea)
cut -c-10 archivo.txt
```

### Ejemplo con columnas de ancho fijo

```
ID    NOMBRE    EDAD
001   Carlos    30
002   Ana       25
```

```bash
# Extraer nombre (posiciones 6-15)
cut -c6-15 archivo.txt

# Extraer ID (posiciones 1-4)
cut -c1-4 archivo.txt
```

---

## Selección por campos (-f, -d)

### -f (fields)

Selecciona campos. Usa el mismo formato de rangos que `-c`.

```bash
# Primer campo
cut -f1 archivo.txt

# Campos 1, 3 y 5
cut -f1,3,5 archivo.txt

# Campos 1 a 4
cut -f1-4 archivo.txt

# Todos los campos excepto el 1
cut -f2- archivo.txt
```

### -d (delimiter)

Especifica el delimitador de campos. Por defecto cut usa **TAB** como delimitador (`-d$'\t'`), NO espacios.

```bash
# Delimitador: dos puntos
cut -d: -f1,3 /etc/passwd

# Delimitador: coma (CSV)
cut -d, -f2,4 datos.csv

# Delimitador: espacio
cut -d' ' -f1 access.log

# Delimitador: varios (cut solo acepta UN carácter como delimitador)
```

> **IMPORTANTE**: cut solo acepta un **único carácter** como delimitador. Para separadores múltiples (ej: varios espacios), usa `awk` o preprocesa con `tr -s` para comprimir espacios.

### Limitación importante de cut con espacios

cut **no** maneja múltiples espacios consecutivos como separador único. Con `-d' '`, trata cada espacio como delimitador individual:

```bash
# NO FUNCIONA como esperas:
# "campo1    campo2    campo3" con -d' '
cut -d' ' -f2 archivo.txt  # Devuelve campo vacío

# Solución: comprimir espacios primero con tr
tr -s ' ' < archivo.txt | cut -d' ' -f2

# O usar awk (recomendado)
awk '{ print $2 }' archivo.txt
```

### -s (solo líneas con delimitador)

Oculta líneas que no contienen el delimitador.

```bash
# Ignorar líneas sin delimitador
cut -d: -f1 -s /etc/passwd

# Sin -s: las líneas sin : se imprimen completas
cut -d: -f1 /etc/passwd
```

---

## Selección por bytes (-b)

`-b` selecciona por bytes. Funciona igual que `-c` pero opera a nivel de bytes. Es importante en archivos multibyte (UTF-8) donde un carácter puede ocupar varios bytes.

```bash
# Primer byte de cada línea
cut -b1 archivo.txt

# En texto ASCII, -c y -b son equivalentes
# En UTF-8, -c respeta caracteres, -b los rompe
```

---

## Opción de complemento (--complement)

Invierte la selección: muestra todo **excepto** lo especificado.

```bash
# Todas las columnas excepto la 1
cut --complement -f1 archivo.txt
# Equivale a: cut -f2- archivo.txt

# Todos los campos excepto 3-5
cut --complement -f3-5 archivo.csv

# Con caracteres: todo excepto los primeros 10
cut --complement -c-10 archivo.txt
```

---

## Opción de delimitador de salida (--output-delimiter)

Controla qué carácter se usa entre los campos seleccionados en la salida. Por defecto usa el delimitador de entrada.

```bash
# Campos 1 y 3 de /etc/passwd, separados por flecha
cut -d: -f1,3 --output-delimiter=" -> " /etc/passwd

# Convertir CSV a TSV
cut -d, -f1,2,3 --output-delimiter=$'\t' datos.csv

# Reemplazar TAB por espacios
cut -f1,2 --output-delimiter=' ' archivo.txt
```

---

## Escenarios reales

### 1. Extraer IPs de access.log

```bash
# Primer campo (IP) separado por espacio
cut -d' ' -f1 access.log

# IPs únicas
cut -d' ' -f1 access.log | sort -u

# Top 10 IPs
cut -d' ' -f1 access.log | sort | uniq -c | sort -rn | head -10
```

### 2. Procesar /etc/passwd

```bash
# Usuarios y sus shells
cut -d: -f1,7 /etc/passwd

# Solo nombres de usuario
cut -d: -f1 /etc/passwd

# UIDs (tercer campo)
cut -d: -f3 /etc/passwd | sort -n

# Directorios home
cut -d: -f6 /etc/passwd
```

### 3. Analizar logs con formato fijo

```bash
# Timestamp está en posiciones fijas (ej: [10/Oct/2023:13:55:36])
cut -c2-21 access.log | head

# Códigos de estado HTTP (ej: posiciones 60-62)
cut -c60-62 access.log | sort | uniq -c | sort -rn
```

### 4. Procesar salida de comandos

```bash
# PID y comando de procesos
ps aux | tr -s ' ' | cut -d' ' -f2,11

# Puertos locales (de ss)
ss -tuna | tr -s ' ' | cut -d' ' -f4

# Tamaño y nombre de archivos
ls -l | tr -s ' ' | cut -d' ' -f5,9
```

---

## Combinación con otras herramientas

### cut + sort + uniq

```bash
# Extraer campo, contar, ordenar
cut -d' ' -f1 access.log | sort | uniq -c | sort -rn
```

### cut + grep

```bash
# grep filtra líneas, cut extrae campo
grep "ERROR" app.log | cut -d' ' -f1-3

# cut extrae campo, grep filtra
cut -d: -f1 /etc/passwd | grep "^a"
```

### cut + awk

```bash
# cut para columnas de ancho fijo, awk para procesar
cut -c1-80 archivo.log | awk '{ print $1, $NF }'

# awk extrae campo, cut toma caracteres
awk '{ print $4 }' app.log | cut -c2-12
```

### cut + tr (para múltiples espacios)

```bash
# tr comprime espacios, cut selecciona campo
tr -s ' ' < archivo.txt | cut -d' ' -f2,5

# tr convierte separador, cut selecciona
tr ':' ' ' < /etc/passwd | cut -d' ' -f1,3
```

---

## Cut vs awk vs sed

| Situación | Herramienta | Por qué |
|-----------|-------------|---------|
| Columna por posición exacta (ancho fijo) | `cut -c` | Simple, directo |
| Campo delimitado por TAB | `cut -f` | Perfecto, es lo que hace por defecto |
| Campo delimitado por espacio simple | `cut -d' ' -fN` | Funciona bien |
| Campo con espacios múltiples | `awk '{ print $N }'` | awk normaliza espacios automáticamente |
| Reordenar campos | `awk '{ print $2, $1 }'` | cut no puede reordenar |
| Condiciones sobre líneas (solo si $2 > 100) | `awk` | cut no tiene lógica condicional |
| Campo delimitado por carácter simple | `cut -d -f` | Más rápido y simple que awk/sed |
| Transformar el valor de un campo | `awk` o `sed` | cut solo extrae, no transforma |

```bash
# Benchmark: cut vs awk para extraer simple
# cut es más rápido en extracciones simples
time cut -d: -f1 /etc/passwd > /dev/null
time awk -F: '{ print $1 }' /etc/passwd > /dev/null
```

---

## Uno-liners imprescindibles

```bash
# Primer campo (espacio como delimitador)
cut -d' ' -f1 archivo.txt

# Último campo (solo si número fijo de campos)
cut -d' ' -f5 archivo.txt

# Todos menos el primero
cut -d' ' -f2- archivo.txt

# Campos 1, 3 y 5
cut -d, -f1,3,5 archivo.csv

# Primeros 10 caracteres
cut -c-10 archivo.txt

# Últimos 10 caracteres
cut -c$(($(wc -c < archivo.txt) - 9))- archivo.txt  # complejo, mejor rev | cut

# Caracteres 5 a 10
cut -c5-10 archivo.txt

# Salida con separador personalizado
cut -d: -f1,3 --output-delimiter='|' /etc/passwd

# Sin líneas sin delimitador
cut -d: -f1 -s /etc/passwd

# Complemento (todo excepto campo 2)
cut --complement -f2 archivo.txt

# Extraer dominios de emails
cut -d@ -f2 emails.txt | sort | uniq -c | sort -rn

# IP y hora de access.log
cut -d' ' -f1,4 access.log | tr -d '['

# Bytes 1-80 de archivo binario como texto
cut -b1-80 archivo.bin

# Quitar primera columna de CSV
cut --complement -d, -f1 datos.csv
```
