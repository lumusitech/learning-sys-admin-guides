# du — Guía completa

**Nivel:** 🟢 Básico
**Archivos de práctica:** Sistema en vivo
**Ver escenarios relacionados:** [`system/06-disk-full-inodes`](../scenarios/system/06-disk-full-inodes.md)

---

## ⚡ Quick command

`du -sh /var/log`

---

## ⚡ Quick run

```bash
du -sh /var/* | sort -rh | head -10
```

---

## Índice

1. [¿Qué es du?](#qué-es-du)
2. [Sintaxis básica](#sintaxis-básica)
3. [Salida clave](#salida-clave)
4. [Opciones principales](#opciones-principales)
5. [Sumarizar con -s](#sumarizar-con--s)
6. [Discos y exclusión](#discos-y-exclusión)
7. [Patrones de uso](#patrones-de-uso)
8. [Uso en troubleshooting](#uso-en-troubleshooting)
9. [Combinación con otras herramientas](#combinación-con-otras-herramientas)
10. [Uno-liners imprescindibles](#uno-liners-imprescindibles)
11. [Errores comunes](#errores-comunes)
12. [Buenas prácticas](#buenas-prácticas)

---

## ¿Qué es du?

**du** (disk usage) estima el espacio usado por archivos y directorios. A diferencia de `df` (que mira el sistema de archivos completo), `du` recorre árboles de directorios y suma el tamaño de cada archivo.

Se usa para:

- identificar qué directorios consumen más espacio;
- encontrar archivos grandes antes de que llenen el disco;
- auditar crecimiento de logs, backups o temporales.

---

## Modelo mental

`du` es el **detective de espacio**. Mientras `df` dice "el disco /var está al 90%", `du` dice "/var/log pesa 40 GB, /var/lib pesa 30 GB, /var/www pesa 5 GB".

`du` recorre cada archivo y suma. Por eso en directorios con millones de archivos puede ser muy lento. Usar `-s` (sumarizar) para no bajar a subdirectorios si no hace falta.

---

## Sintaxis básica

```bash
du [opciones] [directorio]
```

```bash
du -sh /var        # Sumarizar tamaño total de /var
du -sh /var/*      # Cada subdirectorio de /var
du -ach /var/log/* # Con total acumulado
du --max-depth=2 /var  # Hasta 2 niveles de profundidad
```

---

## Salida clave

```text
4.0K    /var/log/btmp
12K     /var/log/dpkg.log
12K     /var/log/faillog
1.2M    /var/log/lastlog
1.5G    /var/log/nginx
45M     /var/log/mysql
```

Cada línea muestra el tamaño y la ruta. La primera columna es en KB por defecto, con `-h` se vuelve legible (K, M, G, T).

---

## Opciones principales

| Opción | Efecto |
|--------|--------|
| `-h` | Formato humano (K, M, G) |
| `-s` | Sumarizar (solo total, sin subdirectorios individuales) |
| `-a` | Mostrar también archivos, no solo directorios |
| `-c` | Mostrar total acumulado al final |
| `-d <N>` | Profundidad máxima (--max-depth) |
| `--exclude=<patrón>` | Excluir archivos/directorios |
| `-t <tamaño>` | Solo entradas mayores a un tamaño |
| `--time` | Mostrar fecha de última modificación |
| `-x` | No cruzar sistemas de archivos (stay within filesystem) |
| `-L` | Seguir enlaces simbólicos |

---

## Sumarizar con -s

`-s` es la opción más usada. Muestra el total sin listar subdirectorios internos:

```bash
# Tamaño de cada subdirectorio de primer nivel
du -sh /var/*

# Tamaño total de un directorio
du -sh /var/log
```

Sin `-s`, `du` muestra cada subdirectorio recursivamente, lo que puede ser muy verboso:

```bash
# Muestra todo, desde /var/log, /var/log/nginx, /var/log/nginx/access, ...
du -h /var/log
```

---

## Discos y exclusión

### No cruzar sistemas de archivos

Si un directorio tiene un mount point dentro, `du` lo atravesaría. La opción `-x` evita esto:

```bash
du -shx /       # Solo el sistema de archivos raíz, sin /proc, /sys, /dev
```

### Excluir directorios específicos

```bash
du -sh --exclude='*.log' /var        # Sin logs
du -sh --exclude='node_modules' /home # Sin node_modules
```

---

## Patrones de uso

### Top directorios por tamaño

```bash
du -sh /* | sort -rh | head -10
```

### Top directorios dentro de /var

```bash
du -sh /var/* | sort -rh | head -10
```

### Directorios con más de 1 GB

```bash
du -sh /* | sort -rh | awk '$1 ~ /G/'
```

### Profundidad controlada

```bash
du -h --max-depth=2 /var | sort -rh | head -20
```

### Tamaño total con acumulado

```bash
du -shc /var/log/* | sort -rh | head -15
```

---

## Uso en troubleshooting

### Encontrar qué llena el disco

```bash
# 1. Ver qué partición está llena
df -h

# 2. Primer nivel
du -sh /var/* | sort -rh | head -10

# 3. Segundo nivel (el directorio que más pesa)
du -sh /var/log/* | sort -rh | head -10

# 4. Archivos más grandes
find /var/log -type f -size +100M -exec ls -lh {} \; | sort -k5 -rh | head -10
```

### Directorios que más crecieron (comparado con ayer)

```bash
# Hoy
du -sb /var/log > /tmp/du_hoy.txt

# Ayer para comparar
diff /tmp/du_ayer.txt /tmp/du_hoy.txt | grep '^>' | sort -rn | head -10
```

### Espacio usado por usuario (en /home)

```bash
du -sh /home/* | sort -rh
```

### Docker: espacio usado por imágenes y contenedores

```bash
du -sh /var/lib/docker/* | sort -rh
```

---

## Combinación con otras herramientas

### du + sort: ranking descendente

```bash
du -sh /var/log/* | sort -rh | head -10
```

### du + awk: filtrar por unidad

```bash
# Solo directorios que pesan más de 1 GB
du -sh /var/* | awk '$0 ~ /G/'
```

### du + grep: excluir temporales

```bash
du -sh /var/* | grep -v tmp | sort -rh | head -10
```

### du + df: diagnóstico de disco completo

```bash
df -h                     # Vista global
du -sh /* | sort -rh | head -10   # Vista granular
```

---

## Uno-liners imprescindibles

```bash
du -sh /var/log                # Tamaño total de logs
du -sh /var/* | sort -rh | head -10  # Top 10 en /var
du -sh /* | sort -rh          # Ranking de todo el sistema raíz
du -sh --exclude=node_modules /home/* | sort -rh  # /home sin node_modules
du -shx / | sort -rh          # Sin cruzar sistemas de archivos
du -sh --time /var/log/*      # Con fecha de último cambio
du -ach /var/log/*.log | sort -rh | head -10  # Archivos .log más grandes
```

---

## Errores comunes

- **Ejecutar `du -sh /` sin `-x`**. Termina recorriendo `/proc`, `/sys`, `/dev` y el servidor se congela. Siempre usar `-x` en la raíz.
- **Confundir `du` con `df`**. `du` mide archivos. `df` mide el sistema de archivos. Pueden diferir (archivos borrados con FD abiertos, metadatos, reserva del 5%).
- **Asumir que `du` es instantáneo**. En directorios con millones de archivos puede tardar minutos. Usar `-s` o acotar la profundidad.
- **No ordenar la salida**. `du -sh /var/*` sin `sort -rh` muestra todo mezclado.
- **Usar `du -h` en scripts**. El formato humano no es consistente entre sistemas (puede mostrar K, M, G, T). Para scripts usar `-b` (bytes) o `-k` (KB).

---

## Buenas prácticas

- Siempre ordenar con `sort -rh` cuando veas du.
- Para directorios grandes, limitar profundidad con `--max-depth=2`.
- En scripts, usar `-k` o `-b` en vez de `-h` para valores predecibles.
- Para monitorear crecimiento, guardar `du -sb /var/log` diariamente y comparar.
- Cuando un disco se llena, la secuencia de diagnóstico es: `df -h` → `du -sh /* | sort -rh` → profundizar en el directorio que más pesa.

---

## Referencias internas

- [`df`](../df.md) — espacio disponible en sistemas de archivos
- [`find`](../find.md) — encontrar archivos grandes por tamaño
- [`storage_backup`](../storage_backup.md) — backup y limpieza de discos
