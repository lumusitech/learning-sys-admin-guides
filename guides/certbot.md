# certbot — Guía completa

**Nivel:** 🟡 Intermedio
**Archivos de práctica:** `labs/docker-compose.tls.yml`
**Ver escenarios relacionados:** [`tls-expired`](../scenarios/infrastructure/04-tls-expired.md), [`cert-rotation`](../scenarios/infrastructure/09-cert-rotation.md), [`tls-handshake-failure`](../scenarios/web/08-tls-handshake-failure.md)

---

## ⚡ Quick command

`certbot renew --dry-run`

> ⚠️ `--dry-run` usa el entorno **staging** de Let's Encrypt: no emite un certificado real y no consume rate limits. Es el primer comando que hay que correr antes de tocar producción.

---

## ⚡ Quick run

```bash
certbot certificates
```

Muestra todos los certificados gestionados, sus dominios y cuántos días les quedan. Si alguno está por vencer, el problema no es el certificado: es la renovación automática.

---

## 📑 Índice

1. [¿Qué es certbot?](#qué-es-certbot)
2. [Modelo mental](#modelo-mental)
3. [Sintaxis básica](#sintaxis-básica)
4. [Salida clave](#salida-clave)
5. [Opciones principales](#opciones-principales)
6. [Patrones de uso](#patrones-de-uso)
7. [Uso en troubleshooting](#uso-en-troubleshooting)
8. [Combinación con otras herramientas](#combinación-con-otras-herramientas)
9. [Uno-liners imprescindibles](#uno-liners-imprescindibles)
10. [Errores comunes](#errores-comunes)
11. [Buenas prácticas](#buenas-prácticas)
12. [Referencias internas](#referencias-internas)

---

## 🧠 ¿Qué es certbot?

`certbot` es el cliente oficial de **Let's Encrypt**, una autoridad certificadora gratuita y automatizada. Habla el protocolo **ACME** con la CA, demuestra que controlás el dominio y guarda el certificado en disco.

Let's Encrypt emite certificados de **90 días**. La única forma sostenible de usarlos es automatizar la renovación: renovar a mano cada tres meses no es un plan, es una cuenta regresiva.

`certbot` hace tres cosas distintas y conviene no confundirlas:

1. **Obtener** un certificado (challenge ACME).
2. **Renovar** antes de que expire.
3. **Desplegar**: recargar el servicio para que use el certificado nuevo.

La tercera es la que más se olvida. Un certificado renovado en disco pero no recargado en nginx sigue siendo un certificado viejo en producción.

---

## 🧠 Modelo mental

```text
certbot ──ACME──> Let's Encrypt
   │
   ├── challenge (HTTP-01 / DNS-01 / TLS-ALPN-01)
   ├── /etc/letsencrypt/live/<nombre>/   ← symlinks al certificado vigente
   ├── /etc/letsencrypt/renewal/<nombre>.conf  ← cómo renovarlo
   └── deploy hook → reload del servicio
```

Tres ideas que ordenan todo:

- **El certificado no es un archivo, es un par**: `fullchain.pem` (certificado + cadena) y `privkey.pem` (clave privada). El servicio necesita ambos.
- **Obtener ≠ renovar ≠ desplegar**. Son tres pasos con comandos distintos y fallas distintas.
- **La renovación depende de la configuración guardada**, no de la línea de comandos. `certbot renew` lee `/etc/letsencrypt/renewal/*.conf` y repite el challenge que funcionó la primera vez.

Si el challenge original fue `--standalone` y después el puerto 80 quedó ocupado por nginx, la renovación va a fallar aunque el certificado todavía sirva. El estado real está en `renewal/`.

---

## 📝 Sintaxis básica

```text
certbot [subcomando] [opciones]
```

| Subcomando | Qué hace |
|------------|----------|
| `run` (default) | Obtiene el certificado y configura el servidor web |
| `certonly` | Solo obtiene el certificado, no toca la configuración |
| `renew` | Renueva los certificados que están por vencer |
| `certificates` | Lista certificados, dominios y vencimiento |
| `revoke` | Revoca un certificado |
| `delete` | Borra un certificado y su configuración |
| `plugins` | Lista los plugins disponibles |
| `register` | Registra una cuenta ACME |

Ejemplos mínimos:

```bash
# Obtener y configurar nginx automáticamente
certbot --nginx -d ejemplo.com -d www.ejemplo.com

# Solo obtener, con webroot
certbot certonly --webroot -w /var/www/html -d ejemplo.com

# Simular la renovación de todo
certbot renew --dry-run

# Renovar de verdad
certbot renew
```

---

## 🔑 Salida clave

### `certbot certificates`

```text
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Found the following certs:
  Certificate Name: ejemplo.com
    Serial Number: 3f2a9c1e8b7d4a6f...
    Key Type: ECDSA
    Domains: ejemplo.com www.ejemplo.com
    Expiry Date: 2026-02-14 03:12:45+00:00 (VALID: 89 days)
    Certificate Path: /etc/letsencrypt/live/ejemplo.com/fullchain.pem
    Private Key Path: /etc/letsencrypt/live/ejemplo.com/privkey.pem
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
```

Lo que importa:

- **`Certificate Name`**: es el nombre del certificado, no siempre el dominio. Se usa con `--cert-name`.
- **`Domains`**: todos los nombres que cubre. Si falta un `www`, el navegador va a mostrar error en ese host.
- **`VALID: N days`**: si es negativo, el certificado ya expiró. Si es menor a 30, la renovación automática no está funcionando.

### Errores típicos

| Mensaje | Significado |
|---------|-------------|
| `Challenge failed for domain` | La CA no pudo validar el dominio (DNS, puerto 80, redirect, proxy) |
| `Problem binding to port 80` | `--standalone` no pudo abrir el puerto porque otro proceso lo usa |
| `too many failed authorizations recently` | Rate limit por validaciones fallidas: esperar antes de reintentar |
| `Rate limit exceeded` | Se pidieron demasiados certificados: usar staging para pruebas |
| `DNS problem: NXDOMAIN` | El dominio no resuelve o apunta a otro lado |
| `No valid IP addresses found` | El registro A/AAAA no existe o no es alcanzable |
| `Some challenges have failed` | Una parte del proceso falló: leer el detalle arriba del mensaje |

### Códigos de salida

`certbot` devuelve `0` en éxito y `1` en falla. `certbot renew` devuelve `0` también cuando **no había nada que renovar**. Para saber si renovó algo, mirar el log o usar `--deploy-hook`.

---

## 🎛️ Opciones principales

### Autenticación (cómo demuestra el control del dominio)

| Opción | Requiere | Cuándo usarla |
|--------|----------|---------------|
| `--nginx` | nginx instalado | nginx sirve el sitio y podés dejar que certbot edite la config |
| `--apache` | Apache instalado | Igual, con Apache |
| `--webroot -w /ruta` | Un webroot servido por el servidor | nginx o Apache ya escuchan en el puerto 80 |
| `--standalone` | Puerto 80 libre | Servidor sin web server, o para pruebas |
| `--manual --preferred-challenges dns` | Acceso al DNS | Wildcards y servidores sin puerto 80 público |
| `--dns-<plugin>` | Plugin DNS del proveedor | Automatizar DNS-01 sin intervención manual |

### Identidad y comportamiento

| Opción | Efecto |
|--------|--------|
| `-d dominio` | Dominio a cubrir. Repetible |
| `--email` | Email de contacto para la cuenta ACME |
| `--agree-tos` | Acepta los términos sin preguntar |
| `--non-interactive` | No hace preguntas (para scripts) |
| `--dry-run` | Simula contra staging, sin emitir certificado real |
| `--staging` | Usa staging de forma permanente (para pruebas) |
| `--force-renewal` | Fuerza la renovación aunque falte mucho |
| `--cert-name` | Selecciona el certificado por nombre |
| `--expand` | Agrega dominios a un certificado existente |
| `--key-type` | `ecdsa` (default moderno) o `rsa` |
| `--rsa-key-size` | Tamaño de clave RSA (`2048`, `4096`) |
| `--deploy-hook` | Comando que corre **solo si el certificado se renovó** |
| `--post-hook` | Comando que corre después de cada intento |
| `--pre-hook` | Comando que corre antes de cada intento |

### Diferencia clave entre hooks

- `--deploy-hook`: se ejecuta **solo cuando se emite o renueva** un certificado. Es el lugar para `nginx -s reload`.
- `--post-hook`: se ejecuta **siempre**, se haya renovado o no. Útil para limpiar o registrar.
- `--pre-hook`: se ejecuta antes del intento. Sirve para liberar el puerto 80 con `--standalone`.

### Rate limits (importante)

Let's Encrypt limita la emisión para evitar abuso. Los límites principales:

- 50 certificados por dominio registrado por semana.
- 5 certificados duplicados por semana (mismo conjunto de dominios).
- 5 validaciones fallidas por cuenta y hostname por hora.
- Límites de cuentas y órdenes por IP.

Los límites cambian: consultar la documentación oficial antes de automatizar algo agresivo. Para pruebas, `--dry-run` o `--staging` no consumen los límites de producción.

### Archivos que crea

| Ruta | Contenido |
|------|-----------|
| `/etc/letsencrypt/live/<nombre>/fullchain.pem` | Certificado + cadena (lo que usa el servidor) |
| `/etc/letsencrypt/live/<nombre>/privkey.pem` | Clave privada (solo root) |
| `/etc/letsencrypt/live/<nombre>/chain.pem` | Cadena intermedia |
| `/etc/letsencrypt/live/<nombre>/cert.pem` | Certificado solo |
| `/etc/letsencrypt/renewal/<nombre>.conf` | Configuración de renovación |
| `/etc/letsencrypt/archive/<nombre>/` | Versiones anteriores (los `live/` son symlinks) |
| `/var/log/letsencrypt/letsencrypt.log` | Log de todas las operaciones |

> No editar a mano los archivos de `live/`: son symlinks al certificado vigente. Para tocar la configuración de renovación, editar `renewal/<nombre>.conf` o volver a correr certbot con las opciones correctas.

---

## 📋 Patrones de uso

### 1. Primera emisión con nginx ya configurado

```bash
certbot --nginx -d ejemplo.com -d www.ejemplo.com \
  --email admin@ejemplo.com --agree-tos --non-interactive
```

Certbot valida por HTTP-01, emite el certificado y agrega las directivas `ssl_certificate` en el server block. Después conviene revisar el diff de la configuración.

### 2. Emisión sin que certbot toque la configuración

```bash
certbot certonly --webroot -w /var/www/html \
  -d ejemplo.com -d www.ejemplo.com \
  --email admin@ejemplo.com --agree-tos --non-interactive
```

Después se configuran las rutas a mano en nginx:

```nginx
ssl_certificate     /etc/letsencrypt/live/ejemplo.com/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/ejemplo.com/privkey.pem;
```

### 3. Renovación automática con systemd (Debian/Ubuntu)

El paquete instala un timer que corre dos veces al día:

```bash
systemctl list-timers | grep certbot
systemctl status certbot.timer
```

`certbot renew` solo renueva los certificados que vencen en menos de 30 días. El timer no necesita configuración extra.

### 4. Renovación automática con cron (Alpine, contenedores)

```bash
echo "0 3 * * * certbot renew --quiet --deploy-hook 'rc-service nginx reload'" >> /etc/crontabs/root
```

En Alpine, `crond` lee `/etc/crontabs/root`. El `--deploy-hook` evita recargar nginx cuando no hubo renovación.

### 5. Renovar y recargar sin downtime

```bash
certbot renew --deploy-hook 'nginx -t && systemctl reload nginx'
```

`nginx -t` valida la configuración antes de recargar. Si falla, no se recarga y el servicio sigue con el certificado anterior (que todavía sirve).

### 6. Wildcard con DNS-01

```bash
certbot certonly --manual --preferred-challenges dns \
  -d '*.ejemplo.com' -d ejemplo.com \
  --email admin@ejemplo.com --agree-tos
```

El wildcard **solo** se puede validar por DNS-01: la CA no puede distinguir subdominios por HTTP. Para automatizarlo, usar un plugin DNS (`--dns-cloudflare`, `--dns-route53`, etc.) en lugar de `--manual`.

### 7. Agregar dominios a un certificado existente

```bash
certbot --nginx --expand -d ejemplo.com -d www.ejemplo.com -d api.ejemplo.com
```

`--expand` reutiliza el certificado y le suma nombres. Sin `--expand`, certbot puede crear un certificado nuevo con otro nombre.

### 8. Verificar que el certificado en uso es el nuevo

```bash
echo | openssl s_client -connect ejemplo.com:443 -servername ejemplo.com 2>/dev/null \
  | openssl x509 -noout -dates -subject
```

Comparar la fecha con la de `certbot certificates`. Si el disco tiene el certificado nuevo y el servidor muestra el viejo, falta el reload.

---

## 🔍 Uso en troubleshooting

### "El certificado expiró"

1. Ver el estado real:

   ```bash
   certbot certificates
   ```

2. Simular la renovación:

   ```bash
   certbot renew --dry-run
   ```

3. Si el dry-run falla, leer el motivo: challenge, DNS, puerto 80, permisos.

4. Renovar de verdad y recargar:

   ```bash
   certbot renew --deploy-hook 'systemctl reload nginx'
   ```

### "Renovó pero el navegador sigue mostrando el certificado viejo"

El certificado está en disco pero el servicio no lo recargó. Verificar:

```bash
certbot certificates | grep -E "Domains|Expiry"
echo | openssl s_client -connect localhost:443 -servername ejemplo.com 2>/dev/null | openssl x509 -noout -enddate
```

Si las fechas no coinciden, falta el `--deploy-hook` o el reload falló. Revisar el log de certbot y el de nginx.

### "Challenge failed"

El origen del problema está en la validación, no en el certificado:

- **DNS**: el dominio debe resolver a la IP del servidor. Un `AAAA` que apunta a otro host rompe HTTP-01.
- **Puerto 80**: debe estar abierto y accesible desde internet. Un firewall o un CDN delante del origen lo bloquean.
- **Redirect**: si el sitio redirige a HTTPS, el challenge debe seguir siendo accesible en `/.well-known/acme-challenge/`.
- **Webroot**: la ruta debe ser la que realmente sirve el servidor, no una copia.

### "Rate limit exceeded"

No reintentar en bucle. Esperar la ventana del límite y usar `--dry-run` para diagnosticar. Si el problema es de configuración, probar con `--staging`:

```bash
certbot certonly --staging --webroot -w /var/www/html -d ejemplo.com
```

### "Problem binding to port 80"

`--standalone` necesita el puerto 80 libre. Si nginx lo ocupa, usar `--webroot` o `--nginx`, o liberar el puerto con un `--pre-hook` y volver a levantarlo con `--post-hook`.

### "Hay varios certificados y renueva el equivocado"

`certbot renew` renueva todos los que estén por vencer. Para uno solo:

```bash
certbot renew --cert-name ejemplo.com
```

Y para evitar duplicados al emitir, usar `--cert-name` desde el principio.

### "El certificado es válido pero el handshake falla"

El problema puede ser de protocolo o cadena, no de vencimiento:

```bash
openssl s_client -connect ejemplo.com:443 -servername ejemplo.com -showcerts
```

Verificar que se sirve `fullchain.pem` y no solo `cert.pem`: sin la cadena intermedia, algunos clientes no pueden validar.

---

## 🛠️ Combinación con otras herramientas

| Herramienta | Para qué |
|-------------|----------|
| `openssl s_client` | Ver el certificado que realmente sirve el servidor |
| `openssl x509 -checkend` | Verificar si vence en N segundos (para monitoreo) |
| `curl -vI` | Ver el handshake TLS desde el cliente |
| `dig` | Confirmar que el dominio resuelve a la IP correcta |
| `ss -ltnp` | Ver quién ocupa el puerto 80 |
| `nginx -t` | Validar la configuración antes del reload |
| `cron` / `systemd` | Programar la renovación |
| `diff` | Comparar la configuración de nginx antes y después de `--nginx` |

Ejemplo de verificación de vencimiento para monitoreo:

```bash
openssl x509 -checkend 1209600 -noout -in /etc/letsencrypt/live/ejemplo.com/fullchain.pem \
  && echo "OK: más de 14 días" || echo "ALERTA: vence en menos de 14 días"
```

---

## 💡 Uno-liners imprescindibles

```bash
certbot certificates                          # estado de todos los certificados
certbot renew --dry-run                       # simular renovación (staging)
certbot renew --deploy-hook 'systemctl reload nginx'   # renovar y recargar
certbot renew --cert-name ejemplo.com          # renovar uno solo
certbot --nginx --expand -d ejemplo.com -d www.ejemplo.com  # agregar dominio
certbot delete --cert-name ejemplo.com         # borrar certificado y config
certbot plugins                                # plugins disponibles
certbot renew --force-renewal --cert-name ejemplo.com  # forzar (cuidado con rate limits)
```

---

## ⚠️ Errores comunes

### 1. Renovar sin recargar el servicio

El certificado nuevo queda en disco y el servicio sigue sirviendo el viejo. Siempre usar `--deploy-hook` o un `--post-hook`.

### 2. Usar `--force-renewal` en el cron

Si el cron corre `--force-renewal` cada día, se piden 365 certificados por año y se choca con el límite semanal. El cron debe ser `certbot renew` sin `--force-renewal`.

### 3. Probar contra producción

Cada intento fallido consume rate limits. Para diagnosticar, `--dry-run` o `--staging`.

### 4. Desplegar un certificado de staging

Los certificados de staging no son confiables para los navegadores. Si se usó `--staging`, hay que volver a emitir contra producción al final.

### 5. Borrar `live/` a mano

Los archivos de `live/` son symlinks. Borrarlos deja el certificado inutilizable y la configuración de renovación rota. Usar `certbot delete --cert-name`.

### 6. No respaldar `/etc/letsencrypt`

Un `certbot delete` accidental o una migración de servidor sin backup obliga a emitir de nuevo. El backup es un `tar` de un directorio.

### 7. Olvidar el `AAAA` en el DNS

HTTP-01 puede intentar validar por IPv6. Si el `AAAA` apunta a otro host o a un servicio que no responde, el challenge falla aunque el `A` esté bien.

### 8. Confundir `--deploy-hook` con `--post-hook`

El primero corre solo si hubo renovación; el segundo corre siempre. Usar el equivocado recarga el servicio en cada intento, incluso cuando no cambió nada.

### 9. Servicio con usuario no-root

`privkey.pem` es solo lectura para root. Si el servicio corre con otro usuario, el deploy hook debe ajustar permisos o copiar el par a una ruta accesible.

---

## ✅ Buenas prácticas

- **Simular antes de renovar**: `certbot renew --dry-run` en cada cambio de infraestructura.
- **Automatizar el despliegue, no solo la emisión**: `--deploy-hook` con `nginx -t && systemctl reload nginx`.
- **Programar dos veces al día**: el timer de systemd ya lo hace; en cron, usar una hora de bajo tráfico.
- **Monitorear el vencimiento**: alertar a 30, 14 y 7 días. No confiar en que el certificado se renueva solo.
- **Un `--cert-name` por aplicación**: facilita renovar y borrar sin ambigüedad.
- **Respaldar `/etc/letsencrypt`** antes de migrar o cambiar de servidor.
- **No editar `live/`**: editar `renewal/` o volver a correr certbot.
- **Usar `--staging` para pruebas**: los límites de producción son un recurso compartido.
- **Wildcard solo con DNS-01**: no hay atajo por HTTP.

---

## 🔗 Referencias internas

- [`openssl`](openssl.md) — inspección de certificados y handshake
- [`nginx`](nginx.md) — configuración SSL y reload sin downtime
- [`dig_curl`](dig_curl.md) — verificar DNS y respuestas HTTP
- [`curl`](curl.md) — comprobar el handshake desde el cliente
- [`ip_ss`](ip_ss.md) — ver qué proceso ocupa el puerto 80
- [`cron`](cron.md) — programar la renovación en sistemas sin systemd
- [`systemd_journalctl`](systemd_journalctl.md) — timer y logs de certbot
- [`openrc`](openrc.md) — recargar nginx en Alpine
- [`apk`](apk.md) — instalar certbot en Alpine
- [`scenario`](../scenarios/infrastructure/04-tls-expired.md) — certificado expirado en producción
- [`scenario`](../scenarios/infrastructure/09-cert-rotation.md) — rotación sin downtime
- [`scenario`](../scenarios/web/08-tls-handshake-failure.md) — handshake TLS fallido
