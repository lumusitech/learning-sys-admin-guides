# Escenario: Análisis de logs del sistema y tracking de errores

## Problema

El servidor está generando errores en los logs que deben ser analizados para identificar la causa raíz de inestabilidad.

## Pipeline: Errores por servicio (facilidad)

```bash
grep -i "error\|fail\|critical" labs/syslog.log \
  | awk '{ print $5 }' \
  | sort \
  | uniq -c \
  | sort -rn \
  | head -10 \
  | awk '{ printf "%-30s %d errores\n", $2, $1 }'
```

### Explicación paso a paso

1. **`grep -i "error\|fail\|critical"`** — Busca líneas con palabras clave (insensible a mayúsculas)
2. **`awk '{ print $5 }'`** — Extrae el nombre del servicio (campo 5 en syslog típico)
3. **`sort`** — Ordena alfabéticamente
4. **`uniq -c`** — Cuenta ocurrencias por servicio
5. **`sort -rn`** — Ordena descendente
6. **`awk '{ printf "%-30s %d errores\n" ... }'`** — Formatea salida en columnas

## Pipeline: Errores por hora

```bash
grep -i "error\|fail\|critical" labs/syslog.log \
  | awk '{
      split($3, t, ":")
      hora = t[1]
      errores[hora]++
    }
    END {
      for (h in errores) printf "%02d:00 %d\n", h, errores[h]
    }' \
  | sort
```

## Pipeline: Últimos 20 errores con contexto

```bash
grep -n "error\|fail\|critical" labs/syslog.log \
  | tail -20 \
  | while IFS=: read -r num linea; do
      echo "--- Línea $num ---"
      echo "$linea"
      echo ""
    done
```

## Pipeline: Líneas entre marcas de tiempo (rango de tiempo)

```bash
sed -n '/14:30:00/,/15:00:00/p' labs/syslog.log \
  | grep -i "error"
```

## Pipeline: Detectar patrones repetitivos (posible problema cíclico)

```bash
awk '{
  # Extraer mensaje (después del PID o servicio)
  msg = $0
  gsub(/^[^ ]+ [^ ]+ [^ ]+ [^ ]+ [^ ]+ /, "", msg)
  msgs[msg]++
}
END {
  for (m in msgs) {
    if (msgs[m] > 3) print msgs[m], substr(m, 1, 80)
  }
}' labs/syslog.log \
  | sort -rn \
  | head -15
```

## Pipeline: Correlacionar journalctl con syslog

```bash
journalctl -u sshd -b --no-pager \
  | awk '{ print $1, $2, $3, $5 }' \
  | grep -i "fail\|error\|invalid"
```

## Pipeline: Monitoreo de OOM (Out of Memory)

```bash
grep -i "oom\|killed\|out of memory" labs/syslog.log \
  | awk '{
      pid = ""
      proceso = ""
      if (match($0, /pid=([0-9]+)/)) pid = substr($0, RSTART+4, RLENGTH-4)
      if (match($0, /process=([^ ]+)/)) proceso = substr($0, RSTART+8, RLENGTH-8)
      print $1, $2, $3, pid, proceso, "OOM KILLED"
    }' \
  | column -t
```

## Pipeline: Watch de errores en tiempo real

```bash
tail -f /var/log/syslog \
  | grep --line-buffered -i "error\|fail\|critical" \
  | awk '{ print strftime("%H:%M:%S"), $0 }'
```

## Pipeline: Reporte diario de errores

```bash
#!/bin/bash
echo "=== Reporte de errores: $(date +%Y-%m-%d) ==="
echo ""

echo "--- Por servicio ---"
grep -i "error\|fail\|critical" labs/syslog.log \
  | awk '{ print $5 }' \
  | sort \
  | uniq -c \
  | sort -rn \
  | awk '{ printf "%-20s %d\n", $2, $1 }'

echo ""
echo "--- Por hora ---"
grep -i "error\|fail\|critical" labs/syslog.log \
  | awk '{ split($3,t,":"); h[t[1]]++ } END { for (i in h) printf "%02d:00 %d\n", i, h[i] }' \
  | sort

echo ""
echo "--- Últimos 5 errores críticos ---"
grep -i "critical" labs/syslog.log | tail -5
```

## Interpretación

| Patrón | Significado |
|--------|-------------|
| `OOM` seguido de `killed process` | Falta de RAM, el kernel mata procesos |
| `EXT4-fs error` | Error de sistema de archivos (disco fallando) |
| `segfault` en un servicio | Bug del servicio: crashea con violación de segmento |
| `Connection refused` repetido | Un servicio no está escuchando o está caído |
| `timeout` repetitivo | Red lenta o servicio saturado |
| `disk full` | Disco lleno, sistema en riesgo |
| `Permission denied` | Problema de permisos en archivos/directorios |

## Comandos relacionados

- [`grep.md`](../../guides/grep.md) — `-i` para ignorar mayúsculas
- [`awk.md`](../../guides/awk.md) — arrays, `split`, `substr`
- [`sed.md`](../../guides/sed.md) — rangos de líneas con `/start/,/end/`
- [`sort.md`](../../guides/sort.md) + [`uniq.md`](../../guides/uniq.md) — frecuencias
