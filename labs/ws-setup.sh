#!/bin/sh
# ws-setup.sh — Configura nginx para el lab de WebSocket
# Uso: sh ws-setup.sh nginx
# Sin bashismos (POSIX compliant)

set -e

MODE="${1:-nginx}"
CONF_DIR="/etc/nginx/conf.d"

if [ "$MODE" = "nginx" ]; then
    echo "=== Configurando NGINX proxy para WebSocket ==="
    echo ""
    echo "PROBLEMA: nginx NO está configurado para WebSocket."
    echo "  - Sin proxy_set_header Upgrade"
    echo "  - Sin proxy_set_header Connection"
    echo "  - proxy_read_timeout = 60s (default)"
    echo ""
    echo "Las conexiones WebSocket se caerán tras 60 segundos."
    echo ""

    # Configuración "rota" — sin headers de WebSocket y timeout corto
    cat > "$CONF_DIR/default.conf" << 'NGINX_EOF'
server {
    listen 80;
    server_name _;

    # Healthcheck endpoint
    location /health {
        return 200 '{"status":"ok","hint":"Proxy sin configuración WebSocket"}';
        add_header Content-Type application/json;
    }

    # Proxy al backend WebSocket
    # PROBLEMA: falta configuración para WebSocket
    location /ws {
        proxy_pass http://ws-backend:8080;
        proxy_http_version 1.1;

        # FALTAN estos headers (necesarios para WebSocket):
        # proxy_set_header Upgrade $http_upgrade;
        # proxy_set_header Connection "upgrade";

        # Timeout default de 60s — muy corto para WebSocket
        proxy_read_timeout 60s;
        proxy_send_timeout 60s;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # Página informativa
    location / {
        return 200 '{"service":"ws-nginx","status":"running","problem":"WebSocket no configurado","hint":"Usa /ws para probar timeout"}';
        add_header Content-Type application/json;
    }
}
NGINX_EOF

    echo "Proxy configurado en http://localhost:8086"
    echo ""
    echo "Endpoints:"
    echo "  GET  /health → healthcheck"
    echo "  WS   /ws     → proxy a ws-backend (timeout 60s)"
    echo ""
    echo "Para probar el timeout:"
    echo "  docker exec -it ws-client websocat ws://ws-nginx/ws"
    echo "  (esperar 60 segundos sin enviar datos → conexión se cierra)"
    echo ""
    echo "Para ver los logs del timeout:"
    echo "  docker logs ws-nginx 2>&1 | grep -i timeout"

else
    echo "Uso: sh ws-setup.sh nginx"
    exit 1
fi

# Iniciar nginx en foreground
exec nginx -g 'daemon off;'
