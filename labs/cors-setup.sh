#!/bin/sh
# cors-setup.sh — Configura nginx para el lab de CORS
# Uso: sh cors-setup.sh frontend|api
# Sin bashismos (POSIX compliant)

set -e

MODE="${1:-api}"
CONF_DIR="/etc/nginx/conf.d"

if [ "$MODE" = "frontend" ]; then
    echo "=== Configurando FRONTEND (puerto 80) ==="

    cat > "$CONF_DIR/default.conf" << 'NGINX_EOF'
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
NGINX_EOF

    # Crear página HTML que hace fetch() a la API cross-origin
    cat > /usr/share/nginx/html/index.html << 'HTML_EOF'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>CORS Lab — Frontend</title>
    <style>
        body { font-family: monospace; margin: 2rem; background: #1a1a2e; color: #eee; }
        h1 { color: #e94560; }
        button { padding: 0.5rem 1rem; margin: 0.5rem; cursor: pointer; }
        pre { background: #16213e; padding: 1rem; border-radius: 4px; overflow-x: auto; }
        .ok { color: #0f0; }
        .err { color: #f00; }
    </style>
</head>
<body>
    <h1>CORS Lab — Frontend</h1>
    <p>Este frontend corre en <code>localhost:3000</code> e intenta llamar a la API en <code>localhost:8080</code>.</p>

    <button onclick="testGet()">GET /data</button>
    <button onclick="testPost()">POST /data</button>
    <button onclick="testOptions()">OPTIONS (preflight)</button>

    <h2>Resultado:</h2>
    <pre id="output">Esperando acción...</pre>

    <script>
        const API = 'http://localhost:8080';

        function log(msg, cls) {
            const el = document.getElementById('output');
            el.className = cls || '';
            el.textContent = msg;
        }

        async function testGet() {
            try {
                const r = await fetch(API + '/data');
                const d = await r.json();
                log('GET /data → OK\n' + JSON.stringify(d, null, 2), 'ok');
            } catch (e) {
                log('GET /data → ERROR CORS\n' + e.message + '\n\nAbre DevTools (F12) → Console para ver el error completo.', 'err');
            }
        }

        async function testPost() {
            try {
                const r = await fetch(API + '/data', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ test: true })
                });
                const d = await r.json();
                log('POST /data → OK\n' + JSON.stringify(d, null, 2), 'ok');
            } catch (e) {
                log('POST /data → ERROR CORS\n' + e.message + '\n\nLas requests POST complejas requieren preflight OPTIONS.', 'err');
            }
        }

        async function testOptions() {
            try {
                const r = await fetch(API + '/data', { method: 'OPTIONS' });
                log('OPTIONS /data → ' + r.status + ' ' + r.statusText + '\nHeaders CORS: ' +
                    (r.headers.get('access-control-allow-origin') || 'NO PRESENTE'), r.ok ? 'ok' : 'err');
            } catch (e) {
                log('OPTIONS /data → ERROR\n' + e.message, 'err');
            }
        }
    </script>
</body>
</html>
HTML_EOF

    echo "Frontend configurado en http://localhost:3000"
    echo "Abre el browser y hace click en los botones para ver errores CORS."

elif [ "$MODE" = "api" ]; then
    echo "=== Configurando API SIN headers CORS (puerto 80) ==="

    # API sin headers CORS — el browser bloqueará las requests
    cat > "$CONF_DIR/default.conf" << 'NGINX_EOF'
server {
    listen 80;
    server_name _;

    # Endpoint de healthcheck
    location /health {
        return 200 '{"status":"ok"}';
        add_header Content-Type application/json;
    }

    # Endpoint de datos — SIN headers CORS
    # El browser bloqueará requests desde localhost:3000
    location /data {
        if ($request_method = 'OPTIONS') {
            return 405;
        }
        return 200 '{"message":"Datos desde la API","timestamp":"2024-01-15T10:30:00Z","items":[1,2,3]}';
        add_header Content-Type application/json;
    }

    location / {
        return 200 '{"service":"cors-api","status":"running","hint":"Usa /data para probar CORS"}';
        add_header Content-Type application/json;
    }
}
NGINX_EOF

    echo "API configurada en http://localhost:8080"
    echo ""
    echo "Endpoints:"
    echo "  GET  /health  → healthcheck"
    echo "  GET  /data    → datos JSON (sin CORS headers)"
    echo "  OPTIONS /data → devuelve 405 (preflight no soportado)"
    echo ""
    echo "Para verificar que falta CORS:"
    echo "  docker exec cors-client curl -s -D - -H 'Origin: http://cors-frontend' http://cors-api/data"

else
    echo "Uso: sh cors-setup.sh frontend|api"
    exit 1
fi

# Iniciar nginx en foreground
exec nginx -g 'daemon off;'
