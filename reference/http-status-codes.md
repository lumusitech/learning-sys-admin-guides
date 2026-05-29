# Códigos de estado HTTP — Referencia rápida

Resumen de códigos HTTP para troubleshooting de aplicaciones web.

---

## 🔵 2xx — Éxito

| Código | Significado | Cuándo aparece en troubleshooting |
|--------|-------------|-----------------------------------|
| 200 | OK | Respuesta normal. Si esperabas un error, revisá la lógica de la app |
| 201 | Created | Recurso creado correctamente (POST). Normal en APIs |
| 204 | No Content | Request exitoso sin cuerpo de respuesta (DELETE). Normal |
| 206 | Partial Content | Descarga parcial (range request). Normal en streaming/video |

---

## 🟡 3xx — Redirección

| Código | Significado | Cuándo aparece en troubleshooting |
|--------|-------------|-----------------------------------|
| 301 | Moved Permanently | La URL cambió definitivamente. Revisar si es intencional o un error de configuración |
| 302 | Found (redirect temporal) | Redirección temporal. Normal en logins, sospechoso si es constante |
| 304 | Not Modified | Usa caché del navegador. Normal, indica que el recurso no cambió |
| 307 | Temporary Redirect | Similar a 302 pero mantiene el método HTTP. Normal en redirecciones POST |

Problemas comunes con 3xx:

- bucle de redirección → el navegador rebota entre dos URLs sin llegar a destino
- HTTPS redirect mal configurado → redirect a HTTP en lugar de HTTPS

---

## 🟠 4xx — Error del cliente

| Código | Significado | Cuándo aparece en troubleshooting |
|--------|-------------|-----------------------------------|
| 400 | Bad Request | Request mal formado. Revisar payload, headers, sintaxis. Generalmente bug del cliente |
| 401 | Unauthorized | Falta autenticación o el token expiró. Revisar headers `Authorization` |
| 403 | Forbidden | Autenticado pero sin permiso. Revisar reglas de acceso, IP bloqueada, WAF |
| 404 | Not Found | URL inexistente. Revisar ruta, si el recurso fue movido o eliminado |
| 405 | Method Not Allowed | Método HTTP no soportado para esa URL (ej: PUT en ruta GET-only) |
| 408 | Request Timeout | El cliente no envió el request completo a tiempo. Posible red lenta o cliente mal configurado |
| 409 | Conflict | Estado conflictivo (ej: recurso duplicado). Normal en REST si se intenta crear algo existente |
| 413 | Payload Too Large | Request excede el límite de tamaño. Revisar `client_max_body_size` en nginx |
| 429 | Too Many Requests | Rate limiting activo. Revisar límites de API o firewall, quizás el cliente está siendo muy agresivo |
| 499 | Client Closed Request | (nginx) El cliente cerró la conexión antes de recibir respuesta. Timeout del lado cliente |

Problemas comunes con 4xx:

- 403 sin razón clara → revisar WAF, reglas de IP, `.htaccess` o config de nginx
- 404 en rutas que deberían existir → revisar document root, symlinks, rewrite rules
- 429 seguido → cliente está siendo rate-limited, revisar si es tráfico legítimo o scraping

---

## 🔴 5xx — Error del servidor

| Código | Significado | Cuándo aparece en troubleshooting |
|--------|-------------|-----------------------------------|
| 500 | Internal Server Error | Error genérico del servidor. Revisar logs de la app, no hay más pista que esa |
| 502 | Bad Gateway | El upstream (app server, PHP-FPM, uWSGI) respondió inválido. Upstream caído o mal configurado |
| 503 | Service Unavailable | Servidor temporalmente no disponible (mantenimiento, sobrecarga). Revisar health checks |
| 504 | Gateway Timeout | Upstream no respondió a tiempo. Timeout de conexión entre nginx y app server |
| 505 | HTTP Version Not Supported | Versión HTTP no soportada. Raro, ocurre con proxies viejos |

Problemas comunes con 5xx:

- 502 intermitente → upstream reiniciándose, pool de conexiones agotado, OOM matando workers
- 503 constante → maintenance mode activo o health check fallando
- 504 lento pero eventualmente responde → ajustar `proxy_read_timeout` en nginx
- 500 sin logs → revisar permisos de escritura de logs, quizás la app no puede loguear el error

---

## 🔍 Cómo usarlo en diagnóstico

```bash
# Ver código de respuesta rápido
curl -s -o /dev/null -w "%{http_code}" https://ejemplo.com/api

# Ver headers completos (incluye código)
curl -I https://ejemplo.com

# Ver código + tiempo total
curl -s -o /dev/null -w "HTTP %{http_code} — %{time_total}s\n" https://ejemplo.com

# Seguir redirecciones y ver cada código intermedio
curl -IL https://ejemplo.com

# Ver errores 5xx en access log de nginx
awk '$9 ~ /^5/ {print $9, $7, $1}' /var/log/nginx/access.log | sort | uniq -c | sort -rn

# Contar distribución de códigos en access log
awk '{print $9}' /var/log/nginx/access.log | sort | uniq -c | sort -rn
```

---

## 🔗 Ver también

- [`curl`](../guides/curl.md) — cómo inspeccionar respuestas HTTP
- [`nginx`](../guides/nginx.md) — configuración y logs de nginx
- [`scenarios/web/01-performance-and-error-analysis.md`](../scenarios/web/01-performance-and-error-analysis.md) — análisis de rendimiento y errores web
- [`scenarios/web/02-nginx-5xx-errors.md`](../scenarios/web/02-nginx-5xx-errors.md) — troubleshooting de errores 5xx
