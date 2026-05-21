# Escenario: Identificar procesos que consumen más recursos

## Problema

El servidor está lento. Hay que identificar qué procesos consumen más CPU, memoria y disco para determinar la causa.

## Pipeline: Top 10 procesos por uso de CPU

```bash
ps aux \
  | sort -k3 -rn \
  | head -11 \
  | awk 'NR == 1 { printf "%-8s %-5s %-5s %s\n", "USUARIO", "CPU%", "MEM%", "COMANDO" }
         NR > 1 { printf "%-8s %-5s %-5s %s\n", $1, $3, $4, $11 }'
```

### Explicación paso a paso

1. **`ps aux`** — Lista todos los procesos con uso de CPU (columna 3) y memoria (columna 4)
2. **`sort -k3 -rn`** — Ordena descendente por CPU (`-k3` campo 3, `-r` reverso, `-n` numérico)
3. **`head -11`** — Toma 11 líneas (1 cabecera + 10 procesos)
4. **`awk 'NR == 1 { ... } NR > 1 { ... }'`** — Formatea en columnas: cabecera vs datos

## Pipeline: Top por uso de memoria

```bash
ps aux \
  | sort -k4 -rn \
  | head -11 \
  | awk 'NR==1{printf "%-8s %-5s %-6s %-5s %s\n","USUARIO","PID","MEM%","RSS","COMANDO"}
         NR>1{printf "%-8s %-5s %-6s %-5s %s\n",$1,$2,$4,$6,$11}'
```

## Pipeline: Memoria total usada por usuario

```bash
ps aux \
  | awk 'NR>1 { mem[$1] += $4; cpu[$1] += $3 }
         END {
           print "USUARIO    CPU%    MEM%"
           for (u in mem) printf "%-10s %-6.1f %-6.1f\n", u, cpu[u], mem[u]
         }' \
  | sort -k3 -rn
```

## Pipeline: Procesos zombies

```bash
ps aux \
  | awk '$8 ~ /Z/ { print }' \
  | awk '{ print $2, $8, $11, "-> ZOMBIE!" }'
```

## Pipeline: Contar procesos por estado

```bash
ps aux \
  | awk 'NR>1 { estados[substr($8,1,1)]++ }
         END {
           for (e in estados) {
             if (e == "R") desc = "Running"
             if (e == "S") desc = "Sleeping"
             if (e == "D") desc = "Disk sleep"
             if (e == "Z") desc = "Zombie"
             if (e == "T") desc = "Stopped"
             print e, desc, estados[e]
           }
         }' \
  | sort -k3 -rn
```

## Pipeline: Procesos con más hilos (threads)

```bash
ps aux \
  | awk 'NR>1 { print $2, $11 }' \
  | while read pid cmd; do
      threads=$(ls /proc/$pid/task 2>/dev/null | wc -l)
      [ -n "$threads" ] && echo "$threads $pid $cmd"
    done \
  | sort -rn \
  | head -10 \
  | column -t
```

## Pipeline: Consumo de memoria por proceso (formato humano)

```bash
ps aux \
  | sort -k4 -rn \
  | head -10 \
  | awk '{
      rss_mb = $6 / 1024
      printf "%-20s %6.1f MB %s\n", $11, rss_mb, $2
    }'
```

## Pipeline: Detectar memory leak (crecimiento de un proceso)

```bash
watch -n 5 '
  ps aux \
    | grep "mi_proceso" \
    | grep -v grep \
    | awk "{print \$3, \$4, \$11}"
'
```

## Pipeline: Archivos abiertos por proceso (más intensivos)

```bash
for pid in $(ps aux --sort=-%mem | awk 'NR>1{print $2}' | head -10); do
  cmd=$(ps -p $pid -o comm= 2>/dev/null)
  fds=$(ls /proc/$pid/fd 2>/dev/null | wc -l)
  [ -n "$fds" ] && echo "$fds $pid $cmd"
done \
  | sort -rn \
  | column -t
```

## Interpretación

| Indicador | Qué significa |
|-----------|---------------|
| Un proceso con >80% CPU sostenido | Proceso en bucle infinito o cómputo intensivo |
| Memoria creciendo sin liberar | Posible memory leak |
| Procesos zombie | Proceso padre no llama a wait(), bug de la app |
| Swap usado >0 | Falta de RAM física, rendimiento degradado |
| Un usuario con muchos procesos | Sesión de usuario con fugas o ataque |
| `D` state (uninterruptible sleep) | Proceso esperando I/O de disco (posible disco lento/fallando) |

## Comandos relacionados

- [`awk.md`](../../guides/awk.md) — arrays asociativos para acumular por usuario
- [`sort.md`](../../guides/sort.md) — ordenamiento numérico por campo
- [`grep.md`](../../guides/grep.md) — filtrado de procesos específicos
- [`xargs.md`](../../guides/xargs.md) — para actuar sobre procesos encontrados
