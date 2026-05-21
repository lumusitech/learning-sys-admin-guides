# Escenario: Detectar escaneo de puertos en logs de firewall

## Problema

Un atacante está escaneando los puertos abiertos del servidor. Los logs del firewall (iptables) muestran conexiones entrantes a múltiples puertos desde una misma IP en poco tiempo. Necesitamos identificar la IP, qué puertos escaneó, y bloquearla.

## Datos de entrada

Log de kernel generado por iptables (ej: `/var/log/kern.log` o el ejemplo `labs/firewall.log`).

Formato típico de log iptables:
```
Jan 15 14:30:22 kernel: [IPTABLES] IN=eth0 OUT= MAC=... SRC=10.0.0.5 DST=192.168.1.100 LEN=40 TOS=... PROTO=TCP SPT=54321 DPT=22 SYN
```

## Pipeline: IPs que más conexiones hacen

```bash
grep -oP 'SRC=\K[0-9.]+' labs/firewall.log \
  | sort \
  | uniq -c \
  | sort -rn \
  | head -10
```

### Explicación paso a paso

1. **`grep -oP 'SRC=\K[0-9.]+'`** — Extrae IP origen (`SRC=...`) usando `-o` (solo match) y `\K` (descartar prefijo)
2. **`sort`** — Ordena alfabéticamente para uniq
3. **`uniq -c`** — Cuenta conexiones por IP
4. **`sort -rn`** — Ordena descendente por número
5. **`head -10`** — Top 10

## Pipeline: Puertos escaneados por una IP sospechosa

```bash
IP_SOSPE="10.0.0.5"

grep "SRC=$IP_SOSPE" labs/firewall.log \
  | grep -oP 'DPT=\K[0-9]+' \
  | sort -n \
  | uniq \
  | awk '{ print "Puerto:", $1 }
    END { print "Total puertos únicos:", NR }'
```

## Pipeline: Detectar SYN scan (solo paquetes SYN sin ACK)

```bash
grep "SYN" labs/firewall.log \
  | grep -v "ACK" \
  | grep -oP 'SRC=\K[0-9.]+' \
  | sort \
  | uniq -c \
  | sort -rn \
  | awk '$1 > 10 { print $2, "->", $1, "SYNs (posible SYN scan)" }'
```

## Pipeline: Reporte completo de escaneo

```bash
grep "SRC=10.0.0.5" labs/firewall.log \
  | awk '{
      split($0, arr, " ")
      for (i in arr) {
        if (arr[i] ~ /SRC=/) ip = substr(arr[i], 5)
        if (arr[i] ~ /DPT=/) port = substr(arr[i], 5)
        if (arr[i] ~ /PROTO=/) proto = substr(arr[i], 7)
      }
      print ip, port, proto
    }' \
  | sort -k2 -n \
  | uniq \
  | column -t
```

## Pipeline: Detectar scan de puertos más comunes (top 20)

```bash
grep -oP 'DPT=\K[0-9]+' labs/firewall.log \
  | sort \
  | uniq -c \
  | sort -rn \
  | head -20 \
  | awk '{
      port = $2
      service = ""
      if (port == 22)  service = "SSH"
      if (port == 80)  service = "HTTP"
      if (port == 443) service = "HTTPS"
      if (port == 3306) service = "MySQL"
      if (port == 5432) service = "PostgreSQL"
      if (port == 3389) service = "RDP"
      if (port == 6379) service = "Redis"
      if (port == 27017) service = "MongoDB"
      printf "Puerto %-5s %-15s %d intentos\n", port, service, $1
    }'
```

## Pipeline: Generar reglas de bloqueo

```bash
grep -oP 'SRC=\K[0-9.]+' labs/firewall.log \
  | sort \
  | uniq -c \
  | sort -rn \
  | awk '$1 > 20 {
      print "iptables -A INPUT -s " $2 " -j LOG --log-prefix \"BLOCKED: \""
      print "iptables -A INPUT -s " $2 " -j DROP"
      print ""
    }'
```

## Pipeline: Watch en tiempo real (detección activa)

```bash
tail -f /var/log/kern.log \
  | grep --line-buffered "IPTABLES" \
  | grep -oP 'SRC=\K[0-9.]+' \
  | sort \
  | uniq -c
```

## Interpretación

| Señal | Interpretación |
|-------|----------------|
| Una IP a +20 puertos diferentes en <1min | Escaneo de puertos automatizado |
| Múltiples IPs al mismo puerto | Escaneo horizontal (misma IP objetivo) |
| Una IP a un puerto con +100 SYN | Posible SYN flood (DoS) |
| Paquetes con flags extraños (FIN+PSH+URG) | Xmas scan (evasión nmap) |
| Paquetes sin flags (NULL) | NULL scan (evasión nmap) |
| Origen puerto bajo a destino puerto bajo | Escaneo de servicios comunes |

## Comandos relacionados

- [`grep.md`](../../guides/grep.md) — `-oP`, `\K`, extracción de patrones
- [`awk.md`](../../guides/awk.md) — procesamiento de logs estructurados
- [`sort.md`](../../guides/sort.md) + [`uniq.md`](../../guides/uniq.md) — conteo
- [`iptables.md`](../../guides/iptables.md) — reglas de bloqueo y logging
- [`tcpdump.md`](../../guides/tcpdump.md) — captura de paquetes para confirmar
