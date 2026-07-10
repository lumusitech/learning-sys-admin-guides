# 🧩 Escenario: PHP-FPM crasheado — 502 Bad Gateway desde nginx

**Dominio:** web
**Nivel:** 🟡 Intermedio
**Herramientas:** `systemctl`, `ss`, `tail`, `strace`
**Archivos:** `labs/docker-compose.broken.yml`

---

## 🎯 Problema

El sitio web devuelve `502 Bad Gateway` en todas las páginas. Nginx está corriendo y responde en el puerto 80, pero no puede comunicarse con PHP-FPM. Los usuarios ven un error genérico de nginx. Necesitás determinar si PHP-FPM está corriendo, si está escuchando en el puerto/socket correcto, y si puede procesar requests.

---

## ⚡ Quick command (SRE)

```bash
systemctl status php*-fpm && ss -tlnp | grep -E "php|9000"
```

---

## ✅ Salida esperada

```text
# PHP-FPM no corriendo:
● php8.1-fpm.service - PHP FastCGI Process Manager
   Active: failed (Result: exit-code)
   Process: 1234 ExecStart=/usr/sbin/php-fpm8.1 (code=exited, status=78)

# O corriendo pero no en el socket esperado:
LISTEN 0 128 /run/php/php8.1-fpm.sock   ← socket UNIX
```

Interpretación:

- `Active: failed` → PHP-FPM no arrancó. Revisar error de configuración.
- `Active: active` pero socket diferente al configurado en nginx → mismatch de socket/puerto
- `status=78` → error de configuración de PHP-FPM (archivo .conf inválido)
- Sin entrada en `ss` → PHP-FPM no está escuchando

---

## 🧠 Diagnóstico

El error 502 desde nginx significa que el proxy upstream (PHP-FPM) no responde. Las causas más comunes:

- PHP-FPM no está corriendo (crash, OOM, nunca arrancó)
- PHP-FPM está corriendo pero en un socket/puerto diferente al configurado en nginx
- PHP-FPM tiene todas las conexiones ocupadas y rechaza nuevas
- Archivo de configuración de PHP-FPM con error de sintaxis
- Permisos incorrectos en el socket UNIX (nginx no puede escribir)

---

## 🛠️ Procedimiento (runbook)

### 1. Verificar estado de PHP-FPM

```bash
systemctl status php*-fpm
ps aux | grep php-fpm
```

### 2. Ver logs de error

```bash
journalctl -u php*-fpm -n 30 --no-pager
tail -50 /var/log/php*-fpm.log
```

### 3. Verificar sintaxis de configuración

```bash
php-fpm8.1 -t
php-fpm8.1 -y /etc/php/8.1/fpm/php-fpm.conf -t
```

### 4. Verificar que nginx apunta al socket correcto

```bash
grep "fastcgi_pass" /etc/nginx/sites-enabled/default
```

Comparar con el socket real de PHP-FPM:

```bash
grep "listen" /etc/php/8.1/fpm/pool.d/www.conf
```

Deben coincidir: si nginx usa `unix:/run/php/php8.1-fpm.sock`, ese socket debe existir y PHP-FPM debe escuchar en él.

### 5. Verificar permisos del socket

```bash
ls -la /run/php/php8.1-fpm.sock
```

El usuario www-data (o nginx) debe tener permisos de lectura/escritura en el socket.

### 6. Si PHP-FPM estaba caído, reiniciar

```bash
php-fpm8.1 -t && systemctl restart php8.1-fpm
ss -tlnp | grep php
```

### 7. Verificar que el sitio responde

```bash
curl -sI http://localhost | head -3
```

---

## 🧯 Mitigación

Verificar:

```bash
systemctl status php*-fpm && curl -sI http://localhost
```

Acción:

- Si PHP-FPM no arranca: corregir error de config (PHP-FPM -t te dice exactamente qué línea)
- Si el socket no coincide: corregir `fastcgi_pass` en nginx
- Si permisos: `chmod 660 /run/php/php8.1-fpm.sock`

Rollback:

- Restaurar php-fpm.conf de backup: `cp /backup/php-fpm.conf /etc/php/8.1/fpm/`
- Reiniciar: `systemctl restart php8.1-fpm`

---

## ✅ Interpretación

502 Bad Gateway con nginx + PHP-FPM es casi siempre un problema de comunicación entre nginx y PHP-FPM. PHP-FPM puede estar caído por un error de sintaxis, un OOM, o simplemente escuchando en un socket diferente al que nginx espera.

El diagnóstico es sistemático: ¿PHP-FPM corre? ¿En qué socket? ¿Nginx apunta a ese socket? ¿Los permisos son correctos?

---

## 🐧 Variante Alpine (OpenRC)

```bash
# Alpine usa php-fpm como servicio
apk add php81 php81-fpm
rc-service php-fpm81 status
rc-service php-fpm81 restart
tail -20 /var/log/php81/error.log

# En Alpine, el socket está en /run/php-fpm/
ls -la /run/php-fpm/
```

---

## 🔗 Referencias

- [`systemctl`](../../guides/systemd.md) — gestión de servicios (alternativa: systemd.md)
- [`nginx`](../../guides/nginx.md) — fastcgi_pass y upstream
- [`ss`](../../guides/ip_ss.md) — verificar puertos y sockets
- [`strace`](../../guides/strace.md) — debuggear PHP-FPM si no arranca
- [`scenario`](05-502-bad-gateway.md) — 502 en contexto de proxy reverso genérico
- [`scenario`](02-nginx-5xx-errors.md) — otros errores 5xx en nginx
