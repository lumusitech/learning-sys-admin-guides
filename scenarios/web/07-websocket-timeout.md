# 🧩 Escenario: WebSocket timeouts — desconexiones frecuentes sin razón aparente

**Dominio:** web
**Nivel:** 🟡 Intermedio
**Herramientas:** `curl`, `nginx`, `tcpdump`, `journalctl`
**Archivos:** Sistema en vivo

---

## 🎯 Problema

Los usuarios reportan que la aplicación web con WebSockets se desconecta frecuentemente. Las conexiones WebSocket se caen después de 30-60 segundos de inactividad, obligando a reconectar. El chat en tiempo real, las notificaciones push o los dashboards live no funcionan de forma estable.

---

## ⚡ Quick command (SRE)

```bash
curl -s -o /dev/null -w "%{http_code}" -H "Upgrade: websocket" -H "Connection: Upgrade" -H "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" -H "Sec-WebSocket-Version: 13" http://localhost/ws
```

---

## ✅ Salida esperada

- `curl` devuelve 101 Switching Protocols → handshake WebSocket exitoso
- la conexión se mantiene abierta → WebSocket funciona
- después de 60 segundos sin tráfico, nginx cierra la conexión → timeout de proxy
- nginx error log muestra `upstream timed out` → el backend no responde a tiempo

Interpretación:

- 101 Switching Protocols → el handshake fue exitoso
- la conexión se cae tras inactividad → nginx proxy_read_timeout es muy bajo
- `upstream timed out` → el backend no responde, posible problema de configuración
- la conexión se cae tras exactamente 60 segundos → timeout default de nginx

---

## 🧠 Diagnóstico

Los WebSockets mantienen una conexión persistente entre cliente y servidor. Si hay un proxy (nginx) entre ellos, el proxy puede cerrar la conexión por inactividad si no está configurado para mantener conexiones WebSocket.

Patrones clave:

- la conexión se cae tras 60 segundos → `proxy_read_timeout` default de nginx (60s)
- la conexión se cae tras inactividad → no hay ping/pong para mantener la conexión viva
- `upstream timed out` en nginx logs → el backend no responde a tiempo
- la conexión funciona desde curl pero no desde el navegador → posible problema de proxy
- la conexión se cae solo en producción → nginx no configurado para WebSocket

👉 Si los WebSockets se caen tras exactamente 60 segundos, el problema es el timeout del proxy.

---

## 🛠️ Procedimiento (runbook)

### 1. Verificar que el backend soporta WebSocket

```bash
curl -s -o /dev/null -D - -H "Upgrade: websocket" -H "Connection: Upgrade" -H "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" -H "Sec-WebSocket-Version: 13" http://localhost/ws
```

### 2. Verificar configuración de nginx para WebSocket

```bash
grep -r "proxy_set_header.*Upgrade\|proxy_read_timeout\|proxy_send_timeout" /etc/nginx/
```

### 3. Ver logs de nginx para timeouts

```bash
grep -i "upstream timed out\|connection reset\|timeout" /var/log/nginx/error.log | tail -10
```

### 4. Verificar si el backend está corriendo

```bash
ps aux | grep -E "node|python|gunicorn|uwsgi"
```

### 5. Capturar tráfico WebSocket

```bash
tcpdump -i any port 80 -A | grep -i "upgrade\|websocket\|close\|ping\|pong"
```

---

## 🧯 Mitigación

Si se confirma que los WebSockets se caen por timeout:

Verificar:

```bash
grep -r "proxy_read_timeout" /etc/nginx/
```

Acción:

```bash
# Configurar nginx para soportar WebSocket
# En el bloque location del WebSocket:
# proxy_http_version 1.1;
# proxy_set_header Upgrade $http_upgrade;
# proxy_set_header Connection "upgrade";
# proxy_read_timeout 3600s;
# proxy_send_timeout 3600s;

# Recargar nginx
nginx -t && nginx -s reload
```

Mitigación adicional:

```bash
# Implementar ping/pong en la aplicación para mantener la conexión viva
# El servidor envía un ping cada 30 segundos
# El cliente responde con pong
# Si no se recibe pong en 10 segundos, cerrar y reconectar
```

Rollback:

```bash
# Restaurar configuración original de nginx
# Recargar nginx
nginx -t && nginx -s reload
```

Casos comunes:

- nginx con timeout default de 60s → las conexiones se caen tras 1 minuto de inactividad
- proxy no configurado para WebSocket → el handshake falla o la conexión se cierra
- load balancer sin soporte WebSocket → las conexiones se pierden al cambiar de backend
- aplicación sin ping/pong → el proxy cierra la conexión por inactividad

---

## ✅ Interpretación

- la conexión se mantiene tras configurar timeout → el problema era el proxy
- la conexión sigue cayendo → el problema puede estar en la aplicación o en el load balancer
- el handshake falla → nginx no está configurado para WebSocket
- la conexión se cae solo en producción → el load balancer puede no soportar WebSocket

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

## 🔗 Referencias

- [`nginx`](../../guides/nginx.md) — configuración y logs de nginx
- [`curl`](../../guides/curl.md) — inspección de respuestas HTTP
- [`tcpdump`](../../guides/tcpdump.md) — captura de tráfico
- [`scenarios/web/01-performance-and-error-analysis.md`](01-performance-and-error-analysis.md) — análisis de rendimiento web
- [`scenarios/web/05-502-bad-gateway.md`](05-502-bad-gateway.md) — backend caído o timeout
