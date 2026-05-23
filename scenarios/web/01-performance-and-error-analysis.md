⬅️ [Volver a scenarios](../README.md)

# 🧩 Escenario: Análisis de rendimiento y errores web

**Dominio:** web
**Nivel:** 🟡 Intermedio
**Herramientas:** `awk`, `grep`, `sort`, `uniq`, `bc`, `sed`
**Archivos:** `labs/nginx_access.log`

---

## 🎯 Problema

Se detectan problemas de rendimiento y errores HTTP en el servidor web que afectan la experiencia de los usuarios. Es necesario analizar los accesos para:

- identificar rutas lentas, picos de tráfico y códigos de error HTTP
- detectar crawlers abusivos, escaneo de rutas y hotlinking
- generar reportes de rendimiento para tomar acciones correctivas

---

## ⚡ Quick command (SRE)

`awk '{t++; if($9 ~ /^[45]/) e++} END{printf "total=%d errores_4xx5xx=%d tasa=%.2f%%\n", t, e, (t? (e*100)/t : 0)}' labs/nginx_access.log`

---

## 🧠 Contexto

El sitio web responde lento y los usuarios reportan errores. Los logs del servidor web (Apache/Nginx) contienen la información necesaria para diagnosticar la causa.

---

## ✅ Datos de entrada

- **Producción:** `/var/log/nginx/access.log` o `/var/log/apache2/access.log`
- **Práctica:** `labs/nginx_access.log`

---

## ⚡ Quick run (top 10 rutas más lentas)

```bash
awk '{ print $NF, $7 }' labs/nginx_access.log | sort -rn | head -10 | awk '{ printf "%6.3fs %s\n", $1, $2 }'
```

---

## 🔍 Paso a paso

1. `awk '{ print $NF, $7 }'` → extrae tiempo de respuesta (último campo) y ruta (campo 7)
2. `sort -rn` → ordena descendente por tiempo
3. `head -10` → top 10
4. `awk '{ printf ... }'` → formatea la salida

---

## ✅ Salida esperada

```
 5.234s /api/reportes
 3.102s /productos/123
 0.892s /index.html
```

Interpretación:

- tasas altas de 4xx → errores de cliente (rutas inválidas o bots)
- aumento de 5xx → fallo del backend o dependencia
- endpoints con alta latencia → cuello de botella en aplicación o DB

---

## 🧠 Diagnóstico

El rendimiento web debe evaluarse combinando errores y tiempos de respuesta.

Patrones relevantes:

- tasa de errores >1–2% → posible problema de servicio o backend
- tiempos de respuesta altos en endpoints específicos → cuello de botella (DB o lógica)
- picos de tráfico → posible sobrecarga o ataque
- aumento de 5xx → fallo del backend o dependencia

👉 No todos los errores indican fallo crítico: el patrón, frecuencia y concentración definen el impacto.

---

## 🛠️ Validación extendida

### Peticiones por minuto (tráfico)

```bash
awk '{ split($4,t,"[/:]"); minuto=t[4]":"t[5]; req[minuto]++ }
END { for (m in req) print m, req[m] }' labs/nginx_access.log \
| sort | head -30
```

### Tasa de errores 4xx/5xx

```bash
TOTAL=$(wc -l < labs/nginx_access.log)
ERRORES=$(awk '$9 ~ /^[45]/' labs/nginx_access.log | wc -l)
echo "Total: $TOTAL | Errores: $ERRORES | Tasa: $(echo "scale=2; $ERRORES*100/$TOTAL" | bc)%"
```

### Códigos HTTP con descripción

```bash
awk '{ print $9 }' labs/nginx_access.log | sort | uniq -c | sort -rn \
| awk '{code=$2; if(code==200)desc="OK"; else if(code==404)desc="Not Found"; else if(code==500)desc="Internal Error"; else if(code==502)desc="Bad Gateway"; else if(code==503)desc="Service Unavailable"; else if(code==301)desc="Redirect"; else if(code==403)desc="Forbidden"; else if(code==429)desc="Rate Limited"; else desc="Other"; printf "%-3s %-20s %s\n", code, desc, $1}'
```

### User-Agents: bots vs reales

```bash
echo "=== BOTS ==="
awk '{ print $NF }' labs/nginx_access.log | grep -iE "bot|crawler|spider" | sort | uniq -c | sort -rn | head -5
echo "=== NAVEGADORES ==="
awk '{ print $NF }' labs/nginx_access.log | grep -viE "bot|crawler|spider|curl|wget|python" | sort | uniq -c | sort -rn | head -5
```

### Picos anómalos de tráfico

```bash
awk '{ split($4,t,"[/:]"); m=t[4]":"t[5]; req[m]++ }
END { for(m in req){ total+=req[m]; c++ } avg=total/c; for(m in req) if(req[m]>avg*2) print "PICO:", m, req[m], "(promedio:", int(avg) ")" }' \
labs/nginx_access.log | sort
```

### Ancho de banda por ruta

```bash
awk '{ r=$7; bytes[r]+=$10 } END { for(r in bytes) if(bytes[r]>1048576) printf "%.2f MB %s\n", bytes[r]/(1024*1024), r }' \
labs/nginx_access.log | sort -rn | head -10
```

---


## 🧯 Mitigación

Ejemplo: high latency en endpoint

```bash
systemctl restart <servicio>
```

Verificar:

```bash
curl -I <url>
```

Rollback:

```bash
systemctl restart <servicio_anterior>
```

Casos comunes:

- rutas lentas → optimizar backend o cache
- errores 5xx → revisar upstream o reiniciar servicio
- rate limiting → bloquear IP o ajustar nginx

---

## 🛡️ Prevención

- [ ] Cache nginx para rutas estáticas
- [ ] Rate limiting por IP: `limit_req_zone`
- [ ] Monitorear con netdata/grafana
- [ ] Alertas cuando 5xx > 1%
- [ ] Rotar logs con logrotate

---

## 🧪 Variantes

### En tiempo real

```bash
tail -f /var/log/nginx/access.log | awk '{ print $NF, $7 }'
```

### Por endpoint específico

```bash
awk '$7 ~ /api/' labs/nginx_access.log | awk '{ print $NF }' | sort -rn | head -5
```

---

## 🧑‍🏫 Modo docente

**Preguntas:** ¿Qué indica un aumento de 502? ¿Cómo diferenciar un crawler de un usuario real?
**Ejercicio:** Encontrar la ruta que más ancho de banda consume y proponer una solución.
**Evaluación:** pipeline correcto, interpretación correcta, mitigación segura.

---

## 🧪 Cómo practicarlo en el lab

```bash
cd labs && docker compose up -d web-nginx
# Generar tráfico simulado
for i in $(seq 1 100); do curl -s localhost:8080/$i >/dev/null; done
# Ver logs en tiempo real
docker logs web-nginx 2>&1 | tail -20
```

[Ver laboratorio completo →](../../labs/README.md)

---

## 🔗 Referencias

- [`guides/awk.md`](../../guides/awk.md) — arrays, split, acumuladores
- [`guides/grep.md`](../../guides/grep.md) — filtrado por patrón
- [`guides/sort.md`](../../guides/sort.md) + [`guides/uniq.md`](../../guides/uniq.md) — frecuencias
- [`guides/nginx.md`](../../guides/nginx.md) — rate limiting, cache, optimización
