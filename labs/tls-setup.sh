#!/bin/sh
# tls-setup.sh — Genera certificado TLS EXPIRADO y configura nginx
# Para practicar detección y renovación de certificados

set -e

SSL_DIR="/etc/nginx/ssl"
CONF_DIR="/etc/nginx/conf.d"

echo "=== Generando certificado TLS EXPIRADO ==="

mkdir -p "$SSL_DIR"

# Generar certificado que expiró hace 30 días
# -days -30 = expirado hace 30 días
openssl req -x509 -nodes -days -30 \
    -newkey rsa:2048 \
    -keyout "$SSL_DIR/server.key" \
    -out "$SSL_DIR/server.crt" \
    -subj "/C=AR/ST=Buenos Aires/L=CABA/O=Lab/OU=Sysadmin/CN=nginx-tls-expired" \
    -addext "subjectAltName=DNS:nginx-tls-expired,DNS:localhost" \
    2>/dev/null

echo "Certificado generado (EXPIRADO):"
openssl x509 -in "$SSL_DIR/server.crt" -noout -subject -dates

# Configurar nginx con TLS
cat > "$CONF_DIR/default.conf" << 'NGINX_EOF'
server {
    listen 80;
    server_name _;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name nginx-tls-expired;

    ssl_certificate     /etc/nginx/ssl/server.crt;
    ssl_certificate_key /etc/nginx/ssl/server.key;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
NGINX_EOF

# Crear página de ejemplo
echo "<h1>Servidor con TLS expirado</h1><p>Este certificado expiró. Renuevalo.</p>" > /usr/share/nginx/html/index.html

echo ""
echo "=== Nginx configurado con TLS expirado ==="
echo "HTTP:  http://localhost:8085 (redirige a HTTPS)"
echo "HTTPS: https://localhost:8443 (certificado expirado)"
echo ""
echo "Para diagnosticar desde el cliente:"
echo "  docker exec tls-client curl -k https://nginx-tls-expired"
echo "  docker exec tls-client openssl s_client -connect nginx-tls-expired:443"
echo ""
echo "Para renovar el certificado:"
echo "  docker exec nginx-tls-expired sh -c 'openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/server.key -out /etc/nginx/ssl/server.crt -subj \"/CN=nginx-tls-expired\" && nginx -s reload'"
echo ""

# Iniciar nginx en foreground
exec nginx -g 'daemon off;'
