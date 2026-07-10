# nginx — Guía completa

**Nivel:** 🟡 Intermedio
**Archivos de práctica:** `labs/nginx_access.log`
**Ver escenarios relacionados:** [`web/01-performance`](../scenarios/web/01-performance-and-error-analysis.md), [`infrastructure/01-migrate`](../scenarios/infrastructure/01-migrate-to-production.md)

## ⚡ Quick command

`nginx -t`

## ⚡ Quick run

```bash
nginx -t && systemctl reload nginx
```

---

## 📑 Índice

1. [¿Qué es nginx?](#qué-es-nginx)
2. [Instalación](#instalación)
3. [Estructura de directorios y archivos](#estructura-de-directorios)
4. [Virtual Hosts (server blocks)](#virtual-hosts)
5. [Proxy inverso](#proxy-inverso)
6. [SSL/TLS con Let's Encrypt](#ssl-tls)
7. [Rate limiting](#rate-limiting)
8. [Geo-blocking y listas de acceso](#geo-blocking)
9. [Cabeceras de seguridad](#cabeceras-de-seguridad)
10. [Load balancing](#load-balancing)
11. [Caché de contenido](#caché)
12. [Logs: formato, rotación y análisis](#logs)
13. [Optimización de rendimiento](#optimización)
14. [Escenarios reales](#escenarios)
15. [Uno-liners imprescindibles](#uno-liners)

---

## 🧠 ¿Qué es nginx?

nginx es un servidor web, proxy inverso, balanceador de carga y caché HTTP de alto rendimiento. Es el más usado globalmente para sitios de alto tráfico.

**Casos de uso:**

- Servir contenido estático (HTML, CSS, JS, imágenes)
- Proxy inverso para aplicaciones (Node.js, Python, PHP-FPM)
- Balanceador de carga entre varios servidores de backend
- Terminación SSL (nginx maneja el cifrado, el backend recibe HTTP plano)
- Caché de contenido para acelerar respuestas

---

## Instalación

```bash
# Debian/Ubuntu
sudo apt update && sudo apt install -y nginx

# RHEL/CentOS/AlmaLinux
sudo dnf install -y nginx

# Verificar
nginx -v
sudo systemctl status nginx

# Iniciar
sudo systemctl enable --now nginx
```

### Firewall

```bash
# Permitir HTTP y HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# O con iptables
sudo iptables -A INPUT -p tcp -m multiport --dports 80,443 -m conntrack --ctstate NEW -j ACCEPT
```

---

## Estructura de directorios

```text
/etc/nginx/
├── nginx.conf              → Configuración principal
├── sites-available/        → Virtual hosts disponibles (por dominio)
├── sites-enabled/          → Virtual hosts activos (symlinks a sites-available)
├── conf.d/                 → Fragmentos de configuración adicionales
├── snippets/               → Fragmentos reutilizables (ssl, headers, etc.)
├── modules-available/      → Módulos dinámicos
├── modules-enabled/        → Módulos activos
└── mime.types              → Asociación extensiones → MIME types

/var/www/html/              → Raíz web por defecto
/var/log/nginx/
├── access.log              → Log de accesos
└── error.log               → Log de errores
```

### nginx.conf (configuración principal)

```nginx
# /etc/nginx/nginx.conf

user www-data;
worker_processes auto;          # Número de procesos worker (= núcleos CPU)
pid /run/nginx.pid;

events {
    worker_connections 1024;    # Conexiones simultáneas por worker
    multi_accept on;            # Aceptar múltiples conexiones a la vez
    use epoll;                  # Método de E/S eficiente en Linux
}

http {
    sendfile on;                # Enviar archivos directamente (sin copiar a user space)
    tcp_nopush on;              # Enviar cabeceras en un solo paquete
    tcp_nodelay on;             # Deshabilitar Nagle's algorithm
    keepalive_timeout 65;       # Timeout de conexiones persistentes
    types_hash_max_size 2048;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Límites de seguridad básicos
    client_max_body_size 10M;   # Tamaño máximo del cuerpo de petición
    client_body_timeout 10;     # Timeout para leer el cuerpo
    client_header_timeout 10;   # Timeout para leer cabeceras

    # Logging
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    # Gzip (compresión de respuestas)
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css application/json application/javascript text/xml;

    # Incluir virtual hosts
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
```

---

## Virtual Hosts

Los virtual hosts (server blocks) permiten servir múltiples dominios desde un mismo servidor.

### Estructura típica

```nginx
# /etc/nginx/sites-available/ejemplo.com

server {
    listen 80;
    listen [::]:80;
    server_name ejemplo.com www.ejemplo.com;

    root /var/www/ejemplo.com/html;
    index index.html index.htm;

    location / {
        try_files $uri $uri/ =404;
    }

    location /images/ {
        expires 30d;                    # Caché del navegador por 30 días
        access_log off;                 # No loguear accesos a imágenes
    }

    # Denegar acceso a archivos ocultos
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
}
```

### Activar virtual host

```bash
# Crear enlace simbólico de sites-available a sites-enabled
sudo ln -s /etc/nginx/sites-available/ejemplo.com /etc/nginx/sites-enabled/

# Crear directorio y contenido de prueba
sudo mkdir -p /var/www/ejemplo.com/html
echo "<h1>Ejemplo funcionando</h1>" | sudo tee /var/www/ejemplo.com/html/index.html

# Probar sintaxis y recargar
sudo nginx -t
sudo systemctl reload nginx
```

### Desactivar virtual host

```bash
sudo rm /etc/nginx/sites-enabled/ejemplo.com
sudo systemctl reload nginx
```

### server_name: coincidencia de dominios

```nginx
# Dominio exacto
server_name ejemplo.com;

# Wildcard (subdominios)
server_name *.ejemplo.com;

# Inicio por patrón
server_name ~^www\d+\.ejemplo\.com$;

# Múltiples
server_name ejemplo.com www.ejemplo.com admin.ejemplo.com;

# Default server (cuando ningún server_name coincide)
listen 80 default_server;
```

---

## Proxy inverso

nginx recibe peticiones y las reenvía a un servidor backend (app Node.js, Python, Java, etc.).

### Proxy básico

```nginx
server {
    listen 80;
    server_name api.ejemplo.com;

    location / {
        proxy_pass http://localhost:3000;          # Backend en puerto 3000
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;   # IP real del cliente
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

| Directiva | Descripción |
|-----------|-------------|
| `proxy_pass` | URL del backend (`ip:puerto` o unix socket) |
| `proxy_set_header Host $host` | Pasar el Host original al backend |
| `X-Real-IP` | IP real del cliente (no la de nginx) |
| `X-Forwarded-For` | Cadena con IPs por las que pasó la petición |
| `X-Forwarded-Proto` | Protocolo original (http o https) |

### Proxy a socket Unix

```nginx
location / {
    proxy_pass http://unix:/var/run/app.sock;
}
```

### Timeouts del proxy

```nginx
location / {
    proxy_connect_timeout 5;        # Timeout para conectar al backend
    proxy_send_timeout 10;          # Timeout para enviar datos al backend
    proxy_read_timeout 30;          # Timeout para recibir respuesta del backend
    proxy_next_upstream error timeout http_502 http_503;  # Reintentar en otro upstream
}
```

### Proxy con subdirectorios

```nginx
# /api/* → backend:3000/api/*
# /app/* → otro backend:4000/*
server {
    listen 80;
    server_name app.ejemplo.com;

    location /api/ {
        proxy_pass http://localhost:3000/;
    }

    location /app/ {
        proxy_pass http://localhost:4000/;
    }

    location / {
        root /var/www/app;
        try_files $uri $uri/ =404;
    }
}
```

---

## SSL/TLS con Let's Encrypt

### Obtener certificado con certbot

```bash
# Instalar certbot
sudo apt install -y certbot python3-certbot-nginx

# Obtener certificado y configurar nginx automáticamente
sudo certbot --nginx -d ejemplo.com -d www.ejemplo.com

# Solo obtener el certificado (sin configurar nginx)
sudo certbot certonly --nginx -d ejemplo.com

# Renovar (certbot añade un timer automático)
sudo certbot renew --dry-run
```

### Configuración SSL manual

```nginx
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name ejemplo.com;

    # Certificados
    ssl_certificate     /etc/letsencrypt/live/ejemplo.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/ejemplo.com/privkey.pem;

    # Seguridad SSL
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1h;
    ssl_session_tickets off;

    # HSTS (forzar HTTPS en el navegador)
    add_header Strict-Transport-Security "max-age=63072000" always;

    # Redirigir HTTP → HTTPS
    server {
        listen 80;
        listen [::]:80;
        server_name ejemplo.com;
        return 301 https://$server_name$request_uri;
    }

    root /var/www/ejemplo.com/html;
    # ...
}
```

### Renovación automática

```bash
# certbot instala un timer systemd automático
sudo systemctl list-timers | grep certbot
sudo certbot renew --dry-run  # Verificar que funciona
```

---

## Rate limiting

Limita el número de peticiones desde una IP para prevenir abusos y DDoS.

```nginx
http {
    # Definir zona de límite: 10MB de memoria, 10 peticiones/segundo
    limit_req_zone $binary_remote_addr zone=mylimit:10m rate=10r/s;

    server {
        location /api/ {
            # Aplicar límite: burst de 20, retrasar el exceso
            limit_req zone=mylimit burst=20 nodelay;

            # Responder con 429 si se excede
            limit_req_status 429;

            proxy_pass http://backend;
        }

        location /login/ {
            # Límite más restrictivo para login
            limit_req zone=mylimit burst=5 nodelay;
        }
    }
}
```

| Directiva | Descripción |
|-----------|-------------|
| `limit_req_zone` | Define zona compartida de límite (nombre, memoria, rate) |
| `limit_req` | Aplica la zona a una ubicación |
| `burst` | Tamaño de ráfaga permitida |
| `nodelay` | Las peticiones en burst se sirven sin retraso (pero cuentan) |
| `limit_req_status` | Código HTTP cuando se excede (429 por defecto) |

### Rate limiting por conexión

```nginx
http {
    limit_conn_zone $binary_remote_addr zone=addr:10m;

    server {
        location /downloads/ {
            limit_conn addr 10;  # Máximo 10 conexiones simultáneas por IP
            limit_conn_status 503;
        }
    }
}
```

---

## Geo-blocking y listas de acceso

### Bloquear IPs

```nginx
location /admin/ {
    # Bloquear IP específica
    deny 192.168.1.100;
    # Bloquear subred
    deny 10.0.0.0/24;
    # Permitir todo lo demás
    allow all;
}
```

### Bloquear por país (con módulo geoip)

```bash
sudo apt install libnginx-mod-http-geoip
```

```nginx
http {
    geoip_country /usr/share/GeoIP/GeoIP.dat;

    # Bloquear países específicos
    map $geoip_country_code $allowed_country {
        default no;
        US yes;
        GB yes;
        ES yes;
        MX yes;
        CO yes;
    }

    server {
        location / {
            if ($allowed_country = no) {
                return 403;
            }
            # ...
        }
    }
}
```

### Autenticación básica para áreas restringidas

```bash
# Crear usuario y contraseña
sudo apt install -y apache2-utils
sudo htpasswd -c /etc/nginx/.htpasswd admin
```

```nginx
location /admin/ {
    auth_basic "Área restringida";
    auth_basic_user_file /etc/nginx/.htpasswd;
}
```

---

## Cabeceras de seguridad

```nginx
server {
    # HSTS (forzar HTTPS)
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;

    # Protección contra clickjacking
    add_header X-Frame-Options "SAMEORIGIN" always;

    # Prevenir MIME-type sniffing
    add_header X-Content-Type-Options "nosniff" always;

    # Activar XSS filter en navegadores antiguos
    add_header X-XSS-Protection "1; mode=block" always;

    # Content Security Policy (CSP)
    add_header Content-Security-Policy "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline';" always;

    # Referrer Policy
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # Permissions Policy (controlar APIs del navegador)
    add_header Permissions-Policy "camera=(), microphone=(), geolocation=()" always;

    # Ocultar versión de nginx
    server_tokens off;
}
```

### Verificar cabeceras

```bash
curl -sI https://ejemplo.com | grep -iE "strict-transport-security|x-frame-options|x-content-type-options"
```

---

## Load balancing

Distribuye tráfico entre múltiples servidores backend.

```nginx
http {
    # Definir grupo de upstream (backends)
    upstream backend_servers {
        # Métodos de balanceo:
        # (por defecto) round-robin
        # ip_hash         → misma IP → mismo backend (sesiones persistentes)
        # least_conn      → al backend con menos conexiones
        # least_time      → al backend con menor latencia + conexiones (NGINX Plus)

        server 10.0.0.10:3000 weight=3;   # weight: recibe 3x más tráfico
        server 10.0.0.11:3000 weight=2;
        server 10.0.0.12:3000 weight=1;

        # Health check (NGINX Plus) o manejar fallos manual:
        server 10.0.0.13:3000 backup;     # Solo si los otros fallan
        server 10.0.0.14:3000 down;       # Deshabilitado (mantenimiento)
    }

    server {
        listen 80;
        server_name api.ejemplo.com;

        location / {
            proxy_pass http://backend_servers;
            proxy_http_version 1.1;

            # Reintentar en otro backend si falla
            proxy_next_upstream error timeout http_500 http_502 http_503;
            proxy_next_upstream_tries 3;

            # Timeouts
            proxy_connect_timeout 5;
            proxy_read_timeout 30;

            # Cabeceras
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }
}
```

### Health check básico (sin NGINX Plus)

```bash
#!/bin/bash
# remove_backend.sh — Quitar backend del upstream
# Se usa con nginx reload, cambiando el puerto o marcando "down"
ssh admin@servidor "sudo sed -i 's/server 10.0.0.10:3000;/& down;/' /etc/nginx/sites-enabled/api"
ssh admin@servidor "sudo nginx -s reload"
```

---

## Caché

### Caché de contenido estático (navegador)

```nginx
location ~* \.(jpg|jpeg|png|gif|ico|css|js|woff2)$ {
    expires 30d;             # Cache del navegador por 30 días
    add_header Cache-Control "public, immutable";
    access_log off;          # No loguear archivos estáticos
    log_not_found off;
}
```

### Caché de proxy (nginx guarda respuestas del backend)

```nginx
http {
    # Definir zona de caché: 1GB en /var/cache/nginx, niveles de subdirectorio
    proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=mycache:10m max_size=1g inactive=60m;

    server {
        location / {
            proxy_cache mycache;
            proxy_cache_key "$scheme$request_method$host$request_uri";
            proxy_cache_valid 200 302 60m;    # Cachear 200/302 por 60 min
            proxy_cache_valid 404 1m;         # Cachear 404 por 1 min
            proxy_cache_use_stale error timeout updating;  # Servir cache aunque el backend falle
            proxy_cache_background_update on;

            # Bypass de caché (forzar actualización)
            proxy_cache_bypass $http_cache_control;

            add_header X-Cache-Status $upstream_cache_status;  # HIT/MISS/STALE
            proxy_pass http://backend;
        }
    }
}
```

### Purgar caché

```bash
# Forzar actualización de una URL específica
curl -X PURGE https://ejemplo.com/api/productos/123

# O borrar manualmente
sudo find /var/cache/nginx -type f -delete
```

---

## Logs

### Formato personalizado

```nginx
http {
    # Formato detallado con tiempos
    log_format detallado '$remote_addr - $remote_user [$time_local] '
                         '"$request" $status $body_bytes_sent '
                         '"$http_referer" "$http_user_agent" '
                         '$request_time $upstream_response_time';

    # Formato JSON (para procesar con herramientas)
    log_format json escape=json '{'
        '"time":"$time_local",'
        '"remote_ip":"$remote_addr",'
        '"request":"$request",'
        '"status":$status,'
        '"bytes":$body_bytes_sent,'
        '"referer":"$http_referer",'
        '"user_agent":"$http_user_agent",'
        '"request_time":$request_time,'
        '"upstream_time":"$upstream_response_time",'
        '"cache_status":"$upstream_cache_status"'
    '}';

    # Logs por virtual host
    access_log /var/log/nginx/ejemplo.com.access.log detallado;
    error_log /var/log/nginx/ejemplo.com.error.log;
}
```

### Logs en JSON (para parsear con herramientas)

```bash
# Analizar logs con jq
cat /var/log/nginx/access.log | jq 'select(.status >= 500) | {time, request, status}'

# Top rutas lentas
cat /var/log/nginx/access.log | jq -r 'select(.request_time > 2) | [.request_time, .request] | @tsv' | sort -rn
```

### Log rotation (logrotate)

```nginx
# /etc/logrotate.d/nginx
/var/log/nginx/*.log {
    daily
    missingok
    rotate 14          # Guardar 14 días
    compress           # Comprimir logs viejos
    delaycompress
    notifempty
    create 0640 www-data adm
    sharedscripts
    postrotate
        if [ -f /var/run/nginx.pid ]; then
            kill -USR1 `cat /var/run/nginx.pid`  # Señal para reabrir logs
        fi
    endscript
}
```

---

## Optimización

### worker_processes y worker_connections

```nginx
worker_processes auto;       # = número de CPUs
worker_rlimit_nofile 4096;   # Límite de archivos abiertos

events {
    worker_connections 2048; # Conexiones simultáneas por worker
    use epoll;               # E/S eficiente en Linux
    multi_accept on;
}
```

### sysctl para nginx

```bash
# /etc/sysctl.d/99-nginx.conf

# Aumentar backlog de conexiones
net.core.somaxconn = 65535

# Aumentar pool de puertos efímeros
net.ipv4.ip_local_port_range = 1024 65535

# Reutilizar TIME_WAIT rápidamente
net.ipv4.tcp_fin_timeout = 15

# Aumentar buffers TCP
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216

# Habilitar TCP Fast Open
net.ipv4.tcp_fastopen = 3
```

```bash
sudo sysctl -p /etc/sysctl.d/99-nginx.conf
```

### open_file_cache (caché de archivos abiertos)

```nginx
http {
    open_file_cache max=1000 inactive=20s;
    open_file_cache_valid 30s;
    open_file_cache_min_uses 2;
    open_file_cache_errors on;
}
```

---

## Escenarios

### 1. Servidor web para PYME

```nginx
# /etc/nginx/sites-available/pyme.com
server {
    listen 80;
    listen [::]:80;
    server_name pyme.com www.pyme.com;

    # Redirigir a HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name pyme.com www.pyme.com;

    ssl_certificate /etc/letsencrypt/live/pyme.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/pyme.com/privkey.pem;

    root /var/www/pyme.com/html;
    index index.html;

    # Caché de archivos estáticos
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    # Proxy a app Node.js
    location /app/ {
        proxy_pass http://localhost:3000/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # Área admin con autenticación básica
    location /admin/ {
        auth_basic "Admin";
        auth_basic_user_file /etc/nginx/.htpasswd;
        proxy_pass http://localhost:3000/;
    }

    # Rate limiting para API
    location /api/ {
        limit_req zone=api burst=20 nodelay;
        proxy_pass http://localhost:3000;
    }

    # Cabeceras de seguridad
    add_header Strict-Transport-Security "max-age=63072000" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    server_tokens off;
}
```

### 2. Proxy inverso con múltiples backends

```nginx
upstream node_apps {
    least_conn;
    server 10.0.0.10:3000;
    server 10.0.0.11:3000;
    server 10.0.0.12:3000;
}

server {
    listen 80;
    server_name app.ejemplo.com;

    location / {
        proxy_pass http://node_apps;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

### 3. Servir múltiples apps por subdominio

```nginx
# app1.ejemplo.com → backend:3001
# app2.ejemplo.com → backend:3002

server {
    listen 80;
    server_name app1.ejemplo.com;
    location / { proxy_pass http://localhost:3001; proxy_set_header Host $host; }
}

server {
    listen 80;
    server_name app2.ejemplo.com;
    location / { proxy_pass http://localhost:3002; proxy_set_header Host $host; }
}
```

### 4. Analizar logs con herramientas del repo

```bash
# Top 10 IPs que más peticiones hacen
awk '{print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -rn | head -10

# Rutas más lentas (campo $request_time)
awk '{print $NF, $7}' /var/log/nginx/access.log | sort -rn | head -10

# Códigos de estado
awk '{print $9}' /var/log/nginx/access.log | sort | uniq -c | sort -rn

# Peticiones por minuto
awk '{split($4,t,"[/:]"); min=t[4]":"t[5]; m[min]++} END{for(i in m) print i, m[i]}' \
  /var/log/nginx/access.log | sort

# Detectar 404 desde una misma IP (posible escaneo)
awk '$9 == 404 {print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -rn | head -10

# Errores 500
grep " 500 " /var/log/nginx/error.log

# Tasa de error (4xx+5xx / total)
TOTAL=$(wc -l < /var/log/nginx/access.log)
ERRORES=$(awk '$9 ~ /^[45]/' /var/log/nginx/access.log | wc -l)
echo "scale=2; $ERRORES * 100 / $TOTAL" | bc
```

---

## Uno-liners

```bash
# Probar sintaxis
nginx -t

# Recargar configuración sin cortar servicio
nginx -s reload

# Ver configuración completa
nginx -T

# Ver módulos compilados
nginx -V 2>&1 | tr ' ' '\n'

# Ver virtual hosts activos
ls -l /etc/nginx/sites-enabled/

# Test de estrés básico
ab -n 1000 -c 100 http://localhost/

# Ver conexiones activas a nginx
ss -tlnp | grep nginx

# Cache HIT/MISS rate
awk '{print $NF}' /var/log/nginx/access.log | grep -c HIT

# Peticiones por segundo
tail -f /var/log/nginx/access.log | pv -l -i 1 > /dev/null
```
