⬅️ ../README.md

# 🧩 Escenario: Detectar escaneo de puertos en logs de firewall

**Dominio:** networking / security  
**Nivel:** 🟡 Intermedio  
**Herramientas:** `awk`, `sort`, `uniq`, `iptables`  
**Archivos:** labs/firewall.log

---

## 🎯 Problema

Se sospecha que el servidor está siendo escaneado para detectar puertos abiertos.

Es necesario:

- identificar IPs sospechosas
- detectar patrones de escaneo
- determinar si la actividad es maliciosa

---

## ⚡ Quick command (SRE)

`awk '{for(i=1;i<=NF;i++) if($i ~ /^SRC=/){ip=$i; sub(/^SRC=/,"",ip); c[ip]++}} END{for(ip in c) print c[ip], ip}' labs/firewall.log | sort -rn | head -10`

---

## 🔍 Señales clave

Al ejecutar el comando:

- IPs con gran cantidad de eventos → sospechoso
- una IP dominante → posible atacante
- muchas IPs con pocos eventos → escaneo distribuido

---

## 🧠 Diagnóstico

Un escaneo de puertos suele presentar:

- acceso a múltiples puertos en poco tiempo
- repeticiones rápidas desde la misma IP
- paquetes SYN sin completar handshake

👉 Esto indica fase de reconocimiento (recon) previa a un ataque real

---

## 🛠️ Validación extendida

### Ver puertos escaneados por IP sospechosa

```bash
IP_SOSPE="10.0.0.5"
grep "SRC=$IP_SOSPE" labs/firewall.log \
| awk '{for(i=1;i<=NF;i++) if($i ~ /^DPT=/) print substr($i,5)}' \
| sort -n | uniq
```

### Detectar SYN scan (SYN sin ACK)

```bash
grep "SYN" labs/firewall.log | grep -v "ACK" \
| awk '{for(i=1;i<=NF;i++) if($i ~ /^SRC=/) print substr($i,5)}' \
| sort | uniq -c | sort -rn
```

### Puertos más escaneados

```bash
awk '{for(i=1;i<=NF;i++) if($i ~ /^DPT=/) print substr($i,5)}' \
labs/firewall.log | sort | uniq -c | sort -rn | head -10
```

---

## ✅ Salida esperada

```bash
 150 10.0.0.5
 89 203.0.113.45
 45 192.168.1.200
```

Interpretación:

- una IP con muchos más eventos → probable atacante
- valores similares → tráfico más distribuido

---

## ✅ Solución

Bloquear IP sospechosa:

```bash
iptables -A INPUT -s 10.0.0.5 -j DROP
```

Verificar:

```bash
iptables -L INPUT -v -n | grep 10.0.0.5
```

Rollback:

```bash
iptables -D INPUT -s 10.0.0.5 -j DROP
```

---

## ⚠️ Errores comunes

- confundir tráfico legítimo con escaneo
- bloquear sin validar patrones completos
- bloquear IP propia (muy común en labs)
- analizar solo cantidad y no tipo de tráfico

---

## 🛡️ Prevención

- cerrar puertos innecesarios
- usar fail2ban
- aplicar rate limiting (iptables -m limit)
- monitorear logs periódicamente

---

## 🧪 Cómo practicarlo

```bash
cd labs && docker compose -f docker-compose.security.yml up -d sec-attacker

docker exec sec-attacker nmap -sS 10.99.0.0/24
```

---

## 🧑‍🏫 Modo docente

**Preguntas:** ¿Cómo diferenciás un escaneo horizontal de uno vertical? ¿Qué campo del log de iptables indica el puerto destino? ¿Cómo bloquearías la IP atacante?

**Ejercicio:** Analizar logs de iptables para detectar un IP escaneando múltiples puertos, clasificar el ataque, bloquear la IP.

**Evaluación:** identificación correcta del patrón de escaneo, clasificación del tipo, bloqueo efectivo con iptables.

---

## 🔗 Ver también

- ../../guides/awk.md
- ../../guides/iptables.md
- ../../guides/tcpdump.md
- ../../concepts/how-to-think-like-sysadmin.md
