# 🧩 Escenario: Sesiones perdidas en load balancer — sticky sessions rotas

**Dominio:** web
**Nivel:** 🟡 Intermedio
**Herramientas:** `curl`, `grep`, `netstat`, `tcpdump`
**Archivos:** `labs/docker-compose.web-cors.yml`

---

## 🎯 Problema

Usuarios reportan que al hacer login en la aplicación, a veces son redirigidos de vuelta a la página de login. El problema es intermitente: funciona en algunos requests y falla en otros. La aplicación usa sesiones en memoria (stateful) y hay 3 backends detrás de un load balancer. Cuando el load balancer envía al usuario a un backend diferente, la sesión no existe en ese backend.

---

## ⚡ Quick command (SRE)

```bash
for i in $(seq 1 10); do curl -sI http://app.local/login | grep -i "set-cookie\|backend"; done
```

---

## ✅ Salida esperada

```text
HTTP/1.1 200 OK
Set-Cookie: SESSIONID=abc123; Path=/
X-Backend: backend-01

HTTP/1.1 302 Found
Location: /login
X-Backend: backend-02    ← sesión no existe en backend-02
```

Interpretación:

- Backend-01 devuelve sesión `abc123` → login exitoso
- Backend-02 no reconoce la sesión → redirige a login
- La cookie se envía en cada request pero el backend cambia → sticky sessions no configuradas
- `X-Backend` (cabecera personalizada) muestra el backend que atendió cada request

---

## 🧠 Diagnóstico

Cuando una aplicación es stateful (guarda sesiones en memoria local), necesita **sticky sessions** (session affinity): el load balancer debe enviar todos los requests de un mismo usuario al mismo backend.

Sin sticky sessions:

1. Login en backend-01: sesión creada, cookie enviada al cliente
2. Siguiente request: load balancer envía a backend-02
3. Backend-02 no tiene la sesión: redirige a login
4. Cliente vuelve a login → experiencia rota

---

## 🛠️ Procedimiento (runbook)

### 1. Confirmar que el problema es sticky sessions

```bash
for i in $(seq 1 20); do curl -s -H "Cookie: SESSIONID=test123" http://app.local/dashboard -w "\n%{http_code}" | tail -1; done | sort | uniq -c
```

Si ves una mezcla de 200 y 302 con la misma cookie, es sticky sessions rota.

### 2. Verificar la configuración del load balancer

**nginx:**

```bash
grep -A5 "upstream" /etc/nginx/nginx.conf
```

Sin sticky:

```nginx
upstream backend {
    server backend-01:8080;
    server backend-02:8080;
    server backend-03:8080;
}
```

Con sticky:

```nginx
upstream backend {
    ip_hash;                          # session affinity por IP
    server backend-01:8080;
    server backend-02:8080;
    server backend-03:8080;
}
```

### 3. Alternativa: sticky con cookie (nginx plus o openresty)

```nginx
upstream backend {
    sticky cookie srv_id expires=1h;
    server backend-01:8080;
    server backend-02:8080;
}
```

### 4. Verificar en HAProxy

```bash
grep -E "cookie|stick" /etc/haproxy/haproxy.cfg
```

### 5. Solución ideal: hacer la aplicación stateless

```bash
# Mover sesiones a Redis (app stateless, sesiones en DB compartida)
# Esta es la solución arquitectónica, no la de emergencia
```

---

## 🧯 Mitigación

Verificar:

```bash
curl -sI http://app.local/ | grep -i "x-backend\|server"
```

Acción: Agregar `ip_hash;` al upstream block de nginx y recargar.

Rollback: Quitar `ip_hash;` (si la app se hizo stateless mientras tanto).

---

## ✅ Interpretación

Sticky sessions rotas son el síntoma clásico de una aplicación stateful mal configurada en un entorno horizontal. La solución rápida es `ip_hash` en nginx, pero la solución correcta es mover el estado a un almacenamiento compartido (Redis, base de datos, JWT).

`ip_hash` tiene limitaciones: todos los usuarios detrás del mismo NAT van al mismo backend (desequilibrio de carga). Para producción real, la sesión debe ser externa.

---

## 🔗 Referencias

- [`curl`](../../guides/curl.md) — diagnóstico HTTP con headers
- [`nginx`](../../guides/nginx.md) — upstream y load balancing
- [`tcpdump`](../../guides/tcpdump.md) — confirmar a qué backend va el tráfico
- [`concept`](../../concepts/stateful-vs-stateless.md) — stateful vs stateless
- [`scenario`](05-502-bad-gateway.md) — load balancer sin backends disponibles
- [`scenario`](01-performance-and-error-analysis.md) — patrones de rendimiento
