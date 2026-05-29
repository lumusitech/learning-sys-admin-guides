# 🧩 Escenario: Certificado TLS vencido — renovar y automatizar

**Dominio:** infrastructure
**Nivel:** 🟡 Intermedio
**Herramientas:** `openssl`, `nginx`, `certbot`, `curl`, `journalctl`
**Archivos:** Sistema en vivo

---

## 🎯 Problema

Los usuarios reportan que el navegador muestra "Su conexión no es privada" o "SECURITY_ERROR". El certificado TLS del servidor web expiró y no se renovó a tiempo. El servicio es inaccesible para usuarios que no ignoran la advertencia. Es necesario renovar el certificado inmediatamente y configurar la renovación automática para que no vuelva a ocurrir.

---

## ⚡ Quick command (SRE)

```bash
echo | openssl s_client -connect <dominio>:443 -servername <dominio> 2>/dev/null | openssl x509 -noout -dates
```

---

## ✅ Salida esperada

- `notAfter` muestra una fecha en el pasado → certificado expirado
- `curl` devuelve error SSL → el navegador/cliente rechaza la conexión
- nginx error log muestra `SSL: error:...certificate has expired` → el certificado no se renovó
- `certbot certificates` muestra el certificado con días negativos → expirado

Interpretación:

- `notAfter` en el pasado → el certificado expiró, se necesita renovación inmediata
- `curl` con `-k` funciona pero sin `-k` falla → el problema es exclusivamente el certificado
- nginx sigue sirviendo el certificado viejo → se necesita recargar nginx tras la renovación
- certbot muestra días negativos → la renovación automática no funcionó

---

## 🧠 Diagnóstico

Los certificados TLS tienen una fecha de expiración. Si no se renuevan antes de esa fecha, los clientes (navegadores, curl, APIs) rechazarán la conexión. Let's Encrypt emite certificados por 90 días y certbot debería renovarlos automáticamente, pero a veces falla por cron mal configurado, cambios de configuración, o problemas de DNS.

Patrones clave:

- certificado expirado → se necesita renovación inmediata
- certbot no renovó automáticamente → revisar cron/timer de certbot
- nginx no recargó tras renovación → se necesita `nginx -s reload`
- el dominio no resuelve → certbot no puede verificar propiedad
- múltiples certificados en `/etc/letsencrypt/live/` → posible confusión de certificados

👉 Si el certificado expiró, lo primero es renovarlo. Después investigar por qué la automática falló.

---

## 🛠️ Procedimiento (runbook)

### 1. Verificar la fecha de expiración del certificado

```bash
echo | openssl s_client -connect <dominio>:443 -servername <dominio> 2>/dev/null | openssl x509 -noout -dates
```

### 2. Verificar el estado de certbot

```bash
certbot certificates
```

### 3. Intentar renovación manual

```bash
certbot renew --dry-run
certbot renew
```

### 4. Recargar nginx tras la renovación

```bash
nginx -t && nginx -s reload
```

### 5. Verificar que el certificado se actualizó

```bash
echo | openssl s_client -connect <dominio>:443 -servername <dominio> 2>/dev/null | openssl x509 -noout -dates
```

---

## 🧯 Mitigación

Si se confirma que el certificado expiró:

Verificar:

```bash
echo | openssl s_client -connect <dominio>:443 2>/dev/null | openssl x509 -noout -dates
certbot certificates
```

Acción:

```bash
# Renovar el certificado
certbot renew

# Recargar nginx para que use el nuevo certificado
nginx -t && nginx -s reload

# Verificar que la renovación funcionó
curl -I https://<dominio>
```

Mitigación adicional:

```bash
# Configurar renovación automática con cron
echo "0 3 * * * certbot renew --quiet --deploy-hook 'nginx -s reload'" | crontab -

# O usar el timer de systemd
systemctl enable certbot.timer
systemctl start certbot.timer

# Verificar que el timer está activo
systemctl list-timers | grep certbot
```

Rollback:

```bash
# Si la renovación falla, restaurar el certificado anterior
# Los backups están en /etc/letsencrypt/archive/
# Restaurar y recargar nginx
nginx -t && nginx -s reload
```

Casos comunes:

- certbot cron no configurado → el certificado nunca se renueva automáticamente
- certbot cron configurado pero no ejecutado → revisar logs de cron
- DNS cambiado → certbot no puede verificar propiedad del dominio
- nginx no recarga tras renovación → el certificado nuevo no se aplica
- múltiples certificados → certbot renueva el incorrecto

---

## ✅ Interpretación

- el certificado se renueva y nginx responde con el nuevo → problema resuelto
- certbot falla por DNS → verificar que el dominio apunta al servidor correcto
- certbot falla por permisos → verificar que certbot corre como root
- la renovación automática no funciona → configurar cron o timer de systemd

---

## 🐧 Variante Alpine (OpenRC)

> Este escenario usa `systemctl` y `journalctl`.

### Variante B — systemctl + journalctl

```bash
# Debian:                          # Alpine:
systemctl restart nginx            rc-service nginx restart
systemctl status certbot.timer     rc-service certbot status
journalctl -u nginx --since "1h"   logread | grep nginx | tail -20
```

---

## 🔗 Referencias

- [`nginx`](../../guides/nginx.md) — configuración y logs de nginx
- [`curl`](../../guides/curl.md) — inspección de respuestas HTTP
- [`ssh`](../../guides/ssh.md) — configuración de servicios
- [`scenarios/web/02-nginx-5xx-errors.md`](../web/02-nginx-5xx-errors.md) — errores 5xx
- [`scenarios/infrastructure/03-disaster-recovery.md`](03-disaster-recovery.md) — disaster recovery
