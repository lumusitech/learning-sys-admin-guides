# Escenario: Análisis de rendimiento y errores web

## Problema

El sitio web responde lento y los usuarios reportan errores. Necesitamos analizar los logs del servidor web (Apache/Nginx) para identificar rutas lentas, picos de tráfico, errores frecuentes y posibles cuellos de botella.

## Pipeline: Tiempos de respuesta (si el log incluye tiempo)

Formato de log con tiempo de respuesta (Nginx):
```
$remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent" $request_time
```

```bash
# Extraer ruta y tiempo, ordenar por tiempo descendente
awk '{
  # Campo 7 = ruta, último campo = tiempo en segundos
  ruta = $7
  tiempo = $NF
  print tiempo, ruta
}' labs/nginx_access.log \
  | sort -rn \
  | head -10 \
  | awk '{ printf "%6.3fs %s\n", $1, substr($0, index($0,$2)) }'
```

## Pipeline: Peticiones por minuto (tráfico general)

```bash
awk '{
  split($4, t, "[/:]")
  minuto = t[4] ":" t[5]
  peticiones[minuto]++
}
END {
  for (m in peticiones) print m, peticiones[m]
}' labs/nginx_access.log \
  | sort \
  | head -30 \
  | awk '{
      if ($2 > max) { max = $2; pico = $1 }
    }
    END { print "Pico máximo:", pico, "-", max, "peticiones/minuto" }'
```

## Pipeline: Tasa de errores 4xx/5xx vs total

```bash
TOTAL=$(wc -l < labs/nginx_access.log)
ERRORES=$(awk '$9 ~ /^[45]/' labs/nginx_access.log | wc -l)

echo "Total peticiones: $TOTAL"
echo "Errores 4xx/5xx: $ERRORES"
echo "Tasa de error:   $(echo "scale=2; $ERRORES * 100 / $TOTAL" | bc)%"
```

## Pipeline: Errores 500 por endpoint

```bash
awk '$9 == 500 { print $7, $1 }' labs/nginx_access.log \
  | sort \
  | uniq -c \
  | sort -rn \
  | head -10 \
  | awk '{ printf "%d %s (IP: %s)\n", $1, $2, $3 }'
```

## Pipeline: Detectar páginas lentas (percentil 95)

```bash
awk '{ print $NF, $7 }' labs/nginx_access.log \
  | sort -n \
  | awk '{
      lines[NR] = $0
    }
    END {
      p95 = int(NR * 0.95)
      print "Percentil 95:", lines[p95]
      print "Máximo:", lines[NR]
    }'
```

## Pipeline: Referers externos (quién enlaza al sitio)

```bash
awk '{
  referer = $11
  if (referer != "\"-\"" && referer !~ /^\"http[s]?:\/\/misitio/)
    print referer
}' labs/nginx_access.log \
  | sort \
  | uniq -c \
  | sort -rn \
  | head -10 \
  | sed 's/^ *//' \
  | awk '{ printf "%d %s\n", $1, substr($0, index($0,$2)) }'
```

## Pipeline: Códigos de estado HTTP con descripción

```bash
awk '{ print $9 }' labs/nginx_access.log \
  | sort \
  | uniq -c \
  | sort -rn \
  | awk '{
      code = $2
      if (code == 200) desc = "OK"
      else if (code == 301) desc = "Moved Permanently"
      else if (code == 302) desc = "Found (redirect)"
      else if (code == 304) desc = "Not Modified"
      else if (code == 400) desc = "Bad Request"
      else if (code == 401) desc = "Unauthorized"
      else if (code == 403) desc = "Forbidden"
      else if (code == 404) desc = "Not Found"
      else if (code == 405) desc = "Method Not Allowed"
      else if (code == 408) desc = "Request Timeout"
      else if (code == 429) desc = "Too Many Requests"
      else if (code == 500) desc = "Internal Server Error"
      else if (code == 502) desc = "Bad Gateway"
      else if (code == 503) desc = "Service Unavailable"
      else if (code == 504) desc = "Gateway Timeout"
      else desc = "Unknown"
      printf "%-3s %-25s %s\n", code, desc, $1
    }'
```

## Pipeline: Análisis de User-Agents (tráfico real vs bots)

```bash
echo "=== Bots/Crawlers ==="
awk '{ print $NF }' labs/nginx_access.log \
  | grep -iE "bot|crawler|spider|scanner" \
  | sort \
  | uniq -c \
  | sort -rn \
  | head -10 \
  | awk '{ printf "%d %s\n", $1, substr($0, index($0,$2)) }'

echo ""
echo "=== Navegadores reales ==="
awk '{ print $NF }' labs/nginx_access.log \
  | grep -viE "bot|crawler|spider|scanner|curl|wget|python" \
  | sort \
  | uniq -c \
  | sort -rn \
  | head -10 \
  | awk '{ printf "%d %s\n", $1, substr($0, index($0,$2)) }'
```

## Pipeline: Detectar picos anómalos de tráfico

```bash
# Calcular promedio y desviación
awk '{ split($4,t,"[/:]"); minuto = t[4]":"t[5]; req[minuto]++ }
END {
  for (m in req) {
    total += req[m]
    count++
  }
  avg = total / count
  for (m in req) {
    if (req[m] > avg * 2) print "PICO:", m, req[m], "(promedio: " int(avg) ")"
  }
}' labs/nginx_access.log \
  | sort
```

## Pipeline: Análisis de ancho de banda por ruta

```bash
awk '{ ruta = $7; bytes[ruta] += $10 }
END {
  for (r in bytes) {
    mb = bytes[r] / (1024 * 1024)
    if (mb > 1) printf "%.2f MB %s\n", mb, r
  }
}' labs/nginx_access.log \
  | sort -rn \
  | head -10
```

## Interpretación

| Indicador | Diagnóstico |
|-----------|-------------|
| `request_time` > 5s | Backend lento (base de datos, API externa) |
| 502/504 creciendo | Proxy/upstream caído o timeout |
| 429 desde misma IP | Rate limiting, posible scraping |
| 404 en rutas que no existen | Escaneo de directorios |
| Ancho de banda alto en una ruta | Archivos grandes servidos, posible hotlinking |
| Peticiones/min duplicado en minutos sucesivos | Crawler automático regular |
| User-Agent `-` | Cliente HTTP mal formado, potencial ataque |

## Comandos relacionados

- [`awk.md`](../../guides/awk.md) — arrays, split, acumuladores
- [`grep.md`](../../guides/grep.md) — filtrado por código de estado
- [`sort.md`](../../guides/sort.md) + [`uniq.md`](../../guides/uniq.md) — frecuencias
- [`bc`] — cálculos aritméticos en shell
- [`sed.md`](../../guides/sed.md) — limpieza de formato
