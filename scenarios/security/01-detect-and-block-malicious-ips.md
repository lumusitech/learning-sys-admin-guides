# Escenario: Detectar y bloquear IPs maliciosas

## Problema

El servidor recibe tráfico malicioso de múltiples IPs. Necesitamos correlacionar logs de diferentes fuentes (auth, acceso web, firewall) para identificar atacantes y bloquearlos automáticamente.

## Pipeline: IPs comunes entre auth.log y access.log

```bash
# IPs que aparecen tanto en fallos SSH como en peticiones web
comm -12 \
  <(grep "Failed password" labs/auth.log | grep -oP 'from \K[0-9.]+' | sort -u) \
  <(awk '{ print $1 }' labs/nginx_access.log | sort -u)
```

### Explicación

- **`comm -12`**: muestra líneas comunes entre dos archivos ordenados
- **`<(comando)`**: process substitution, trata la salida del comando como un archivo
- Primer subcomando: extrae IPs de intentos SSH fallidos
- Segundo subcomando: extrae IPs de peticiones web

## Pipeline: Score de amenaza por IP

```bash
#!/bin/bash
# Puntúa IPs según actividad sospechosa
# +1 por intento SSH fallido, +1 por petición 404, +3 por escaneo de puertos

echo "IP PUNTOS RAZONES"
echo "-- ------ -------"

# Obtener IPs de todas las fuentes
grep "Failed password" labs/auth.log \
  | grep -oP 'from \K[0-9.]+' \
  | sort \
  | uniq -c \
  | awk '{ print $2, $1 * 2 }'  # SSH fail: 2 puntos c/u

grep " 404 " labs/nginx_access.log \
  | awk '{ print $1 }' \
  | sort \
  | uniq -c \
  | awk '{ print $1, $2 * 1 }'  # 404: 1 punto c/u

grep "DPT=" labs/firewall.log 2>/dev/null \
  | grep -oP 'SRC=\K[0-9.]+' \
  | sort \
  | uniq -c \
  | awk '$1 > 5 { print $2, $1 * 3 }'  # Escaneo: 3 puntos c/u
```

## Pipeline: Bloquear IPs con más de N intentos

```bash
# Encontrar IPs candidates
grep "Failed password" labs/auth.log \
  | grep -oP 'from \K[0-9.]+' \
  | sort \
  | uniq -c \
  | sort -rn \
  | awk '$1 > 10 { print $2, $1 }' \
  | while read ip count; do
      echo "BLANQUEAR: $ip ($count intentos)"
      # iptables -A INPUT -s $ip -j DROP
    done
```

## Pipeline: Reporte consolidado de amenazas

```bash
echo "=== REPORTE DE SEGURIDAD ==="
echo ""

echo "→ Intentos SSH fallidos por IP:"
grep "Failed password" labs/auth.log \
  | grep -oP 'from \K[0-9.]+' \
  | sort \
  | uniq -c \
  | sort -rn \
  | head -10 \
  | awk '{ printf "  %-15s %d intentos\n", $2, $1 }'

echo ""
echo "→ Usuarios más atacados:"
grep "Failed password" labs/auth.log \
  | grep -oP 'for \K[^ ]+' \
  | sort \
  | uniq -c \
  | sort -rn \
  | head -10 \
  | awk '{ printf "  %-15s %d intentos\n", $2, $1 }'

echo ""
echo "→ IPs que generaron 404:"
grep " 404 " labs/nginx_access.log \
  | awk '{ print $1 }' \
  | sort \
  | uniq -c \
  | sort -rn \
  | head -10 \
  | awk '{ printf "  %-15s %d accesos\n", $2, $1 }'

echo ""
echo "→ User Agents sospechosos:"
grep -iE "nikto|sqlmap|nmap|curl|wget|python-requests" labs/nginx_access.log \
  | awk '{ print $NF }' \
  | sort \
  | uniq -c \
  | sort -rn \
  | head -10 \
  | awk '{ printf "  %d %s\n", $1, substr($0, index($0,$2)) }'

echo ""
echo "→ Puertos escaneados (firewall):"
grep -oP 'DPT=\K[0-9]+' labs/firewall.log 2>/dev/null \
  | sort \
  | uniq -c \
  | sort -rn \
  | head -15 \
  | awk '{ printf "  Puerto %-5s %d intentos\n", $2, $1 }'
```

## Pipeline: Fail2ban-like con tools estándar

```bash
# BAN temporal vía iptables con expiración (simulado)
grep "Failed password" labs/auth.log \
  | grep -oP 'from \K[0-9.]+' \
  | sort \
  | uniq -c \
  | sort -rn \
  | awk '$1 >= 5 {
      cmd = "iptables -A INPUT -s " $2 " -j DROP"
      print cmd
      # system(cmd)  # descomentar para ejecutar
    }'
```

## Pipeline: Detectar ataques DDoS (muchas requests desde muchas IPs)

```bash
# Peticiones por segundo (aproximado)
TOTAL=$(wc -l < labs/nginx_access.log)
PRIMER=$(head -1 labs/nginx_access.log | awk '{ print $4 }' | tr -d '[')
ULTIMO=$(tail -1 labs/nginx_access.log | awk '{ print $4 }' | tr -d '[')
echo "Total peticiones: $TOTAL"

# IPs con más requests
awk '{ print $1 }' labs/nginx_access.log \
  | sort \
  | uniq -c \
  | sort -rn \
  | head -10 \
  | awk '$1 > 50 { print $2, $1, "ALTO VOLUMEN" }'
```

## Interpretación

| Puntaje | Acción |
|---------|--------|
| 1-5 puntos | Monitorear, posible falso positivo |
| 5-15 puntos | Rate limiting recomendado |
| 15-50 puntos | Bloquear inmediatamente |
| 50+ puntos | Bloquear y reportar a ISP/abuse |

## Comandos relacionados

- [`grep.md`](../../guides/grep.md) — extracción con `-oP` y `\K`
- [`awk.md`](../../guides/awk.md) — arrays, formateo
- [`sort.md`](../../guides/sort.md) + [`uniq.md`](../../guides/uniq.md) — conteo
- [`iptables.md`](../../guides/iptables.md) — bloqueo de IPs
- [`xargs.md`](../../guides/xargs.md) — ejecutar comandos en lote
