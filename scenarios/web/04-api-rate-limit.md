# 🧩 Escenario: API rate-limited — usuario legítimo bloqueado

**Dominio:** web
**Nivel:** 🟡 Intermedio
**Herramientas:** `curl`, `nginx`, `journalctl`, `ab`
**Archivos:** Sistema en vivo

---

## 🎯 Problema

Un usuario o integración legítima reporta que la API devuelve errores 429 (Too Many Requests). El usuario no está haciendo un ataque — es un cliente normal que hace requests dentro de lo esperado. El rate limiting de nginx está demasiado agresivo o mal configurado, bloqueando tráfico legítimo.

---

## ⚡ Quick command (SRE)

```bash
curl -s -o /dev/null -w "HTTP %{http_code}\n" -H "X-Forwarded-For: <ip_cliente>" http://localhost/api/endpoint
```

---

## ✅ Salida esperada

- `curl` devuelve 429 Too Many Requests → rate limiting activo
- nginx error log muestra `limiting requests, excess` → el cliente excedió el límite
- la respuesta incluye header `Retry-After` → indica cuándo reintentar
- el cliente hace < 10 requests/segundo → el límite es demasiado bajo para su uso

Interpretación:

- 429 en requests legítimas → el rate limit está demasiado bajo
- 429 solo en ciertos endpoints → el rate limit es específico de esa zona
- 429 solo desde ciertas IPs → posible whitelist necesaria
- nginx muestra `limiting requests` en error log → el rate limit se está aplicando

---

## 🧠 Diagnóstico

El rate limiting protege la API de abuso, pero si está mal configurado puede bloquear usuarios legítimos. La clave es distinguir entre tráfico legítimo (que necesita más requests) y tráfico malicioso (que necesita ser bloqueado).

Patrones clave:

- usuario legítimo con 429 → el rate limit es demasiado bajo para su caso de uso
- integración con 429 → la integración hace más requests de las permitidas
- 429 solo en horario pico → el rate limit no considera la carga normal
- 429 desde CDN o proxy → todas las requests vienen de la misma IP
- nginx `limit_req_zone` con zona muy pequeña → el bucket se llena rápido

👉 Si un usuario legítimo recibe 429, el rate limit necesita ajuste, no el usuario.

---

## 🛠️ Procedimiento (runbook)

### 1. Verificar que el cliente recibe 429

```bash
curl -v http://localhost/api/endpoint 2>&1 | grep -E "HTTP|429|Retry-After"
```

### 2. Ver logs de rate limiting en nginx

```bash
grep "limiting requests" /var/log/nginx/error.log | tail -20
```

### 3. Ver la configuración actual de rate limiting

```bash
grep -r "limit_req" /etc/nginx/
```

### 4. Probar el rate limit con Apache Bench

```bash
ab -n 100 -c 10 http://localhost/api/endpoint 2>&1 | grep -E "Complete requests|Failed requests|Non-2xx"
```

### 5. Verificar si el cliente está en una zona compartida (CDN, proxy)

```bash
# Si el cliente pasa por CDN, todas las requests vienen de la misma IP
# Verificar X-Forwarded-For
curl -H "X-Forwarded-For: <ip_real>" http://localhost/api/endpoint
```

---

## 🧯 Mitigación

Si se confirma que el rate limit está bloqueando usuarios legítimos:

Verificar:

```bash
grep -r "limit_req_zone" /etc/nginx/
curl -s -o /dev/null -w "%{http_code}\n" http://localhost/api/endpoint
```

Acción:

```bash
# Aumentar el rate limit en la configuración de nginx
# Ejemplo: cambiar de 10r/s a 50r/s
# limit_req_zone $binary_remote_addr zone=api:10m rate=50r/s;

# O aumentar el burst
# limit_req zone=api burst=100 nodelay;

# Recargar nginx
nginx -t && nginx -s reload
```

Mitigación adicional:

```bash
# Usar X-Forwarded-For en vez de IP directa (para clientes detrás de CDN)
# limit_req_zone $http_x_forwarded_for zone=api:10m rate=50r/s;

# O crear zona diferente para IPs de confianza
# map $http_x_forwarded_for $limit_key {
#   default $http_x_forwarded_for;
#   "" $remote_addr;
# }
```

Rollback:

```bash
# Restaurar configuración original de nginx
# Recargar nginx
nginx -t && nginx -s reload
```

Casos comunes:

- integración que hace polling frecuente → aumentar rate limit para esa IP
- cliente detrás de CDN → todas las requests vienen de la misma IP
- endpoint público sin rate limit diferenciado → aplicar rate limit por usuario, no por IP
- rate limit demasiado bajo para el tráfico normal → ajustar según métricas reales

---

## ✅ Interpretación

- el usuario deja de recibir 429 tras ajustar rate limit → el límite era demasiado bajo
- el usuario sigue con 429 → el problema puede estar en otra capa (WAF, firewall)
- los 429 desaparecen al usar X-Forwarded-For → el problema era IP compartida
- los 429 son solo en ciertos endpoints → aplicar rate limit diferenciado

---

## 🐧 Variante Alpine (OpenRC)

> Este escenario usa `systemctl` y `journalctl`.

### Variante B — systemctl + journalctl

```bash
# Debian:                          # Alpine:
systemctl restart nginx            rc-service nginx restart
journalctl -u nginx --since "1h"   logread | grep nginx | tail -20
```

---

## 🧑‍🏫 Modo docente

**Preguntas:** ¿Cómo distinguís rate limiting de otro tipo de error HTTP? ¿Qué header revela la IP real del cliente detrás de un proxy? ¿Cómo ajustás burst sin abrir el throttle?

**Ejercicio:** Diagnosticar rate limiting en nginx, ajustar limit_req_zone para cliente legítimo, verificar con ab.

**Evaluación:** identificación del rate limit en logs, ajuste correcto de rate/burst, verificación con carga controlada.

---

## 🔗 Referencias

- [`nginx`](../../guides/nginx.md) — configuración y logs de nginx
- [`curl`](../../guides/curl.md) — inspección de respuestas HTTP
- [`scenarios/web/01-performance-and-error-analysis.md`](01-performance-and-error-analysis.md) — análisis de rendimiento web
- [`scenarios/web/02-nginx-5xx-errors.md`](02-nginx-5xx-errors.md) — errores 5xx
