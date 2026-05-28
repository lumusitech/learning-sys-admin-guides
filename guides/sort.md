# sort — Guía completa

**Nivel:** 🟢 Básico
**Archivos de práctica:** `labs/datos.txt`
**Ver escenarios relacionados:** [`networking/01-detect-ssh-brute-force`](../scenarios/networking/01-detect-ssh-brute-force.md)

## ⚡ Quick command

`sort -k3 -rn labs/datos.txt`

## ⚡ Quick run

```bash
ps aux | sort -k3 -rn | head -5
```

---

## Índice

1. [¿Qué es sort?](#qué-es-sort)
2. [Sintaxis básica](#sintaxis-básica)
3. [Orden numérico (-n)](#orden-numérico--n)
4. [Orden inverso (-r)](#orden-inverso--r)
5. [Orden por campos (-k)](#orden-por-campos--k)
6. [Orden humano (-h)](#orden-humano--h)
7. [Manejo de mayúsculas (-f, -l)](#manejo-de-mayúsculas--f--l)
8. [Estabilidad y merge](#estabilidad-y-merge)
9. [Separador de campos (-t)](#separador-de-campos--t)
10. [Unique (-u)](#unique--u)
11. [Verificar orden (-c, -C)](#verificar-orden)
12. [Aleatorizar (-R)](#aleatorizar--r)
13. [Escenarios reales](#escenarios-reales)
14. [Combinación con otras herramientas](#combinación-con-otras-herramientas)
15. [Uno-liners imprescindibles](#uno-liners-imprescindibles)

---

## ¿Qué es sort?

**sort** ordena las líneas de archivos de texto. Por defecto ordena alfabéticamente por la línea completa. Es una herramienta esencial para análisis de datos, preparación de reportes, y como paso previo a `uniq`.

### Por defecto: orden alfabético

```bash
sort archivo.txt
```

Por defecto sort ordena:

- Alfabéticamente (según el locale)
- Por la línea completa
- Ascendente
- Case-sensitive (según locale)

---

## Orden numérico (-n)

`-n` (numeric sort) ordena por valor numérico real, no alfabético. La diferencia es clave:

```bash
# Alfabético: 1, 10, 100, 2, 20, 3...
echo -e "2\n10\n1\n20\n3" | sort
# Resultado: 1, 10, 2, 20, 3

# Numérico: 1, 2, 3, 10, 20
echo -e "2\n10\n1\n20\n3" | sort -n
# Resultado: 1, 2, 3, 10, 20
```

> **Explicación**: sin `-n`, sort compara strings: "10" < "2" porque '1' < '2'. Con `-n`, convierte a número antes de comparar.

### -g (general numeric sort)

Ordena también números en notación científica, flotantes, etc. Es más lento que `-n`.

```bash
# Números en notación científica
echo -e "1e2\n5e-1\n3e0" | sort -g
# Resultado: 5e-1 (0.5), 3e0 (3), 1e2 (100)
```

---

## Orden inverso (-r)

Invierte el orden (descendente).

```bash
# Descendente alfabético
sort -r archivo.txt

# Descendente numérico
sort -rn archivo.txt

# Top 10: ordenar por frecuencia descendente
sort -rn output.txt | head -10
```

---

## Orden por campos (-k)

`-k` especifica qué campo(s) usar para ordenar. El formato es `-k posicion_inicial[,posicion_final]`.

### Sintaxis básica

```bash
# Ordenar por segundo campo (alfabético)
sort -k2 archivo.txt

# Ordenar por segundo campo (numérico)
sort -k2 -n archivo.txt

# Ordenar por campo 2 numérico, luego campo 1 alfabético
sort -k2 -n -k1 archivo.txt
```

### Rangos de campos

```bash
# Ordenar por campos 2 a 4
sort -k2,4 archivo.txt

# Ordenar por campo 2, luego campo 1 (como ORDER BY SQL)
sort -k2,2 -k1,1 archivo.txt

# Ordenar por campo 2 numérico descendente, luego campo 1 ascendente
sort -k2,2 -rn -k1,1 archivo.txt
```

### Ordenar por subcampos dentro de un campo

```bash
# Archivo: "John   Smith" — ordenar por apellido (sin delimitar)
sort -k2 archivo.txt

# Archivo con timestamp: "2024-01-15 14:30:00 mensaje"
# Ordenar por hora (campo 2, subcampo 1 con separador :)
sort -t' ' -k2.1,2.2 -n archivo.log
```

> **Explicación de `k2.1,2.2`**: campo 2, desde el subcarácter 1 hasta el subcarácter 2 del campo.

### -s (stable sort)

Mantiene el orden original entre líneas con la misma clave de ordenación.

```bash
# Primero ordenar por campo 2, luego estabilizar
sort -k2,2 -s archivo.txt
```

---

## Orden humano (-h)

Ordena tamaños con sufijos humanos (K, M, G, T, P).

```bash
# Salida de du -h: ordenada por tamaño
du -h | sort -h

# Al revés: más grande primero
du -h | sort -rh

# ls -lh ordenado por tamaño
ls -lh | sort -h -k5
```

> **Explicación**: `-h` entiende que "1K" < "1M" < "1G". Sin `-h`, "1G" < "1K" (porque 'G' > 'K' alfabéticamente).

---

## Manejo de mayúsculas (-f, -l)

### -f (fold case)

Ignora mayúsculas/minúsculas.

```bash
# Sin -f: A, B, Z, a, b, z (en ASCII, mayúsculas van antes)
echo -e "z\nA\na\nZ\nB\nb" | sort

# Con -f: a, A, b, B, z, Z (trata igual mayúsculas y minúsculas)
echo -e "z\nA\na\nZ\nB\nb" | sort -f
```

### -l (locale)

Especifica el locale para el ordenamiento. Afecta a cómo se ordenan caracteres acentuados, ñ, etc.

```bash
# Orden español
LC_ALL=es_ES.UTF-8 sort archivo.txt

# Orden C (ASCII puro, más rápido)
LC_ALL=C sort archivo.txt
```

> **`LC_ALL=C`**: sort usando orden ASCII, no el del locale. Ignora acentos, ñ, etc. Es más rápido.

---

## Estabilidad y merge

### -m (merge)

Fusiona archivos ya ordenados sin reordenarlos. Es mucho más rápido que ordenar desde cero.

```bash
sort -m archivo1_ordenado.txt archivo2_ordenado.txt
```

### -s (stable)

Mantiene el orden original entre registros con clave igual. Útil para ordenaciones sucesivas.

```bash
# Ordenar por apellido manteniendo orden relativo original
sort -k2,2 -s archivo.txt
```

---

## Separador de campos (-t)

Especifica el delimitador de campos. Por defecto sort separa por **transición de espacio en blanco a no espacio** (como awk).

```bash
# /etc/passwd: separador :
sort -t: -k3 -n /etc/passwd

# CSV: separador ,
sort -t, -k2 -n datos.csv

# Espacio como separador explícito
sort -t' ' -k2 archivo.txt
```

> **Diferencia con cut**: sort con `-t' '` trata espacios simples como delimitadores. cut con `-d' '` también, pero sort maneja múltiples espacios?

En realidad sort **normaliza espacios en blanco** por defecto. Si usas `-t' '`, sort solo reconoce un espacio como delimitador. Si no usas `-t`, sort reconoce cualquier secuencia de espacios/tabs como separador.

---

## Unique (-u)

Salida con líneas únicas (elimina duplicados adyacentes después de ordenar).

```bash
# Líneas únicas ordenadas (como sort | uniq)
sort -u archivo.txt

# IPs únicas ordenadas
sort -u -t' ' -k1 access.log

# Campos único por clave específica
sort -u -k2,2 archivo.txt  # solo mantiene primera línea por cada valor en campo 2
```

> **Diferencia entre `sort -u` y `sort | uniq`**: son equivalentes cuando sort procesa un solo archivo. `sort -u` puede ser más eficiente porque elimina duplicados durante el ordenamiento.

---

## Verificar orden (-c, -C)

### -c (check, verbose)

Verifica si el archivo está ordenado. Muestra la primera línea desordenada.

```bash
# Salir con código 0 si está ordenado, 1 si no
sort -c archivo.txt
# Si no lo está: "sort: archivo.txt:2: disorder: línea 2"

sort -c -k2 archivo.txt
```

### -C (check, silencioso)

Como `-c` pero sin mensaje de error. Solo código de salida.

```bash
if sort -C archivo.txt; then
  echo "Está ordenado"
else
  echo "NO está ordenado"
fi
```

---

## Aleatorizar (-R)

### -R (random sort)

Ordena aleatoriamente (shuffle-like). No es realmente "ordenar", sino mezclar.

```bash
# Mezclar líneas aleatoriamente
sort -R archivo.txt

# Seleccionar 5 líneas aleatorias de un archivo grande
sort -R archivo.txt | head -5
```

> **Nota**: `-R` usa un hash aleatorio. Con `--random-source=archivo` puedes hacer reproducible la mezcla.

---

## Opciones adicionales

| Opción | Descripción |
|--------|-------------|
| `-b` | Ignora espacios al inicio de cada campo |
| `-d` | Ordena solo por letras, dígitos y espacios (ignora otros caracteres) |
| `-i` | Ignora caracteres no imprimibles |
| `-M` | Ordena por nombre de mes (Ene, Feb, Mar...) |
| `-V` | Ordena por número de versión (natural version sort) |
| `--parallel=N` | Usa N hilos para ordenar (más rápido en archivos grandes) |
| `-S N%` | Usa hasta N% de RAM para el buffer de ordenamiento |
| `-T dir` | Directorio para archivos temporales |
| `--batch-size=N` | Máximo número de archivos a fusionar a la vez |

### -M (month sort)

```bash
# Ordenar por mes
echo -e "Ene\nMar\nFeb\nAbr" | sort -M
# Resultado: Ene, Feb, Mar, Abr
```

### -V (version sort)

Ordena números de versión correctamente (1.2, 1.10, 2.0, etc.).

```bash
# Sin -V: 1.10, 1.2, 2.0 (alfabético)
echo -e "2.0\n1.10\n1.2" | sort

# Con -V: 1.2, 1.10, 2.0 (versión correcta)
echo -e "2.0\n1.10\n1.2" | sort -V

# Útil para ordenar tags, paquetes, etc.
sort -V versiones.txt
```

---

## Escenarios reales

### 1. Análisis de logs

```bash
# Ordenar access.log por IP (campo 1)
sort -k1 access.log

# Ordenar por timestamp (campo 4) — fechas en formato [10/Oct/2023...
sort -k4 access.log

# Mayor consumo de ancho de banda (bytes, último campo)
awk '{print $NF, $0}' access.log | sort -rn | head -10 | cut -d' ' -f2-

# Peticiones lentas (tiempo de respuesta, si el log lo tiene)
sort -k10 -rn access.log | head -10
```

### 2. Análisis de procesos

```bash
# Procesos ordenados por uso de CPU
ps aux | sort -k3 -rn

# Procesos ordenados por uso de memoria
ps aux | sort -k4 -rn

# Procesos ordenados por PID
ps aux | sort -k2 -n
```

### 3. Análisis de tamaño de archivos

```bash
# Directorios ordenados por tamaño (humano)
du -h | sort -h

# Archivos ordenados por tamaño (ascendente)
find . -type f -exec ls -l {} \; | sort -k5 -n

# Archivos ordenados por tamaño (descendente, top 20)
find . -type f -exec ls -l {} \; | sort -k5 -rn | head -20

# Archivos por fecha de modificación (más recientes primero)
ls -lt | head -20
```

### 4. Procesamiento de datos

```bash
# Top 10 IPs por peticiones
cut -d' ' -f1 access.log | sort | uniq -c | sort -rn | head -10

# Top 10 páginas por visitas
cut -d' ' -f7 access.log | sort | uniq -c | sort -rn | head -10

# Transferencia por IP
awk '{ bytes[$1] += $10 } END { for (ip in bytes) print bytes[ip], ip }' access.log | sort -rn | head -10
```

---

## Combinación con otras herramientas

### sort + uniq (tándem clásico)

```bash
# Contar ocurrencias
sort archivo.txt | uniq -c | sort -rn

# IPs únicas de log
cut -d' ' -f1 access.log | sort -u

# Mostrar solo duplicados
sort archivo.txt | uniq -d

# Mostrar solo no duplicados
sort archivo.txt | uniq -u
```

### sort + head/tail

```bash
# Top 10 registros
sort -k2 -rn archivo.txt | head -10

# Últimos 10 registros (menores valores)
sort -k2 -n archivo.txt | tail -10

# Rango medio: registros 10-20
sort -k2 -n archivo.txt | sed -n '10,20p'
```

### sort + awk

```bash
# awk calcula, sort ordena
awk '{ ips[$1]++ } END { for (i in ips) print ips[i], i }' access.log | sort -rn

# awk filtra, sort ordena
awk '$9 == 404 { print $1, $7 }' access.log | sort -k1
```

### sort + find

```bash
# Archivos ordenados por tamaño (find + sort)
find . -type f -printf "%s %p\n" | sort -rn | head -10

# Archivos ordenados por fecha
find . -type f -printf "%T@ %p\n" | sort -rn
```

---

## Uno-liners imprescindibles

```bash
# Ordenar archivo numéricamente por primera columna
sort -n archivo.txt

# Ordenar por segunda columna numérica descendente
sort -k2 -rn archivo.txt

# Ordenar por múltiples columnas
sort -k1,1 -k3,3n archivo.txt

# Ordenar por mes
sort -M archivo.txt

# Ordenar por versión
sort -V archivo.txt

# Ordenar ignorando mayúsculas
sort -f archivo.txt

# Ordenar único (eliminar duplicados)
sort -u archivo.txt

# Verificar si está ordenado
sort -c archivo.txt

# Mezclar aleatoriamente
sort -R archivo.txt

# Ordenar por campo con delimitador personalizado
sort -t: -k3 -n /etc/passwd

# Fusionar archivos ordenados
sort -m archivo1.txt archivo2.txt

# Ordenar humano (tamaños con sufijo)
du -sh * | sort -h

# Ordenar con buffer grande (más rápido en archivos grandes)
sort -S 50% archivo_grande.txt

# Ordenar paralelo
sort --parallel=4 archivo_grande.txt

# Ordenar por campo numérico descendente, luego campo texto ascendente
sort -k1,1rn -k2,2 archivo.txt

# Ordenar por el último campo usando awk
awk '{ print $NF, $0 }' archivo.txt | sort -n | cut -d' ' -f2-

# Ordenar IPs correctamente (IPv4)
sort -t. -k1,1n -k2,2n -k3,3n -k4,4n ips.txt
```
