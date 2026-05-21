# 🧩 Escenario: Detectar escaneo de puertos en logs de firewall

**Dominio:** networking / security
**Nivel:** 🟡 Intermedio
**Herramientas:** `grep`, `awk`, `sort`, `uniq`, `head`, `iptables`
**Archivos:** `labs/firewall.log`

**Quick command (SRE):** `awk '{for(i=1;i<=NF;i++) if($i ~ /^SRC=/){ip=$i; sub(/^SRC=/,"",ip); c[ip]++}} END{for(ip in c) print c[ip], ip}' labs/firewall.log | sort -rn | head -10`

**Quick command (original):** `awk '{for(i=1;i<=NF;i++) if($i ~ /^SRC=/) c[substr($i,5)]++} END{for(ip in c) print c[ip], ip}' labs/firewall.log | sort -rn | head`

**Cuándo usar este escenario:**
- Logs de firewall con muchas conexiones desde una IP
- Sospecha de escaneo de puertos
- IPs desconocidas probando múltiples puertos

**Archivo(s) de práctica:** `labs/firewall.log`

---

## 🎯 Objetivo

1. Identificar IPs que están escaneando puertos del servidor.
2. Detectar el tipo de escaneo (SYN, horizontal, evasión).
3. Generar reglas de bloqueo específicas.

---

## 🧠 Contexto

Los logs del firewall (iptables) muestran conexiones entrantes a múltiples puertos desde una misma IP en poco tiempo. Un atacante está probando qué servicios están abiertos para planear un ataque.

---

## ✅ Datos de entrada

- **Producción:** `/var/log/kern.log` (logs de iptables con `LOG`)
- **Práctica:** `labs/firewall.log`

---

## ⚡ Quick run (IPs que más conexiones hacen)

```bash
awk '{for(i=1;i<=NF;i++) if($i ~ /^SRC=/) print substr($i,5)}' labs/firewall.log | sort | uniq -c | sort -rn | head -10
```

---

## 🔍 Paso a paso

1. `awk '{for(i=1;i<=NF;i++) if($i ~ /^SRC=/) print substr($i,5)}'` → extrae IP origen después de `SRC=`
2. `sort` → ordena para uniq
3. `uniq -c` → cuenta conexiones por IP
4. `sort -rn` → ordena por frecuencia
5. `head -10` → top 10

---

## ✅ Salida esperada

```
150 10.0.0.5
 89 203.0.113.45
 45 192.168.1.200
```

- Una IP con muchas más conexiones que el resto → probable atacante
- Si son pocas conexiones por IP pero muchas IPs distintas → escaneo distribuido

---

## 📌 Pipelines de diagnóstico

### Puertos escaneados por IP sospechosa

```bash
IP_SOSPE="10.0.0.5"
grep "SRC=$IP_SOSPE" labs/firewall.log | awk '{for(i=1;i<=NF;i++) if($i ~ /^DPT=/) print substr($i,5)}' | sort -n | uniq \
| awk '{ print "Puerto:", $1 } END { print "Total puertos únicos:", NR }'
```

### Detectar SYN scan (SYN sin ACK)

```bash
grep "SYN" labs/firewall.log | grep -v "ACK" \
| awk '{for(i=1;i<=NF;i++) if($i ~ /^SRC=/) print substr($i,5)}' | sort | uniq -c | sort -rn \
| awk '$1>10{print $2, "->", $1, "SYNs (posible SYN scan)"}'
```

### Reporte completo de escaneo

```bash
grep "SRC=10.0.0.5" labs/firewall.log \
| awk '{ for(i=1;i<=NF;i++){ if($i~ /SRC=/)ip=substr($i,5); if($i~ /DPT=/)port=substr($i,5); if($i~ /PROTO=/)proto=substr($i,7) } print ip,port,proto }' \
| sort -k2 -n | uniq | column -t
```

### Puertos más escaneados (top 20)

```bash
awk '{for(i=1;i<=NF;i++) if($i ~ /^DPT=/) print substr($i,5)}' labs/firewall.log | sort | uniq -c | sort -rn | head -20 \
| awk '{ p=$2; if(p==22)s="SSH"; else if(p==80)s="HTTP"; else if(p==443)s="HTTPS"; else if(p==3306)s="MySQL"; else if(p==5432)s="PostgreSQL"; else if(p==3389)s="RDP"; else if(p==6379)s="Redis"; else s=""; printf "Puerto %-5s %-12s %d\n", p, s, $1 }'
```

### Generar reglas de bloqueo

```bash
awk '{for(i=1;i<=NF;i++) if($i ~ /^SRC=/) print substr($i,5)}' labs/firewall.log | sort | uniq -c | sort -rn \
| awk '$1>20{print "iptables -A INPUT -s", $2, "-j DROP"}'
```

### Watch en tiempo real

```bash
tail -f /var/log/kern.log | grep --line-buffered "IPTABLES" | awk '{for(i=1;i<=NF;i++) if($i ~ /^SRC=/) print substr($i,5)}' | sort | uniq -c
```

---

## 🧯 Mitigación

```bash
# Bloquear IP sospechosa
iptables -A INPUT -s 10.0.0.5 -j DROP

# Verificar reglas aplicadas
iptables -L INPUT -v -n | grep 10.0.0.5

# Rollback
iptables -D INPUT -s 10.0.0.5 -j DROP
```

⚠️ Aplicá de a una IP, verificá que no te bloquees a vos mismo.

---

## 🛡️ Prevención

- [ ] Tener solo los puertos necesarios abiertos
- [ ] Usar fail2ban para bloqueo automático
- [ ] Cambiar puertos no estándar para SSH (>1024)
- [ ] Rate limiting con iptables: `-m limit --limit 10/sec`
- [ ] Monitorear logs de firewall periódicamente

---

## 🧪 Variantes

### Detectar Xmas scan (flags FIN+PSH+URG)

```bash
grep "FIN" labs/firewall.log | grep "PSH" | grep "URG"
```

### Escaneo horizontal (mismo puerto, distintas IPs)

```bash
grep "DPT=22" labs/firewall.log | awk '{for(i=1;i<=NF;i++) if($i ~ /^SRC=/) print substr($i,5)}' | sort -u | wc -l
```

---

## 🧑‍🏫 Modo docente

**Preguntas:** ¿Por qué un SYN scan sin ACK es sospechoso? ¿Qué diferencia un escaneo de una conexión legítima?
**Ejercicio:** Detectar IPs que escanean más de 10 puertos distintos en menos de 1 minuto.
**Evaluación:** extracción correcta de IPs/puertos, clasificación del tipo de escaneo, mitigación sin bloquearte.

---

## 🧪 Cómo practicarlo en el lab

```bash
cd labs && docker compose -f docker-compose.security.yml up -d sec-attacker
# Simular escaneo desde el contenedor atacante
docker exec sec-attacker nmap -sS 10.99.0.0/24
# Ver logs
docker logs sec-attacker 2>&1 | tail -20
```

[Ver laboratorio completo →](../../labs/README.md)

---

## 🔗 Referencias

- [`guides/grep.md`](../../guides/grep.md) — `-oP`, `\K`
- [`guides/awk.md`](../../guides/awk.md) — procesamiento de logs
- [`guides/sort.md`](../../guides/sort.md) + [`guides/uniq.md`](../../guides/uniq.md) — conteo
- [`guides/iptables.md`](../../guides/iptables.md) — reglas de bloqueo y logging
- [`guides/tcpdump.md`](../../guides/tcpdump.md) — captura para confirmar
