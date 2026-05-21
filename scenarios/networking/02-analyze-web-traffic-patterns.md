# Escenario: Analizar patrones de tráfico web

## Problema

El servidor web está lentro. Necesitamos entender qué rutas se solicitan más, qué códigos de estado predominan, y detectar posibles ataques o crawlers abusivos.

## Datos de entrada

Usamos `labs/access.log` (formato Apache/Nginx combinado).

## Pipeline: Top 10 rutas más solicitadas

```bash
awk '{ print $7 }' labs/nginx_access.log \
  | sort \
  | uniq -c \
  | sort -rn \
  | head -10
```

### Explicación paso a paso

1. **`awk '{ print $7 }'`** — Extrae la ruta URL (campo 7 en log combinado: `"GET /ruta HTTP/1.1"`)
2. **`sort`** — Ordena rutas alfabéticamente
3. **`uniq -c`** — Cuenta ocurrencias de cada ruta
4. **`sort -rn`** — Ordena descendente por frecuencia
5. **`head -10`** — Top 10

## Pipeline: Códigos de estado HTTP

```bash
awk '{ print $9 }' labs/nginx_access.log \
  | sort \
  | uniq -c \
  | sort -rn \
  | awk '{ 
      if ($2 ~ /^2/) clase = "2xx - Éxito";
      else if ($2 ~ /^3/) clase = "3xx - Redirección";
      else if ($2 ~ /^4/) clase = "4xx - Error cliente";
      else if ($2 ~ /^5/) clase = "5xx - Error servidor";
      else clase = "Otro";
      print $1, $2, clase
    }'
```

## Pipeline: Detectar crawlers por User-Agent

```bash
awk '{ print $1, $NF }' labs/nginx_access.log \
  | grep -iE "bot|crawler|spider|scanner" \
  | sort \
  | uniq -c \
  | sort -rn \
  | head -15
```

## Pipeline: Peticiones por hora (patrón de tráfico)

```bash
awk '{
  split($4, t, /[/:]/);
  hora = t[4];
  horas[hora]++
}
END {
  for (h in horas) printf "%02d:00 %d peticiones\n", h, horas[h]
}' labs/nginx_access.log \
  | sort
```

## Pipeline: Detectar escaneo de rutas (404 desde misma IP)

```bash
awk '$9 == 404 { print $1, $7 }' labs/nginx_access.log \
  | sort \
  | uniq -c \
  | sort -rn \
  | awk '$1 > 3 { print $2, $3, $1 }' \
  | head -20
```

## Pipeline: Ancho de banda por IP

```bash
awk '{ ips[$1] += $10 } END { for (i in ips) printf "%.0f %s\n", ips[i], i }' labs/nginx_access.log \
  | sort -rn \
  | head -10 \
  | awk '{ printf "%-15s %s\n", $2, gensub(/([0-9]+)([0-9]{3})$/, "\\1.\\2 KB", "g", $1) }'
```

## Pipeline: Tasa de errores por minuto

```bash
awk '{
  split($4, t, /[/:]/);
  minuto = t[4] ":" t[5];
  total[minuto]++;
  if ($9 ~ /^[45]/) error[minuto]++
}
END {
  for (m in total)
    printf "%s %d %.1f%%\n", m, error[m], (error[m]/total[m])*100
}' labs/nginx_access.log \
  | sort \
  | head -20
```

## Pipeline: Sesiones por IP (misma IP + User-Agent)

```bash
awk '{ print $1, $NF }' labs/nginx_access.log \
  | sort -u \
  | cut -d' ' -f1 \
  | sort \
  | uniq -c \
  | sort -rn \
  | head -10
```

## Interpretación de resultados

| Indicador | Qué significa |
|-----------|---------------|
| Alta tasa 404 desde una IP | Escaneo de directorios (dirbuster/gobuster) |
| Muchas rutas igual desde misma IP | Crawler legítimo o scraping |
| 5xx creciendo | Problemas de backend (app caída, BD lenta) |
| Tráfico en horario anómalo (3-5am) | Ataque automatizado o backup |
| User-Agent inusual (curl, python-requests) | Scripting, posible ataque |
| Una IP con muchas requests/minuto | Posible DDoS o rate limit excedido |

## Comandos relacionados

- [`awk.md`](../../guides/awk.md) — arrays asociativos para acumular por IP/hora
- [`grep.md`](../../guides/grep.md) — filtrado por patrón con `-iE`
- [`sort.md`](../../guides/sort.md) + [`uniq.md`](../../guides/uniq.md) — conteo de frecuencias
