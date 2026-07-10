# 🧩 Escenario: 502 Bad Gateway — backend caído o timeout

**Dominio:** web
**Nivel:** 🟡 Intermedio
**Herramientas:** `curl`, `nginx`, `ps`, `journalctl`, `strace`
**Archivos:** Sistema en vivo

---

## 🎯 Problema

Los usuarios reportan errores 502 Bad Gateway al acceder a la aplicación. Nginx no puede comunicarse con el backend (PHP-FPM, uWSGI, Gunicorn, Node.js). El problema puede ser que el backend está caído, no responde a tiempo, o nginx está configurado con un upstream incorrecto.

---

## ⚡ Quick command (SRE)

```bash
curl -s -o /dev/null -w "HTTP %{http_code} — %{time_total}s\n" http://localhost/
```

---

## ✅ Salida esperada

- `curl` devuelve 502 Bad Gateway → nginx no pudo conectar con el backend
- nginx error log muestra `connect() failed` o `upstream timed out` → el backend no responde
- el proceso del backend no está corriendo → el servicio está caído
- el proceso del backend está corriendo pero no escucha en el puerto esperado → configuración incorrecta

Interpretación:

- `connect() failed (111: Connection refused)` → el backend no está corriendo o no escucha en ese puerto
- `upstream timed out (110: Connection timed out)` → el backend no responde a tiempo
- `no live upstreams` → todos los backends están caídos
- el backend está corriendo pero en puerto diferente → nginx apunta al puerto incorrecto

---

## 🧠 Diagnóstico

Un 502 Bad Gateway significa que nginx actuó como proxy inverso pero el backend no respondió correctamente. La causa más común es que el servicio backend (PHP-FPM, uWSGI, Gunicorn, Node.js) está caído o no escucha en el puerto que nginx espera.

Patrones clave:

- `connect() failed (111)` → el backend no está corriendo
- `upstream timed out (110)` → el backend está sobrecargado o colgado
- `no live upstreams` → todos los backends del pool están caídos
- el backend está corriendo pero en puerto diferente → desconfiguración
- el backend responde pero nginx no lo reconoce → problema de socket o bind address

👉 Si nginx devuelve 502, el primer paso es verificar si el backend está corriendo.

---

## 🛠️ Procedimiento (runbook)

### 1. Verificar el código de respuesta

```bash
curl -v http://localhost/ 2>&1 | grep -E "HTTP|502"
```

### 2. Ver logs de nginx

```bash
tail -20 /var/log/nginx/error.log
```

### 3. Verificar si el backend está corriendo

```bash
ps aux | grep -E "php-fpm|uwsgi|gunicorn|node|python"
```

### 4. Verificar en qué puerto escucha el backend

```bash
ss -tlnp | grep -E "9000|8000|3000|5000"
```

### 5. Verificar la configuración de upstream en nginx

```bash
grep -r "proxy_pass\|fastcgi_pass\|uwsgi_pass" /etc/nginx/
```

---

## 🧯 Mitigación

Si se confirma que el backend está caído:

Verificar:

```bash
ps aux | grep -E "php-fpm|uwsgi|gunicorn|node"
ss -tlnp | grep -E "9000|8000|3000|5000"
```

Acción:

```bash
# Reiniciar el servicio backend
systemctl restart php-fpm
# o
systemctl restart gunicorn
# o
systemctl restart uwsgi

# Verificar que el servicio arrancó
systemctl status php-fpm
```

Mitigación adicional:

```bash
# Si el backend muere por OOM, verificar memoria
free -h
dmesg | grep -i oom

# Si el backend muere por error de código, revisar logs
journalctl -u php-fpm --since "1 hour ago" | tail -30

# Si el problema es el puerto, verificar configuración
nginx -t
```

Rollback:

```bash
# Si el backend no arranca, restaurar configuración anterior
# Restaurar backup de la configuración del servicio
systemctl restart <servicio>
```

Casos comunes:

- PHP-FPM se cayó por OOM → aumentar memory_limit o agregar swap
- Gunicorn se cayó por error de código → revisar logs de la aplicación
- uWSGI no escucha en el puerto correcto → verificar configuración de socket
- Node.js se cayó por unhandled exception → revisar logs de la aplicación
- nginx apunta a puerto incorrecto → verificar `fastcgi_pass` o `proxy_pass`

---

## ✅ Interpretación

- el backend arranca y nginx responde 200 → el problema era el servicio caído
- el backend arranca pero sigue 502 → nginx apunta al puerto o socket incorrecto
- el backend muere inmediatamente tras reiniciar → hay un error en el código o configuración
- el backend responde pero muy lento → posible timeout de nginx, ajustar `proxy_read_timeout`

---

## 🐧 Variante Alpine (OpenRC)

> Este escenario usa `systemctl` y `journalctl`.

### Variante B — systemctl + journalctl

```bash
# Debian:                          # Alpine:
systemctl restart php-fpm          rc-service php-fpm restart
systemctl status php-fpm           rc-service php-fpm status
journalctl -u php-fpm --since "1h" logread | grep php-fpm | tail -20
```

---

## 🧑‍🏫 Modo docente

**Preguntas:** ¿Qué significa exactamente 502 Bad Gateway? ¿Cómo verificás que el upstream (PHP-FPM, Gunicorn, etc.) está corriendo? ¿Dónde mirás logs del backend?

**Ejercicio:** Diagnosticar un 502: verificar si el upstream está vivo, revisar configuración de proxy_pass, revisar logs del backend.

**Evaluación:** diagnóstico metódico (upstream -> config -> logs), identificación de la causa raíz, restauración del servicio.

---

## 🔗 Referencias

- [`nginx`](../../guides/nginx.md) — configuración y logs de nginx
- [`curl`](../../guides/curl.md) — inspección de respuestas HTTP
- [`scenarios/web/01-performance-and-error-analysis.md`](01-performance-and-error-analysis.md) — análisis de rendimiento web
- [`scenarios/web/02-nginx-5xx-errors.md`](02-nginx-5xx-errors.md) — errores 5xx
