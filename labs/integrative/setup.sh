#!/bin/sh
# setup.sh — Configura servicios para el proyecto integrador
# Uso: sh setup.sh nginx
# Sin bashismos (POSIX compliant)

set -e

MODE="${1:-nginx}"
CONF_DIR="/etc/nginx/conf.d"
SSL_DIR="/etc/nginx/ssl"

if [ "$MODE" = "nginx" ]; then
    echo "=== Configurando nginx ==="

    mkdir -p "$SSL_DIR"

    # Generar certificado autofirmado
    openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout "$SSL_DIR/server.key" \
        -out "$SSL_DIR/server.crt" \
        -subj "/C=AR/ST=BA/L=CABA/O=PYME/OU=IT/CN=web-nginx" \
        2>/dev/null

    # Config con proxy_pass a la app (el estudiante debe completar)
    cat > "$CONF_DIR/default.conf" << 'NGINX_EOF'
server {
    listen 80;
    server_name _;

    # TODO: Redirigir HTTP a HTTPS
    # return 301 https://$host$request_uri;

    location / {
        # TODO: Configurar proxy_pass a web-app:3000
        # proxy_pass http://web-app:3000;
        # proxy_set_header Host $host;
        # proxy_set_header X-Real-IP $remote_addr;

        return 200 '{"status":"nginx ok","hint":"Configura proxy_pass a web-app:3000"}';
        add_header Content-Type application/json;
    }

    location /health {
        return 200 '{"status":"nginx ok"}';
        add_header Content-Type application/json;
    }
}

server {
    listen 443 ssl;
    server_name _;

    ssl_certificate     /etc/nginx/ssl/server.crt;
    ssl_certificate_key /etc/nginx/ssl/server.key;

    # TODO: Configurar proxy_pass para HTTPS
    location / {
        return 200 '{"status":"nginx ssl ok","hint":"Configura proxy_pass a web-app:3000"}';
        add_header Content-Type application/json;
    }
}
NGINX_EOF

    echo "Nginx configurado. Completar los TODOs en /etc/nginx/conf.d/default.conf"
    echo "Luego ejecutar: nginx -s reload"

else
    echo "Uso: sh setup.sh nginx"
    exit 1
fi

exec nginx -g 'daemon off;'
