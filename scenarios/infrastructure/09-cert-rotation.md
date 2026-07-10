# 🧩 Escenario: Rotación de certificados con Let's Encrypt y certbot

**Dominio:** infrastructure
**Nivel:** 🟡 Intermedio
**Herramientas:** `certbot`, `openssl`, `nginx`, `curl`, `crontab`
**Archivos:** `labs/docker-compose.tls.yml`

---

## 🎯 Problema

El certificado TLS de producción vence en 7 días. Necesitás rotarlo antes de que expire usando Let's Encrypt con certbot, verificar que el nuevo certificado funciona, y configurar la renovación automática para que no vuelva a ocurrir. El servidor tiene nginx como proxy reverso y no puede haber downtime.

---

## ⚡ Quick command (SRE)

```bash
certbot renew --dry-run && certbot certificates | grep -E "Domains|Expiry"
```

---

## ✅ Salida esperada

```text
- - - - - - - - - - - - - - - - - - - - - - - - - -
Found the following certs:
  Certificate Name: ejemplo.com
    Domains: ejemplo.com www.ejemplo.com
    Expiry Date: 2026-10-08 12:00:00+00:00 (VALID: 89 days)
    Certificate Path: /etc/letsencrypt/live/ejemplo.com/fullchain.pem
    Private Key Path: /etc/letsencrypt/live/ejemplo.com/privkey.pem
```

Interpretación:

- `VALID: 89 days` → el certificado fue renovado exitosamente
- `dry-run` sin errores → la renovación automática funcionará sin intervención manual
- Fecha de expiración en el futuro → rotación exitosa

---

## 🧠 Diagnóstico

Una rotación de certificados no es solo cambiar el archivo del certificado. Hay que:

- Verificar que el challenge de validación funcione (HTTP-01 o DNS-01)
- Recargar nginx con el nuevo certificado sin downtime
- Verificar que el nuevo certificado es válido y la cadena está completa
- Configurar el timer o cron para renovación automática

Patrones de fallo:

- `certbot: Challenge failed` → el dominio no es accesible desde internet, o el webroot está mal configurado
- `certbot renew --dry-run` falla pero el certificado no expiró → configurar alerta antes de que expire
- Certificado renovado pero nginx no lo carga → falta reload post-renovación

---

## 🛠️ Procedimiento (runbook)

### 1. Verificar estado actual

```bash
certbot certificates
echo | openssl s_client -connect localhost:443 -servername ejemplo.com 2>/dev/null | openssl x509 -noout -enddate
```

### 2. Renovar certificado (si ya existe)

```bash
certbot renew --dry-run              # Primero simular
certbot renew                        # Después ejecutar
```

### 3. Obtener nuevo certificado (si es primera vez)

```bash
certbot certonly --webroot -w /var/www/html \
  -d ejemplo.com -d www.ejemplo.com \
  --email admin@ejemplo.com --agree-tos --non-interactive
```

### 4. Actualizar configuración de nginx

```bash
sed -i 's|ssl_certificate .*|ssl_certificate /etc/letsencrypt/live/ejemplo.com/fullchain.pem;|' /etc/nginx/sites-enabled/default
sed -i 's|ssl_certificate_key .*|ssl_certificate_key /etc/letsencrypt/live/ejemplo.com/privkey.pem;|' /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx
```

### 5. Verificar que el nuevo certificado está activo

```bash
echo | openssl s_client -connect localhost:443 -servername ejemplo.com 2>/dev/null | openssl x509 -noout -dates
```

### 6. Configurar renovación automática

```bash
# Verificar que el timer de systemd está activo
systemctl enable certbot.timer
systemctl status certbot.timer

# Alternativa con cron
echo "0 3 * * * root certbot renew --quiet --post-hook 'systemctl reload nginx'" >> /etc/crontab
```

---

## 🧯 Mitigación

Verificar:

```bash
echo | openssl s_client -connect localhost:443 2>/dev/null | openssl x509 -noout -checkend 0 && echo "OK" || echo "EXPIRE"
```

Acción: Si expira, renovar manualmente con `certbot renew --force-renewal`.

Rollback: Si la renovación rompe algo, restaurar el certificado anterior desde `/etc/letsencrypt/archive/` y recargar nginx.

---

## ✅ Interpretación

La rotación de certificados es la operación TLS más frecuente en un sysadmin — los certificados de Let's Encrypt duran 90 días. La diferencia entre un servidor que funciona y uno que muestra errores SSL es un cron job de 2 líneas.

La clave no es solo renovar: es verificar después de renovar. `openssl s_client -checkend` te dice si el certificado nuevo está realmente activo. Sin verificación post-renovación, podés tener el certificado renovado en disco pero nginx sirviendo el viejo.

---

## 🔗 Referencias

- [`openssl`](../../guides/openssl.md) — verificación de certificados
- [`nginx`](../../guides/nginx.md) — configuración SSL
- [`cron`](../../guides/cron.md) — renovación programada
- [`systemctl`](../../guides/systemd.md) — timers de systemd
- [`scenario`](04-tls-expired.md) — qué hacer cuando ya expiró
- [`scenario`](../web/08-tls-handshake-failure.md) — handshake TLS roto (mismo dominio, problema diferente)
