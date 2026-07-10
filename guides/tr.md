# tr — Guía completa de transformación de caracteres

**Nivel:** 🟢 Básico
**Archivos de práctica:** Descripción general (funciona en cualquier sistema)
**Ver escenarios relacionados:** [`system/02-log-analysis`](../scenarios/system/02-log-analysis-and-error-tracking.md)

---

## ⚡ Quick command

`echo "HOLA MUNDO" | tr 'A-Z' 'a-z'`

> ⚠️ Disponible en Alpine, BusyBox y cualquier Unix. Portable por definición (POSIX).

---

## ⚡ Quick run

```bash
echo "UPPERCASE" | tr '[:upper:]' '[:lower:]'
```

---

## 📑 Índice

1. [¿Qué es tr?](#qué-es-tr)
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

## 🧠 ¿Qué es tr?

tr (translate) transforma, elimina o comprime caracteres de la entrada estándar y escribe el resultado en la salida estándar. No lee archivos directamente — siempre trabaja con stdin/stdout.

Es ideal para:

- Convertir mayúsculas a minúsculas (y viceversa)
- Eliminar caracteres no deseados (carriage returns, espacios extra)
- Reemplazar un set de caracteres por otro
- Comprimir caracteres repetidos (squeeze)
- Limpiar output de comandos para procesamiento

---

## 🧠 Modelo mental

Pensá en tr como un **filtro de café**. Le tirás texto sucio (con caracteres que no querés) y sale texto limpio. No modifica el archivo original, solo transforma lo que pasa por el filtro.

Es como `sed` pero para operaciones carácter-por-carácter, no por líneas. Para transformaciones simples de caracteres, tr es más rápido y más simple que sed.

---

## 📝 Sintaxis básica

```text
tr [opciones] SET1 [SET2]
```

| Uso | Comando |
|-----|---------|
| Reemplazar SET1 por SET2 | `tr 'abc' 'xyz'` |
| Eliminar caracteres de SET1 | `tr -d 'caracteres'` |
| Comprimir caracteres repetidos de SET1 | `tr -s 'caracteres'` |
| Complemento de SET1 (todo menos SET1) | `tr -c 'abc' 'xyz'` |

---

## 🔑 Salida clave

### Reemplazo simple

```bash
$ echo "abc" | tr 'a' 'x'
xbc
```

### Rango de caracteres

```bash
$ echo "HOLA" | tr 'A-Z' 'a-z'
hola
```

### Eliminar caracteres

```bash
$ echo "col1,col2,col3" | tr -d ','
col1col2col3
```

### Comprimir (squeeze)

```bash
$ echo "muchos     espacios" | tr -s ' '
muchos espacios
```

---

## 🎛️ Opciones principales

| Flag | Significado |
|------|-------------|
| `-d` | Delete: eliminar caracteres de SET1 |
| `-s` | Squeeze: comprimir repeticiones de SET1 |
| `-c` | Complement: operar sobre todo MENOS SET1 |
| `-t` | Truncate SET1 al largo de SET2 |

### Clases de caracteres POSIX

| Clase | Equivalente | Descripción |
|-------|-------------|-------------|
| `[:alnum:]` | `A-Za-z0-9` | Alfanuméricos |
| `[:alpha:]` | `A-Za-z` | Letras |
| `[:digit:]` | `0-9` | Dígitos |
| `[:lower:]` | `a-z` | Minúsculas |
| `[:upper:]` | `A-Z` | Mayúsculas |
| `[:space:]` | Tab, space, newline | Espacios |
| `[:punct:]` | `!@#$%...` | Puntuación |
| `[:print:]` | Caracteres imprimibles | Sin caracteres de control |
| `[:cntrl:]` | `\0-\37 \177` | Caracteres de control |

---

## 📋 Patrones de uso

### Minúsculas a mayúsculas

```bash
echo "hola mundo" | tr '[:lower:]' '[:upper:]'
```

### Eliminar carriage returns (^M de Windows)

```bash
tr -d '\r' < archivo_windows.txt > archivo_unix.txt
```

### Comprimir espacios múltiples

```bash
cat log.txt | tr -s ' ' > log_limpio.txt
```

### Eliminar todas las vocales

```bash
echo "Hola Mundo" | tr -d 'aeiouAEIOU'
```

### Reemplazar comas por tabs (CSV a TSV)

```bash
cat datos.csv | tr ',' '\t'
```

### Eliminar caracteres no imprimibles

```bash
cat archivo_sucio | tr -cd '[:print:]\n'
```

### Rot13 (cifrado simple)

```bash
echo "secreto" | tr 'A-Za-z' 'N-ZA-Mn-za-m'
```

### Conteo de frecuencia de letras

```bash
cat texto.txt | tr '[:upper:]' '[:lower:]' | tr -d '[:punct:][:space:]' | fold -w1 | sort | uniq -c | sort -rn
```

---

## 🔍 Uso en troubleshooting

### "Los logs tienen timestamps en formato raro (con comas)"

```bash
grep "ERROR" app.log | tr ',' ' ' | awk '{print $1, $2, $NF}'
```

### "El archivo viene de Windows y tiene ^M al final de cada línea"

```bash
tr -d '\r' < archivo_windows > archivo_linux
```

### "Muchos espacios entre columnas, awk no lo parsea bien"

```bash
cat datos.txt | tr -s ' ' | awk '{print $1, $3}'
```

### "Quiero ver solo los dígitos de teléfono en un archivo"

```bash
cat contacto.txt | tr -cd '[:digit:]\n'
```

---

## 🛠️ Combinación con otras herramientas

### tr + awk

```bash
cat log_sucio | tr -s ' ' | awk '{print $1, $3, $NF}'
```

### tr + sort + uniq

```bash
cat texto.txt | tr '[:upper:]' '[:lower:]' | tr -s '[:space:]' '\n' | sort | uniq -c | sort -rn | head -20
```

### tr + grep

```bash
cat /var/log/syslog | tr '[:upper:]' '[:lower:]' | grep "error"
```

### tr + sed

```bash
cat archivo | tr '\t' ',' | sed 's/,,/,/g'   # Tabs a CSV, limpiar doble coma
```

---

## 💡 Uno-liners imprescindibles

```bash
# A minúsculas
echo "TEXTO" | tr '[:upper:]' '[:lower:]'

# A mayúsculas
echo "texto" | tr '[:lower:]' '[:upper:]'

# Eliminar carriage return (Windows a Unix)
tr -d '\r' < entrada > salida

# Eliminar espacios múltiples
cat log.txt | tr -s ' '

# Comas a tabs
tr ',' '\t'

# Solo dígitos
tr -cd '[:digit:]'

# Solo letras y espacios
tr -cd '[:alpha:][:space:]'

# Eliminar línea en blanco múltiple
tr -s '\n'

# Rot13 (ofuscar texto)
tr 'A-Za-z' 'N-ZA-Mn-za-m'

# Primera letra de cada palabra a mayúscula
echo "hola mundo" | sed 's/.*/\L&/; s/[a-z]*/\u&/g'
```

---

## ⚠️ Errores comunes

| Error | Causa | Solución |
|-------|-------|----------|
| Esperar que tr lea archivos | tr solo procesa stdin | `tr 'a' 'b' < archivo` o `cat archivo \| tr 'a' 'b'` |
| Confundir rangos y clases | `'a-z'` depende del locale; `'[:lower:]'` es más portable | Usar clases POSIX |
| SET1 más largo que SET2 | tr repite el último carácter de SET2 para empatar | Especificar explícitamente |
| `-c` con newline | `tr -cd '[:print:]'` elimina `\n` | Agregar `\n` al set: `tr -cd '[:print:]\n'` |
| No funciona con Unicode/multibyte | tr opera byte a byte | Usar `sed` o `perl` para Unicode |

---

## ✅ Buenas prácticas

1. **Usar clases POSIX** (`[:lower:]`) en vez de rangos (`a-z`) para portabilidad entre locales
2. **Siempre recordar que tr no lee archivos** — usar `<` o pipe
3. **Combinar con `-s` para limpiar output** antes de pasarlo a awk/cut
4. **Para caracteres no-ASCII**, verificar el locale: `LC_ALL=C tr ...` para byte-level
5. **Preferir tr sobre sed** para transformaciones carácter-por-carácter: es más simple y más rápido
6. **Usar `-d` en vez de reemplazar por vacío** (`tr -d 'x'` no `tr 'x' ''`)

---

## 🔗 Referencias internas

- [`sed`](sed.md) — transformaciones línea por línea
- [`awk`](awk.md) — procesamiento por campos (post-tr)
- [`grep`](grep.md) — filtrado por patrón (pre-tr o post-tr)
- [`cut`](cut.md) — extracción por campos/delimitador
- [`sort`](sort.md), [`uniq`](uniq.md) — análisis de frecuencia
- [`scenario`](../scenarios/system/02-log-analysis-and-error-tracking.md) — limpieza de logs con tr
