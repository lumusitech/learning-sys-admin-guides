# Escenario: Detectar ataque de fuerza bruta SSH

## Problema

El servidor presenta alta carga de CPU y múltiples conexiones SSH fallidas. Se necesita identificar las IPs atacantes, su frecuencia, y generar un reporte para bloquearlas.

## Datos de entrada

Usamos `/var/log/auth.log` (o el archivo de ejemplo `labs/auth.log`).

## Pipeline completo

```bash
grep "Failed password" labs/auth.log \
  | grep -oP 'from \K[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' \
  | sort \
  | uniq -c \
  | sort -rn \
  | awk '$1 > 5 { print $2, $1, "intentos - BLOQUEAR" }' \
  | head -10
```

### Explicación paso a paso

1. **`grep "Failed password"`** — Filtra solo líneas de login fallido
2. **`grep -oP 'from \K[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+'`** — Extrae solo la IP (`-o` solo match, `-P` regex Perl, `\K` descarta lo anterior)
3. **`sort`** — Ordena IPs alfabéticamente (necesario para `uniq`)
4. **`uniq -c`** — Agrupa IPs iguales y las cuenta
5. **`sort -rn`** — Ordena por frecuencia descendente
6. **`awk '$1 > 5'`** — Filtra IPs con más de 5 intentos
7. **`head -10`** — Top 10 atacantes

### Salida esperada

```
192.168.1.200 150 intentos - BLOQUEAR
10.0.0.50 89 intentos - BLOQUEAR
203.0.113.45 45 intentos - BLOQUEAR
```

## Variantes

### Con detección de usuarios atacados

```bash
grep "Failed password" labs/auth.log \
  | grep -oP 'for \K[^ ]+' \
  | sort \
  | uniq -c \
  | sort -rn \
  | head -10
```

### Reporte completo (IP + usuario + timestamp)

```bash
grep "Failed password" labs/auth.log \
  | awk '{
      ip  = gensub(/.*from ([0-9.]+).*/, "\\1", "g");
      user = gensub(/.*for ([^ ]+).*/, "\\1", "g");
      print $1, $2, $3, user, ip
    }' \
  | sort -k5 \
  | column -t
```

### Generar regla iptables para bloquear

```bash
grep "Failed password" labs/auth.log \
  | grep -oP 'from \K[0-9.]+' \
  | sort \
  | uniq -c \
  | sort -rn \
  | awk '$1 > 10 { print "iptables -A INPUT -s " $2 " -j DROP" }'
```

### Watch en tiempo real (ataque activo)

```bash
tail -f /var/log/auth.log \
  | grep --line-buffered "Failed password" \
  | grep -oP 'from \K[0-9.]+' \
  | sort \
  | uniq -c
```

## Interpretación

| Frecuencia | Interpretación |
|------------|----------------|
| 1-3 intentos | Error humano (contraseña mal escrita) |
| 5-20 intentos | Escaneo automatizado suave |
| 20-100+ intentos | Ataque de fuerza bruta activo |
| Misma IP + distintos usuarios | Ataque contra múltiples cuentas |
| Misma IP + mismo usuario | Ataque contra una cuenta específica |
| Múltiples IPs + mismo usuario | Ataque distribuido (botnet) |

## Comandos relacionados en las guías

- [`grep.md`](../../guides/grep.md) — búsqueda con `-oP` y `\K`
- [`sort.md`](../../guides/sort.md) + [`uniq.md`](../../guides/uniq.md) — conteo de frecuencias
- [`awk.md`](../../guides/awk.md) — filtrado condicional con `$1 > 5`
- [`iptables.md`](../../guides/iptables.md) — bloqueo de IPs
