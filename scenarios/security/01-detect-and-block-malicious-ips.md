⬅️ [Volver a scenarios](../README.md)

# 🧩 Escenario: Detectar y bloquear IPs maliciosas

**Dominio:** security
**Nivel:** 🟡 Intermedio
**Herramientas:** `grep`, `awk`, `sort`, `uniq`, `comm`, `iptables`, `xargs`
**Archivos:** `labs/auth.log`, `labs/nginx_access.log`, `labs/firewall.log`

## ⚡ Quick command (SRE)

`awk 'FNR==NR{if($0~/Failed password/){for(i=1;i<=NF;i++) if($i=="from"){a[$(i+1)]=1; break}}; next} {ip=$1; if(ip in a) b[ip]++} END{for(ip in b) print b[ip], ip}' labs/auth.log labs/nginx_access.log | sort -rn | head -10`

## 🔍 Análisis paso a paso

1. awk 'FNR==NR{...}' → procesa primero auth.log para identificar IPs con intentos fallidos de SSH
2. a[$(i+1)]=1 → guarda en un array las IPs atacantes detectadas
3. next → evita procesar la segunda parte en el primer archivo
4. {ip=$1; if(ip in a) b[ip]++} → cruza con nginx_access.log contando actividad web de esas mismas IPs
5. END{for(ip in b) print b[ip], ip} → imprime cantidad de accesos web por IP sospechosa
6. sort -rn → ordena de mayor a menor actividad
7. head -10 → muestra las 10 IPs más relevantes

## ✅ Resultado

- correlacionás actividad entre SSH y web
- identificás IPs con comportamiento malicioso consistente
- priorizás bloqueos basados en múltiples fuentes

---

## 🎯 Problema

Se detecta actividad sospechosa en múltiples servicios del sistema, lo que puede indicar ataques coordinados desde ciertas IPs. Es necesario correlacionar eventos entre diferentes logs para:

- correlacionar logs de múltiples fuentes (SSH, web, firewall) para identificar atacantes
- calcular un score de amenaza por IP basado en su actividad
- generar reglas de bloqueo automatizadas

---

## 🧠 Contexto

El servidor recibe tráfico malicioso de múltiples IPs desde distintas fuentes. Una IP que aparece en logs SSH, web y de firewall simultáneamente tiene alta probabilidad de ser maliciosa.

---

## ✅ Datos de entrada

- **Producción:** `/var/log/auth.log`, `/var/log/nginx/access.log`, `/var/log/kern.log`
- **Práctica:** `labs/auth.log`, `labs/nginx_access.log`, `labs/firewall.log`

---

## ⚡ Quick run (IPs comunes entre SSH fallido y web)

```bash
awk 'FNR==NR{if($0~/Failed password/){for(i=1;i<=NF;i++)if($i=="from"){a[$(i+1)]=1;break}};next} $1 in a{print $1}' labs/auth.log labs/nginx_access.log | sort -u
```

---

## 🔍 Paso a paso

1. Primer subcomando: extrae IPs con SSH fallido
2. Segundo subcomando: extrae IPs de peticiones web
3. `comm -12` → solo IPs que aparecen en ambas listas
4. IPs comunes → alta probabilidad de ataque coordinado

---

## ✅ Salida esperada

```
10.0.0.5
192.168.1.200
```

- Si ves IPs aquí, están atacando SSH y web simultáneamente → bloquear.
- Si no ves nada, las fuentes de ataque no se superponen.

---

## 📌 Pipelines de diagnóstico

### Score de amenaza por IP

```bash
echo "=== SCORE DE AMENAZA ==="
echo "IP PUNTOS RAZON"
awk '/Failed password/{for(i=1;i<=NF;i++) if($i=="from") print $(i+1)}' labs/auth.log | sort | uniq -c | awk '{ print $2, $1*2 }'  # SSH: 2 pts c/u
echo "---"
grep " 404 " labs/nginx_access.log | awk '{ print $1 }' | sort | uniq -c | awk '{ print $1, $2 }'  # 404: 1 pt c/u
echo "---"
grep "DPT=" labs/firewall.log 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i ~ /^SRC=/) print substr($i,5)}' | sort | uniq -c | awk '$1>5{print $2,$1*3}'  # Escaneo: 3 pts c/u
```

### Reporte consolidado de seguridad

```bash
echo "=== REPORTE DE SEGURIDAD ==="
echo ""
echo "→ Intentos SSH fallidos por IP:"
awk '/Failed password/{for(i=1;i<=NF;i++) if($i=="from") print $(i+1)}' labs/auth.log | sort | uniq -c | sort -rn | head -10
echo ""
echo "→ Usuarios más atacados:"
awk '/Failed password/{for(i=1;i<=NF;i++) if($i=="for") print $(i+1)}' labs/auth.log | sort | uniq -c | sort -rn | head -10
echo ""
echo "→ IPs con 404 en web:"
grep " 404 " labs/nginx_access.log | awk '{ print $1 }' | sort | uniq -c | sort -rn | head -10
echo ""
echo "→ User-Agents sospechosos:"
grep -iE "nikto|sqlmap|nmap|curl|python-requests" labs/nginx_access.log | awk '{ print $NF }' | sort | uniq -c | sort -rn | head -10
echo ""
echo "→ Puertos escaneados:"
awk '{for(i=1;i<=NF;i++) if($i ~ /^DPT=/) print substr($i,5)}' labs/firewall.log 2>/dev/null | sort | uniq -c | sort -rn | head -15
```

### Bloquear IPs con más de N intentos

```bash
awk '/Failed password/{for(i=1;i<=NF;i++) if($i=="from") print $(i+1)}' labs/auth.log | sort | uniq -c | sort -rn \
| awk '$1>10{print "iptables -A INPUT -s", $2, "-j DROP"}' | head -10
```

---

## 🧯 Mitigación

```bash
# Bloquear IP de alto score
iptables -A INPUT -s 10.0.0.5 -j DROP

# Si te equivocaste (rollback)
iptables -D INPUT -s 10.0.0.5 -j DROP
```

⚠️ Siempre guardar backup antes: `iptables-save > /root/iptables.backup`

---

## 🛡️ Prevención

- [ ] fail2ban con jail personalizado para SSH + web
- [ ] Rate limiting en nginx + iptables
- [ ] Whitelist de IPs confiables (VPN, oficina)
- [ ] Logs centralizados (rsyslog, ELK) para correlación

---

## 🧪 Variantes

### Fail2ban-like con herramientas estándar

```bash
awk '/Failed password/{for(i=1;i<=NF;i++) if($i=="from") print $(i+1)}' labs/auth.log | sort | uniq -c \
| awk '$1>=5{cmd="iptables -A INPUT -s "$2" -j DROP"; print cmd; system(cmd)}'
```

### Detectar DDoS (muchas IPs, mismas rutas)

```bash
awk '{ print $1, $7 }' labs/nginx_access.log | sort -u | awk '{ print $2 }' | sort | uniq -c | sort -rn | head -10
```

---

## 🧑‍🏫 Modo docente

**Preguntas:** ¿Por qué una IP en logs SSH + web es más peligrosa que una solo en web? ¿Qué falso positivo puede dar un score alto?
**Ejercicio:** Calcular el score de amenaza de las top 5 IPs y decidir acción para cada una.
**Evaluación:** correlación correcta de fuentes, justificación del bloqueo, rollback preparado.

---

## 🧪 Cómo practicarlo en el lab

```bash
cd labs && docker compose -f docker-compose.security.yml up -d sec-attacker sec-ssh-weak web-outdated
# Generar actividad maliciosa desde el contenedor atacante
docker exec sec-attacker nmap -sS sec-ssh-weak web-outdated
docker logs sec-ssh-weak 2>&1 | grep "Failed password"
```

[Ver laboratorio completo →](../../labs/README.md)

---

## 🔗 Referencias

- [`guides/grep.md`](../../guides/grep.md) — extracción con `-oP`
- [`guides/awk.md`](../../guides/awk.md) — arrays y formateo
- [`guides/sort.md`](../../guides/sort.md) + [`guides/uniq.md`](../../guides/uniq.md) — conteo
- [`guides/iptables.md`](../../guides/iptables.md) — bloqueo de IPs
- [`guides/xargs.md`](../../guides/xargs.md) — ejecutar comandos en lote
