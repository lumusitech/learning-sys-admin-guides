# 🧩 Escenario: Errores CORS — API bloqueada por política de origen cruzado

**Dominio:** web
**Nivel:** 🟡 Intermedio
**Herramientas:** `curl`, `nginx`, `journalctl`, `browser devtools`
**Archivos:** Sistema en vivo

---

## 🎯 Problema

Los usuarios reportan que la aplicación web no puede comunicarse con la API. El navegador muestra errores como "has been blocked by CORS policy" o "No 'Access-Control-Allow-Origin' header is present". La API funciona bien desde curl o Postman, pero el navegador la bloquea. El frontend y la API están en dominios o puertos diferentes.

---

## ⚡ Quick command (SRE)

```bash
curl -s -o /dev/null -D - -H "Origin: http://frontend.local" http://api.local/endpoint
```

---

## ✅ Salida esperada

- `curl` con `Origin` header no devuelve `Access-Control-Allow-Origin` → CORS no configurado
- `curl` con `Origin` header devuelve `Access-Control-Allow-Origin: *` → CORS abierto
- `curl` OPTIONS (preflight) devuelve 405 o sin headers CORS → preflight no soportado
- el navegador bloquea la respuesta → la política CORS está rechazando la solicitud

Interpretación:

- sin header `Access-Control-Allow-Origin` → el servidor no permite requests cross-origin
- `Access-Control-Allow-Origin: *` → permite cualquier origen (puede ser inseguro)
- `Access-Control-Allow-Origin: http://frontend.local` → solo permite ese origen específico
- preflight OPTIONS devuelve 405 → el servidor no maneja solicitudes OPTIONS

---

## 🧠 Diagnóstico

CORS (Cross-Origin Resource Sharing) es un mecanismo de seguridad del navegador que bloquea requests a un dominio diferente al que sirvió la página. Para permitirlo, el servidor debe incluir headers CORS específicos en la respuesta.

Patrones clave:

- la API funciona con curl pero no desde el navegador → CORS bloqueando
- el navegador muestra "blocked by CORS policy" → falta configuración CORS en el servidor
- las solicitudes POST complejas fallan pero GET funcionan → preflight OPTIONS no soportado
- `Access-Control-Allow-Origin` no incluye el dominio del frontend → origen no permitido
- los headers personalizados no se envían → falta `Access-Control-Allow-Headers`

👉 Si curl funciona pero el navegador no, el problema es CORS.

---

## 🛠️ Procedimiento (runbook)

### 1. Verificar headers CORS en la respuesta

```bash
curl -s -D - -H "Origin: http://frontend.local" http://api.local/endpoint | head -20
```

### 2. Probar preflight OPTIONS

```bash
curl -s -D - -X OPTIONS -H "Origin: http://frontend.local" -H "Access-Control-Request-Method: POST" http://api.local/endpoint
```

### 3. Verificar configuración de nginx

```bash
grep -r "add_header.*Access-Control" /etc/nginx/
```

### 4. Verificar configuración de la aplicación

```bash
grep -r "cors\|CORS\|Access-Control" /etc/app/ /opt/app/
```

### 5. Ver logs de nginx para requests OPTIONS

```bash
grep "OPTIONS" /var/log/nginx/access.log | tail -10
```

---

## 🧯 Mitigación

Si se confirma que CORS está bloqueando:

Verificar:

```bash
curl -s -D - -H "Origin: http://frontend.local" http://api.local/endpoint | grep -i "access-control"
```

Acción:

```bash
# Configurar headers CORS en nginx
# En el bloque server o location de la API:
# add_header 'Access-Control-Allow-Origin' 'http://frontend.local';
# add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS';
# add_header 'Access-Control-Allow-Headers' 'Content-Type, Authorization';

# Recargar nginx
nginx -t && nginx -s reload
```

Mitigación adicional:

```bash
# Para desarrollo, permitir cualquier origen (NO en producción)
# add_header 'Access-Control-Allow-Origin' '*';

# Manejar preflight OPTIONS
# if ($request_method = 'OPTIONS') {
#     add_header 'Access-Control-Allow-Origin' 'http://frontend.local';
#     add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS';
#     add_header 'Access-Control-Allow-Headers' 'Content-Type, Authorization';
#     add_header 'Access-Control-Max-Age' 86400;
#     return 204;
# }
```

Rollback:

```bash
# Eliminar headers CORS de la configuración
# Recargar nginx
nginx -t && nginx -s reload
```

Casos comunes:

- frontend en localhost:3000, API en localhost:8080 → diferentes puertos = diferente origen
- frontend en HTTPS, API en HTTP → mixed content + CORS
- API sin headers CORS → el navegador bloquea todas las solicitudes
- preflight OPTIONS no soportado → solicitudes POST/PUT/DELETE fallan
- `Access-Control-Allow-Origin: *` con credenciales → el navegador rechaza (incompatible)

---

## ✅ Interpretación

- los headers CORS aparecen en la respuesta → el servidor está configurado correctamente
- el preflight OPTIONS devuelve 204 → el servidor maneja solicitudes preflight
- el navegador deja de mostrar errores CORS → la configuración es correcta
- los headers CORS no aparecen → la configuración no se aplicó (revisar nginx -t)

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

**Preguntas:** ¿Por qué los errores CORS no se detectan con curl? ¿Qué header HTTP habilita CORS? ¿Qué método HTTP usa el preflight?

**Ejercicio:** Simular petición cross-origin con curl, identificar headers faltantes, configurar CORS en nginx, verificar con preflight OPTIONS.

**Evaluación:** comprensión de por qué curl no reproduce el error, configuración correcta de headers CORS, manejo del preflight.

---

## 🔗 Referencias

- [`nginx`](../../guides/nginx.md) — configuración y logs de nginx
- [`curl`](../../guides/curl.md) — inspección de respuestas HTTP
- [`scenarios/web/01-performance-and-error-analysis.md`](01-performance-and-error-analysis.md) — análisis de rendimiento web
- [`scenarios/web/02-nginx-5xx-errors.md`](02-nginx-5xx-errors.md) — errores 5xx
