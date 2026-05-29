# curl — Guía completa

**Nivel:** 🟡 Intermedio
**Archivos de práctica:** Sistema en vivo
**Ver escenarios relacionados:** [`web/01-performance`](../scenarios/web/01-performance-and-error-analysis.md)

## ⚡ Quick command

`curl -sI https://example.com`

## 📑 Índice

1. [¿Qué es curl?](#qué-es-curl)
2. [Sintaxis básica](#sintaxis-básica)
3. [Métodos HTTP](#métodos-http)
4. [Cabeceras](#cabeceras)
5. [Datos y formularios](#datos-y-formularios)
6. [Autenticación](#autenticación)
7. [Cookies](#cookies)
8. [Certificados SSL/TLS](#certificados-ssltls)
9. [Tiempos de espera y reintentos](#tiempos-de-espera-y-reintentos)
10. [Seguimiento de redirecciones](#seguimiento-de-redirecciones)
11. [Salida y verbosidad](#salida-y-verbosidad)
12. [Subida de archivos](#subida-de-archivos)
13. [Escenarios reales](#escenarios-reales)
14. [Diagnóstico y depuración](#diagnóstico-y-depuración)
15. [Escenarios de seguridad](#escenarios-de-seguridad)
16. [Uno-liners imprescindibles](#uno-liners-imprescindibles)

---

## 🧠 ¿Qué es curl?

**curl** transfiere datos desde o hacia un servidor usando uno de los protocolos soportados (HTTP, HTTPS, FTP, SFTP, SCP, LDAP, SMTP, POP3, IMAP, etc.). Es el "navaja suiza" de las transferencias de red en línea de comandos.

### Instalación

```bash
# Verificar
curl --version

# Instalar
sudo apt install curl    # Debian/Ubuntu
sudo yum install curl    # CentOS/RHEL
```

---

## 📝 Sintaxis básica

```bash
curl [opciones] URL
```

```bash
# GET simple (el contenido se imprime en stdout)
curl https://api.example.com/users

# Guardar salida en archivo
curl -o archivo.html https://example.com

# Usar el nombre remoto
curl -O https://example.com/archivo.zip

# Silencioso (sin barra de progreso)
curl -s https://api.example.com/users
```

### -o vs -O

| Opción | Descripción |
|--------|-------------|
| `-o archivo` | Guarda la respuesta en `archivo` |
| `-O` | Guarda con el nombre del archivo remoto |

---

## Métodos HTTP

| Método | Opción curl | Descripción |
|--------|-------------|-------------|
| GET | (por defecto) | Obtener recurso |
| POST | `-X POST -d "data"` | Crear recurso |
| PUT | `-X PUT -d "data"` | Actualizar recurso |
| PATCH | `-X PATCH -d "data"` | Actualización parcial |
| DELETE | `-X DELETE` | Eliminar recurso |
| HEAD | `-I` | Solo cabeceras |
| OPTIONS | `-X OPTIONS` | Métodos disponibles |

```bash
# GET (por defecto)
curl https://api.example.com/users/123

# POST
curl -X POST -d '{"name":"Juan"}' https://api.example.com/users

# PUT
curl -X PUT -d '{"name":"Pedro"}' https://api.example.com/users/123

# DELETE
curl -X DELETE https://api.example.com/users/123

# HEAD (solo cabeceras de respuesta)
curl -I https://example.com

# OPTIONS (qué métodos acepta el servidor)
curl -X OPTIONS https://api.example.com
```

---

## Cabeceras

### Cabeceras de solicitud (-H)

```bash
# Cabecera personalizada
curl -H "Authorization: Bearer token123" https://api.example.com

# Múltiples cabeceras
curl -H "Accept: application/json" -H "X-API-Key: 12345" https://api.example.com

# User-Agent personalizado
curl -H "User-Agent: Mozilla/5.0" https://example.com

# Content-Type
curl -H "Content-Type: application/json" -d '{"key":"value"}' https://api.example.com
```

### Cabeceras de respuesta (-I)

```bash
# Ver cabeceras de respuesta
curl -I https://example.com

# Solo código de estado HTTP
curl -s -o /dev/null -w "%{http_code}" https://example.com
```

---

## Datos y formularios

### -d (data)

Envía datos en el cuerpo de la petición (por defecto POST).

```bash
# Datos simples (application/x-www-form-urlencoded)
curl -d "nombre=Juan&edad=30" https://ejemplo.com/formulario

# Datos JSON (necesita -H Content-Type)
curl -H "Content-Type: application/json" -d '{"nombre":"Juan","edad":30}' https://api.ejemplo.com

# Datos desde archivo
curl -d @datos.json -H "Content-Type: application/json" https://api.ejemplo.com

# URL-encoded con --data-urlencode
curl --data-urlencode "nombre=Juan Pérez" https://ejemplo.com/formulario
```

### -F (form: multipart/form-data)

Para subir archivos o formularios multipart.

```bash
# Subir archivo
curl -F "archivo=@/ruta/local/foto.jpg" https://ejemplo.com/subir

# Formulario con archivo y campos
curl -F "nombre=Juan" -F "avatar=@foto.jpg" https://ejemplo.com/perfil

# Varios archivos
curl -F "file1=@doc1.pdf" -F "file2=@doc2.pdf" https://ejemplo.com/subir

# Especificar tipo MIME
curl -F "imagen=@foto.png;type=image/png" https://ejemplo.com/subir

# Cambiar nombre del archivo en el servidor
curl -F "file=@foto.jpg;filename=nuevo_nombre.jpg" https://ejemplo.com/subir
```

### -G (GET con datos en URL)

```bash
# GET con parámetros (en lugar de POST)
curl -G -d "q=busqueda" -d "page=1" https://api.ejemplo.com/search
# Equivale a: https://api.ejemplo.com/search?q=busqueda&page=1
```

---

## Autenticación

### Básica (-u)

```bash
# Autenticación básica
curl -u usuario:contraseña https://api.ejemplo.com/protegido

# Sin contraseña (la pide interactivamente)
curl -u usuario https://api.ejemplo.com/protegido
```

### Bearer token

```bash
# Token JWT/OAuth
curl -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIs..." https://api.ejemplo.com

# O usando -H
curl -H "Authorization: Bearer $(cat token.txt)" https://api.ejemplo.com
```

### API Key

```bash
# Como cabecera
curl -H "X-API-Key: abc123" https://api.ejemplo.com

# Como query parameter
curl "https://api.ejemplo.com?api_key=abc123"
```

### Digest

```bash
curl --digest -u usuario:contraseña https://ejemplo.com/digest-auth
```

### Negotiate (Kerberos/NTLM)

```bash
curl --negotiate -u : https://ejemplo.com/kerberos
```

---

## Cookies

### Guardar cookies (-c)

```bash
# Guardar cookies del servidor a un archivo
curl -c cookies.txt https://ejemplo.com/login
```

### Enviar cookies (-b)

```bash
# Enviar cookies desde archivo
curl -b cookies.txt https://ejemplo.com/dashboard

# Enviar cookie inline
curl -b "session=abc123; preferencias=dark" https://ejemplo.com
```

### Sesión completa (login + uso autenticado)

```bash
# 1. Login (guarda cookie)
curl -c cookies.txt -d "user=admin&pass=1234" https://ejemplo.com/login

# 2. Usar sesión (envía cookie guardada)
curl -b cookies.txt https://ejemplo.com/dashboard
```

### --cookie-jar

```bash
# Especificar archivo para guardar/leer cookies
curl --cookie-jar sesion.txt -d "user=admin&pass=1234" https://ejemplo.com/login
curl --cookie sesion.txt https://ejemplo.com/dashboard
```

---

## Certificados SSL/TLS

### -k (insecure)

Omite la validación del certificado SSL. **Ojo**: inseguro, solo para tests.

```bash
# Aceptar certificado auto-firmado
curl -k https://servidor-interno.local

# O con --insecure
curl --insecure https://192.168.1.100
```

### --cacert

Especificar un CA bundle personalizado.

```bash
curl --cacert /ruta/mi-ca.pem https://servidor-interno.local
```

### --cert y --key

Certificado de cliente para autenticación mutua (mTLS).

```bash
curl --cert cliente.pem --key cliente-key.pem https://api.ejemplo.com
```

### Verificación estricta

```bash
# Por defecto curl verifica SSL. Si falla:
# curl: (60) SSL certificate problem: self signed certificate
# → El certificado es auto-firmado o no confiable
```

### Probar SSL de un servidor

```bash
# Ver cadena de certificados
curl -vI https://example.com 2>&1 | grep -E "Server certificate|subject|issuer|start date|expire date"

# Ver si el certificado expira pronto
echo | openssl s_client -connect example.com:443 2>/dev/null | openssl x509 -noout -dates
```

---

## Tiempos de espera y reintentos

### --connect-timeout

Tiempo máximo para establecer la conexión TCP.

```bash
# Timeout de conexión: 5 segundos
curl --connect-timeout 5 https://servidor-lento.com
```

### --max-time

Tiempo máximo total para la transferencia completa.

```bash
# Timeout total: 30 segundos
curl --max-time 30 https://servidor-lento.com/archivo-grande.zip
```

### --retry

Reintentos automáticos en caso de error transitorio.

```bash
# Reintentar hasta 3 veces
curl --retry 3 https://api.ejemplo.com

# Reintentar con espera (segundos entre reintentos)
curl --retry 3 --retry-delay 5 https://api.ejemplo.com

# Reintentar en todos los errores (no solo transitorios)
curl --retry 3 --retry-all-errors https://api.ejemplo.com

# Espera máxima entre reintentos
curl --retry 3 --retry-max-time 60 https://api.ejemplo.com
```

### --limit-rate

Limitar velocidad de descarga.

```bash
# Limitar a 1 MB/s
curl --limit-rate 1M -O https://ejemplo.com/archivo-grande.zip
```

---

## Seguimiento de redirecciones

### -L (follow redirects)

Sigue redirecciones HTTP (301, 302, 303, 307, 308).

```bash
# Sin -L: muestra la redirección, no la sigue
curl -I http://example.com
# HTTP/1.1 301 Moved Permanently
# Location: https://example.com

# Con -L: sigue la redirección hasta el destino final
curl -L http://example.com

# Límite de redirecciones
curl -L --max-redirs 5 http://ejemplo.com
```

### --location-trusted

Envía credenciales también a los destinos redirigidos (por defecto no).

```bash
curl -u user:pass -L --location-trusted http://ejemplo.com/login
```

---

## Salida y verbosidad

### Verbosidad

| Opción | Descripción |
|--------|-------------|
| `-v` | Verboso (cabeceras, handshake SSL, tiempos) |
| `-vv` | Muy verboso |
| `--trace` | Traza completa de datos enviados/recibidos |
| `--trace-ascii` | Traza en ASCII (legible) |
| `-s` | Silencioso (sin barra de progreso ni errores) |
| `-S` | Muestra errores (con -s, para ver solo errores) |

```bash
# Verboso: ver cabeceras de solicitud y respuesta
curl -v https://api.ejemplo.com

# Traza detallada (para depuración profunda)
curl --trace-ascii traza.txt https://api.ejemplo.com

# Silencioso + solo errores
curl -sS https://api.ejemplo.com

# Solo código de estado HTTP
curl -s -o /dev/null -w "%{http_code}" https://ejemplo.com
```

### -w (write-out)

Formatea la salida con variables específicas después de la transferencia.

```bash
# Tiempo total
curl -s -o /dev/null -w "Tiempo total: %{time_total}s\n" https://example.com

# Desglose de tiempos
curl -s -o /dev/null -w "
    Tiempo de conexión: %{time_connect}s
    Tiempo hasta TLS: %{time_appconnect}s
    Tiempo hasta primer byte: %{time_starttransfer}s
    Tiempo total: %{time_total}s
    Velocidad: %{speed_download} B/s
    Tamaño: %{size_download} bytes
    Código HTTP: %{http_code}
" https://example.com
```

### Variables de -w

| Variable | Descripción |
|----------|-------------|
| `%{http_code}` | Código de estado HTTP |
| `%{time_total}` | Tiempo total de la transferencia |
| `%{time_connect}` | Tiempo para conectar TCP |
| `%{time_appconnect}` | Tiempo para handshake SSL/TLS |
| `%{time_starttransfer}` | Tiempo hasta primer byte |
| `%{time_redirect}` | Tiempo en redirecciones |
| `%{size_download}` | Bytes descargados |
| `%{size_upload}` | Bytes subidos |
| `%{speed_download}` | Velocidad de descarga |
| `%{speed_upload}` | Velocidad de subida |
| `%{content_type}` | Content-Type de la respuesta |
| `%{url_effective}` | URL final tras redirecciones |
| `%{ssl_verify_result}` | Resultado de verificación SSL |
| `%{num_redirects}` | Número de redirecciones seguidas |
| `%{remote_ip}` | IP del servidor remoto |
| `%{remote_port}` | Puerto del servidor remoto |
| `%{local_ip}` | IP local usada |
| `%{local_port}` | Puerto local usado |

### @output-file con -w

```bash
# Guardar formato en archivo y usarlo
echo "Código: %{http_code}\nTiempo: %{time_total}s\nURL: %{url_effective}" > formato.txt
curl -s -o /dev/null -w @formato.txt https://example.com
```

---

## Subida de archivos

### FTP

```bash
# Subir archivo por FTP
curl -T archivo.zip ftp://servidor.com/subir/

# Con autenticación
curl -T archivo.zip -u usuario:contraseña ftp://servidor.com/subir/
```

### SFTP/SCP

```bash
# Subir por SFTP
curl -T archivo.zip sftp://servidor.com/ruta/ --key clave-privada
```

### HTTP PUT

```bash
# Subir con PUT
curl -T archivo.zip -H "Content-Type: application/zip" https://api.ejemplo.com/subir
```

---

## Escenarios reales

### 1. Probar API REST

```bash
# GET
curl -s https://api.github.com/users/octocat | jq '.name, .bio'

# POST con JSON
curl -s -X POST \
  -H "Content-Type: application/json" \
  -d '{"title":"Bug report","body":"Descripción"}' \
  -H "Authorization: token ghp_xxxx" \
  https://api.github.com/repos/user/repo/issues

# PUT
curl -s -X PUT \
  -H "Content-Type: application/json" \
  -d '{"name":"nuevo-nombre"}' \
  https://api.ejemplo.com/items/123
```

### 2. Monitoreo de salud de endpoints

```bash
# Verificar que un servicio responde 200
curl -s -o /dev/null -w "%{http_code}" https://ejemplo.com/health

# Script de health check
check_url() {
  local url=$1
  local code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$url")
  if [ "$code" = "200" ]; then
    echo "OK: $url ($code)"
  else
    echo "FALLO: $url ($code)"
  fi
}
check_url https://ejemplo.com
check_url https://ejemplo.com/api
```

### 3. Medir tiempos de respuesta

```bash
# Benchmark de latencia
for i in {1..10}; do
  curl -s -o /dev/null -w "%{time_total}\n" https://api.ejemplo.com
done | awk '{sum+=$1; count++} END {print "Promedio:", sum/count, "s"}'

# Comparar servidores
for url in https://servidor1.com https://servidor2.com; do
  echo -n "$url: "
  curl -s -o /dev/null -w "%{time_total}s\n" "$url"
done
```

### 4. Descargar archivos

```bash
# Descargar con barra de progreso
curl -O https://ejemplo.com/archivo.zip

# Descargar con nombre personalizado
curl -o proyecto.zip https://ejemplo.com/archivo.zip

# Descargar desde archivo enlazado
curl -L -O "https://github.com/user/repo/releases/download/v1.0/archivo.tar.gz"
```

### 5. Probar web sockets

```bash
# curl no maneja WS nativamente, pero se puede probar upgrade
curl -s -H "Connection: Upgrade" -H "Upgrade: websocket" -H "Sec-WebSocket-Version: 13" \
  -H "Sec-WebSocket-Key: $(echo -n 'clave' | base64)" \
  https://ejemplo.com/ws 2>&1
```

### 6. Verificar cabeceras de seguridad

```bash
# Ver cabeceras de seguridad HTTP
curl -sI https://ejemplo.com | grep -iE "strict-transport-security|x-frame-options|x-content-type-options|content-security-policy|x-xss-protection"

# Score de seguridad
HEADERS=$(curl -sI https://ejemplo.com)
echo "$HEADERS" | grep -q "Strict-Transport-Security" && echo "HSTS: OK" || echo "HSTS: FALTA"
echo "$HEADERS" | grep -q "X-Frame-Options" && echo "XFO: OK" || echo "XFO: FALTA"
```

### 7. Login y sesión

```bash
# Login, guardar cookie, usar sesión
curl -c sesion.txt -d "username=admin&password=pass123" https://ejemplo.com/login
curl -b sesion.txt https://ejemplo.com/dashboard
curl -b sesion.txt -X POST -d "action=delete&id=5" https://ejemplo.com/items/delete
```

---

## Diagnóstico y depuración

### 1. Error de conexión (timeout)

```bash
curl -v --connect-timeout 5 https://servidor-caido.com
# curl: (28) Connection timed out after 5001 milliseconds
# → Servidor caído, firewall bloquea, o red caída
```

### 2. Error de resolución DNS

```bash
curl -v https://dominioquenoexiste.com
# curl: (6) Could not resolve host: dominioquenoexiste.com
# → DNS no puede resolver el nombre
```

### 3. Error de certificado SSL

```bash
curl -v https://servidor-con-certificado-expirado.com
# curl: (60) SSL certificate problem: certificate has expired
# → Certificado caducado
```

### 4. Error 403 Forbidden

```bash
curl -v https://api.ejemplo.com
# HTTP/1.1 403 Forbidden
# → Falta autenticación o no tienes permisos
```

### 5. Error 404 Not Found

```bash
curl -v https://ejemplo.com/ruta-inexistente
# HTTP/1.1 404 Not Found
# → La URL no existe
```

### 6. Error 429 Too Many Requests

```bash
curl -v https://api.ejemplo.com
# HTTP/1.1 429 Too Many Requests
# Retry-After: 3600
# → Rate limiting activo. Esperar antes de reintentar.
```

### 7. Redirección (301/302)

```bash
curl -v http://ejemplo.com
# HTTP/1.1 301 Moved Permanently
# Location: https://ejemplo.com
# → Sin -L, curl no sigue. Con -L, sigue a la nueva URL.
```

### 8. Ver todo el flujo de red

```bash
curl --trace-ascii /dev/stdout https://ejemplo.com
# Muestra cada byte enviado y recibido (muy detallado)
```

### 9. Usar proxy

```bash
# HTTP proxy
curl -x http://proxy.ejemplo.com:8080 https://api.ejemplo.com

# Proxy con autenticación
curl -x http://proxy.ejemplo.com:8080 -U usuario:contraseña https://api.ejemplo.com

# SOCKS5 proxy
curl --socks5 127.0.0.1:1080 https://ejemplo.com
```

---

## Escenarios de seguridad

### 1. Verificar HSTS

```bash
# Strict-Transport-Security
curl -sI https://ejemplo.com | grep -i "strict-transport-security"
# max-age=31536000; includeSubDomains; preload
```

### 2. Verificar CORS

```bash
# Probar CORS
curl -H "Origin: https://otro-sitio.com" -H "Access-Control-Request-Method: GET" \
  -X OPTIONS https://api.ejemplo.com -v 2>&1 | grep -i "access-control"
```

### 3. Fingerprinting de servidores

```bash
# Determinar software del servidor
curl -sI https://ejemplo.com | grep -iE "server|x-powered-by|x-aspnet-version"
```

### 4. Detectar IP real detrás de CDN

```bash
# Ver IP del servidor que realmente responde
curl -s -o /dev/null -w "%{remote_ip}" https://ejemplo.com

# Con registro dig: comparar IPs de CDN vs directa
echo "CDN IP: $(curl -s -o /dev/null -w '%{remote_ip}' https://ejemplo.com)"
echo "DNS A: $(dig +short ejemplo.com)"
```

### 5. Probar protocolos y versiones TLS

```bash
# Probar TLS 1.2
curl --tlsv1.2 https://ejemplo.com

# Probar TLS 1.3
curl --tlsv1.3 https://ejemplo.com

# Prohibir TLS 1.0 y 1.1
curl --tls-max 1.2 https://ejemplo.com

# Ver versión TLS negociada
curl -vI https://ejemplo.com 2>&1 | grep "TLS handshake"
```

---

## 💡 Uno-liners imprescindibles

```bash
# GET simple
curl https://api.ejemplo.com

# POST JSON
curl -X POST -H "Content-Type: application/json" -d '{"key":"value"}' URL

# Solo cabeceras
curl -I https://ejemplo.com

# Código HTTP
curl -s -o /dev/null -w "%{http_code}" https://ejemplo.com

# Guardar archivo
curl -O https://ejemplo.com/archivo.zip

# Seguir redirecciones
curl -L http://ejemplo.com

# Autenticación básica
curl -u user:pass https://ejemplo.com

# Bearer token
curl -H "Authorization: Bearer token" URL

# Cookies (guardar y usar)
curl -c cookies.txt -b cookies.txt URL

# SSL inseguro (solo test)
curl -k https://servidor-interno

# Timeout
curl --connect-timeout 5 --max-time 30 URL

# Reintentos
curl --retry 3 --retry-delay 5 URL

# Límite de velocidad
curl --limit-rate 500K -O URL

# Verboso
curl -v URL

# Solo tiempos
curl -s -o /dev/null -w "TCP: %{time_connect}s\nTLS: %{time_appconnect}s\nTTFB: %{time_starttransfer}s\nTotal: %{time_total}s\n" URL

# IP del servidor
curl -s -o /dev/null -w "%{remote_ip}\n" https://ejemplo.com

# Subir archivo (multipart)
curl -F "file=@local.txt" https://ejemplo.com/subir

# Subir archivo (PUT)
curl -T archivo.zip URL

# Proxy
curl -x http://proxy:8080 URL

# User-Agent personalizado
curl -H "User-Agent: Mozilla/5.0" URL

# Silent mode
curl -sS URL

# Ping HTTP (comprobar que un sitio responde 200)
curl -s -o /dev/null -w "%{http_code}" https://ejemplo.com/health | grep -q 200 && echo "UP" || echo "DOWN"
```
