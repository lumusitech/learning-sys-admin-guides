# 🧩 Escenario: Errores 5xx en servidor web (nginx)

---

## 🎯 Problema

Los usuarios reportan errores al acceder al sitio web. El servidor responde con códigos HTTP 5xx, lo que indica fallos del lado del servidor. Es necesario identificar la causa y restaurar el servicio.

---

## ⚡ Quick command (SRE)

```bash
tail -n 50 /var/log/nginx/error.log
```

---

## ✅ Salida esperada

- errores recientes del servidor nginx
- mensajes de conexión fallida o timeouts
- referencias a upstreams o servicios internos

Interpretación:

- `connection refused` → backend no está corriendo
- `upstream timed out` → backend lento o bloqueado
- `no live upstreams` → backend caído o mal configurado

---

## 🧠 Diagnóstico

Los errores 5xx indican fallos internos del servidor o sus dependencias.

Patrones clave:

- 500 → error interno de aplicación
- 502 → fallo de conexión con backend
- 503 → servicio no disponible
- 504 → timeout en upstream

👉 nginx rara vez falla solo: generalmente el problema está en la aplicación o backend.

---

## 🛠️ Procedimiento (runbook)

### 1. Ver errores en nginx

```bash
tail -n 50 /var/log/nginx/error.log
```

### 2. Verificar estado del servicio nginx

```bash
systemctl status nginx
```

### 3. Verificar backend (app / API)

```bash
# puerto 3000 o el que sea
ss -tulnp | grep 3000
```

### 4. Probar conectividad directa al backend

```bash
curl -I http://127.0.0.1:3000
```

### 5. Ver logs del backend

```bash
journalctl -u <servicio> --no-pager | tail -20
```

### 6. Verificar configuración nginx

```bash
nginx -t
```

---

## 🧯 Mitigación

Si hay errores 5xx:

Verificar:

```bash
systemctl status nginx
systemctl status <backend>
```

Acción:

```bash
# reiniciar backend
systemctl restart <backend>

# si es necesario reiniciar nginx
systemctl restart nginx
```

Rollback:

```bash
# restaurar configuración previa
cp /etc/nginx/nginx.conf.bak /etc/nginx/nginx.conf
nginx -t && systemctl reload nginx
```

Casos comunes:

- backend caído → servicio detenido o crash
- puerto incorrecto → mala configuración de proxy_pass
- timeout → backend lento o sobrecargado
- deploy fallido → versión rota de la app

---

## ✅ Interpretación

- nginx responde correctamente → error resuelto
- backend sigue fallando → problema de aplicación
- errores reaparecen → revisar carga o estabilidad
- solo ciertos endpoints fallan → bug específico en API

---

## 🐧 Variante Alpine (OpenRC + logs)

Este escenario asume systemd (Debian/Ubuntu). En Alpine Linux:

```bash
# Debian:                          # Alpine:
systemctl status nginx              rc-service nginx status
systemctl restart nginx             rc-service nginx restart
systemctl reload nginx              rc-service nginx reload
systemctl status <backend>          rc-service <backend> status
systemctl restart <backend>         rc-service <backend> restart
journalctl -u <svc> --no-pager      logread | grep <svc>
```

---

## 🧑‍🏫 Modo docente

**Preguntas:** ¿Cuál es la diferencia entre 502 Bad Gateway y 504 Gateway Timeout? ¿Dónde mirás primero cuando hay errores 5xx? ¿Cómo verificás si el backend está corriendo y escuchando?

**Ejercicio:** Diagnosticar un error 5xx en nginx: revisar access.log y error.log, verificar backend con curl local, revisar upstream en configuración.

**Evaluación:** correlación correcta entre error HTTP y logs de nginx, verificación del backend, propuesta de fix.

---

## 🔗 Referencias

- [`nginx`](../../guides/nginx.md)
- [`systemd_journalctl`](../../guides/systemd_journalctl.md)
- [`openrc`](../../guides/openrc.md) — Alpine Linux: servicios (rc-service, rc-update)
- [`busybox`](../../guides/busybox.md) — Alpine Linux: toolchain mínima (logread, dmesg)
