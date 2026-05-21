# 🧩 Escenario: Analizar patrones de tráfico web

**Dominio:** networking
**Nivel:** 🟢 Básico
**Herramientas:** `awk`, `grep`, `sort`, `uniq`, `head`, `cut`
**Archivos:** `labs/nginx_access.log`

---

## 🎯 Objetivo

1. Extraer las rutas más solicitadas y los códigos de estado HTTP.
2. Detectar crawlers, escaneo de rutas y fuentes de tráfico anómalo.
3. Reportar IPs con comportamiento sospechoso.

---

## 🧠 Contexto

El servidor web está lento. Necesitamos entender qué rutas se solicitan más, qué códigos de estado predominan, y detectar patrones de tráfico anómalo como ataques o crawlers abusivos.

---

## ✅ Datos de entrada

- **Producción:** `/var/log/nginx/access.log` (o Apache)
- **Práctica:** `labs/nginx_access.log`

---

## ⚡ Quick run (top 10 rutas más solicitadas)

```bash
awk '{ print $7 }' labs/nginx_access.log | sort | uniq -c | sort -rn | head -10
```

---

## 🔍 Paso a paso

1. `awk '{ print $7 }'` → extrae la ruta URL
2. `sort` → ordena alfabéticamente (necesario para uniq)
3. `uniq -c` → cuenta ocurrencias de cada ruta
4. `sort -rn` → ordena descendente por frecuencia
5. `head -10` → top 10

---

## ✅ Salida esperada

```
150 /index.html
 89 /api/usuarios
 45 /productos/123
```

- Ruta `/` con muchas más requests que las demás → normal
- Rutas con 404 alto y nombres aleatorios → escaneo
- Ruta `/admin` o `/wp-admin` con intentos → ataque

---

## 📌 Pipelines de diagnóstico

### Códigos de estado HTTP

```bash
awk '{ print $9 }' labs/nginx_access.log | sort | uniq -c | sort -rn \
| awk '{ if($2 ~ /^2/)c="2xx - Éxito"; else if($2 ~ /^3/)c="3xx - Redirección"; else if($2 ~ /^4/)c="4xx - Error cliente"; else if($2 ~ /^5/)c="5xx - Error servidor"; else c="Otro"; print $1, $2, c }'
```

### Detectar crawlers por User-Agent

```bash
awk '{ print $1, $NF }' labs/nginx_access.log | grep -iE "bot|crawler|spider|scanner" | sort | uniq -c | sort -rn | head -15
```

### Peticiones por hora

```bash
awk '{ split($4,t,"[/:]"); h=t[4]; horas[h]++ } END { for(h in horas) printf "%02d:00 %d\n", h, horas[h] }' labs/nginx_access.log | sort
```

### Detectar escaneo de rutas (404 desde misma IP)

```bash
awk '$9==404{print $1,$7}' labs/nginx_access.log | sort | uniq -c | sort -rn | awk '$1>3{print $2,$3,$1}' | head -20
```

### Ancho de banda por IP

```bash
awk '{ ips[$1] += $10 } END { for(i in ips) printf "%d %s\n", ips[i], i }' labs/nginx_access.log | sort -rn | head -10
```

### Tasa de errores por minuto

```bash
awk '{ split($4,t,"[/:]"); m=t[4]":"t[5]; total[m]++; if($9~/^[45]/) error[m]++ }
END { for(m in total) printf "%s %d %.1f%%\n", m, error[m], (error[m]/total[m])*100 }' labs/nginx_access.log | sort | head -20
```

### Sesiones por IP (IP + User-Agent únicos)

```bash
awk '{ print $1, $NF }' labs/nginx_access.log | sort -u | cut -d' ' -f1 | sort | uniq -c | sort -rn | head -10
```

---

## 🧯 Mitigación

| Señal | Acción |
|-------|--------|
| Una IP con 404 masivos | Bloquear IP temporalmente |
| Crawler sin respetar robots.txt | Rate limiting o bloquear User-Agent |
| Tráfico fuera de horario (3am) | Investigar si es backup legítimo o ataque |
| Una IP con >100 req/min | Rate limiting |

⚠️ Verificá antes de bloquear: podés estar bloqueando un monitor legítimo o un proxy CDN.

---

## 🛡️ Prevención

- [ ] Configurar rate limiting por IP en nginx (`limit_req_zone`)
- [ ] Bloquear User-Agents maliciosos conocidos
- [ ] Monitorear picos anómalos con alertas
- [ ] Usar CDN/WAF (Cloudflare, AWS Shield)

---

## 🧪 Variantes

### En tiempo real (ataque activo)

```bash
tail -f /var/log/nginx/access.log | awk '{ print $1, $7 }'
```

### Por ventana de 5 minutos

```bash
awk '{ split($4,t,"[/:]"); m=t[4]":"int(t[5]/5)*5; req[m]++ } END { for(m in req) print m, req[m] }' labs/nginx_access.log | sort | head -20
```

---

## 🧑‍🏫 Modo docente

**Preguntas:** ¿Qué diferencia hay entre 200 y 304? ¿Cómo identificás un crawler legítimo de uno malicioso?
**Ejercicio:** Encontrar IPs que piden rutas que no existen y clasificar la severidad.
**Evaluación:** pipeline correcto, interpretación acertada, mitigación justificada.

---

## 🧪 Cómo practicarlo en el lab

```bash
cd labs && docker compose up -d web-nginx
# Simular tráfico y escaneo
curl -s localhost:8080/ && curl -s localhost:8080/admin && curl -s localhost:8080/backup.zip
# Ver logs en tiempo real
docker logs web-nginx 2>&1 | tail -10
```

[Ver laboratorio completo →](../../labs/README.md)

---

## 🔗 Referencias

- [`guides/awk.md`](../../guides/awk.md) — arrays asociativos
- [`guides/grep.md`](../../guides/grep.md) — filtrado con `-iE`
- [`guides/sort.md`](../../guides/sort.md) + [`guides/uniq.md`](../../guides/uniq.md) — conteo de frecuencias
- [`guides/nginx.md`](../../guides/nginx.md) — rate limiting y logs
