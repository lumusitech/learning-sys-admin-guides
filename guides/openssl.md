# openssl — Guía completa de diagnóstico TLS

**Nivel:** 🟡 Intermedio
**Archivos de práctica:** `labs/docker-compose.tls.yml`
**Ver escenarios relacionados:** [`infrastructure/04-tls-expired`](../scenarios/infrastructure/04-tls-expired.md)

---

## ⚡ Quick command

`openssl s_client -connect example.com:443 -servername example.com`

> ⚠️ Disponible en Alpine (`apk add openssl`). BusyBox incluye una versión recortada sin `s_client`.

---

## ⚡ Quick run

```bash
echo | openssl s_client -connect google.com:443 2>/dev/null | openssl x509 -noout -dates
```

---

## 📑 Índice

1. [¿Qué es openssl?](#qué-es-openssl)
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

## 🧠 ¿Qué es openssl?

openssl es el estándar de facto para operaciones criptográficas en Linux. Como sysadmin, lo usás principalmente para:

- **Diagnóstico TLS**: verificar certificados, cadenas de confianza, handshake
- **Generar certificados**: self-signed para testing, CSRs para producción
- **Convertir formatos**: PEM, DER, PKCS12 (PFX)
- **Hashes y checksums**: SHA, MD5 para integridad
- **Encriptación y desencriptación**: archivos, contraseñas

Es la navaja suiza de la criptografía en terminal.

---

## 🧠 Modelo mental

Pensá en openssl como **`curl` pero para la capa TLS**. Donde `curl` te dice qué devuelve el servidor HTTP, openssl te dice cómo se estableció la conexión segura: qué certificado presentó, qué cipher negoció, si la cadena de confianza es válida.

Si un servicio HTTPS falla, `curl` te da el error. `openssl s_client` te dice por qué.

---

## 📝 Sintaxis básica

```text
openssl <comando> [opciones]
```

| Comando | Para qué |
|---------|----------|
| `s_client` | Cliente TLS: conectar a un puerto con TLS |
| `x509` | Manipular certificados X.509 |
| `req` | Generar Certificate Signing Requests (CSR) |
| `rsa` / `ec` | Manipular claves privadas RSA / EC |
| `s_server` | Servidor TLS para testing |
| `dgst` | Hashes (SHA256, MD5, etc.) |
| `enc` | Encriptar/desencriptar archivos |
| `rand` | Generar bytes aleatorios |
| `version` | Mostrar versión de openssl |

---

## 🔑 Salida clave

### `s_client -connect`

```text
CONNECTED(00000003)
depth=2 C = US, O = Internet Security Research Group, CN = ISRG Root X1
verify return:1
depth=1 C = US, O = Let's Encrypt, CN = R3
verify return:1
depth=0 CN = example.com
verify return:1
---
Certificate chain
 0 s:CN = example.com
   i:C = US, O = Let's Encrypt, CN = R3
---
Server certificate
-----BEGIN CERTIFICATE-----
...
-----END CERTIFICATE-----
subject=CN = example.com
issuer=C = US, O = Let's Encrypt, CN = R3
---
No client certificate CA names sent
Peer signing digest: SHA256
Peer signature type: RSA-PSS
Server Temp Key: X25519, 253 bits
---
SSL handshake has read 3351 bytes and written 397 bytes
Verification: OK
---
New, TLSv1.3, Cipher is TLS_AES_256_GCM_SHA384
Server public key is 2048 bit
```

**Lo que mirás como sysadmin:**

- `Verification: OK` → cadena de confianza válida
- `Verification error: ...` → problema de certificado
- `Cipher is ...` → algoritmo de cifrado negociado
- `depth=0 CN = ...` → Common Name del certificado

---

## 🎛️ Opciones principales

### s_client

| Flag | Descripción |
|------|-------------|
| `-connect host:port` | Destino |
| `-servername name` | SNI (Server Name Indication) |
| `-showcerts` | Mostrar toda la cadena de certificados |
| `-CAfile file` | CA bundle para verificar |
| `-tls1_2` / `-tls1_3` | Forzar versión TLS específica |
| `-cipher suite` | Forzar cipher suite |
| `-starttls smtp` | STARTTLS para SMTP, IMAP, etc. |
| `-brief` | Output resumido |

### x509

| Flag | Descripción |
|------|-------------|
| `-in cert.pem` | Archivo de entrada |
| `-text` | Todo el contenido del certificado |
| `-noout -dates` | Solo fechas de validez |
| `-noout -subject` | Solo subject (CN, O, etc.) |
| `-noout -issuer` | Solo issuer (quién lo emitió) |
| `-noout -fingerprint` | Huella digital |
| `-noout -enddate` | Fecha de expiración |
| `-checkend N` | ¿Expira en N segundos? |

---

## 📋 Patrones de uso

### Verificar certificado HTTPS

```bash
echo | openssl s_client -connect example.com:443 -servername example.com 2>/dev/null | openssl x509 -noout -dates
```

### Verificar fecha de expiración

```bash
echo | openssl s_client -connect example.com:443 2>/dev/null | openssl x509 -noout -enddate
```

### Extraer todos los SANs (Subject Alternative Names)

```bash
echo | openssl s_client -connect example.com:443 2>/dev/null | openssl x509 -noout -ext subjectAltName
```

### Verificar cipher negociado

```bash
echo | openssl s_client -connect example.com:443 2>/dev/null | grep -E "Cipher|Protocol"
```

### Probar si un cipher específico funciona

```bash
echo | openssl s_client -cipher 'ECDHE-RSA-AES128-GCM-SHA256' -connect example.com:443 2>/dev/null | grep "Cipher"
```

### Generar certificado self-signed

```bash
openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes -subj "/CN=localhost"
```

### Verificar un archivo de certificado en disco

```bash
openssl x509 -in /etc/nginx/ssl/cert.pem -text -noout
```

---

## 🔍 Uso en troubleshooting

### "Certificate has expired"

```bash
echo | openssl s_client -connect dominio.com:443 2>/dev/null | openssl x509 -noout -enddate
```

Si la fecha ya pasó: renovar con Let's Encrypt o regenerar el certificado.

### "Unable to verify the first certificate" / "self-signed certificate"

```bash
echo | openssl s_client -connect dominio.com:443 -showcerts 2>/dev/null
```

El servidor usa un certificado auto-firmado o la cadena de confianza está incompleta.

### "wrong version number"

El puerto no habla TLS. Posiblemente el servicio es HTTP simple (sin TLS):

```bash
echo | openssl s_client -connect dominio.com:80 2>&1 | head -5
```

### "Connection refused" en TLS

El servicio puede no estar corriendo o el puerto está bloqueado:

```bash
echo | openssl s_client -connect dominio.com:443 -brief 2>&1
```

### TLS version negotiation

Si clientes antiguos no se conectan, verificar qué versiones acepta el servidor:

```bash
for v in tls1 tls1_1 tls1_2 tls1_3; do
  echo -n "$v: "
  echo | openssl s_client -${v} -connect dominio.com:443 2>&1 | grep -c "Cipher"
done
```

### Hash de archivo para integridad

```bash
openssl dgst -sha256 archivo.tar.gz
```

---

## 🛠️ Combinación con otras herramientas

### openssl + curl

```bash
# Verificar certificado antes de la conexión
openssl s_client -connect api:443 </dev/null 2>/dev/null | openssl x509 -noout -checkend 0 \
  && curl https://api/health || echo "Certificado expirado"
```

### openssl + date

```bash
expiry=$(echo | openssl s_client -connect dominio.com:443 2>/dev/null | openssl x509 -noout -enddate | cut -d= -f2)
days=$(( ($(date -d "$expiry" +%s) - $(date +%s)) / 86400 ))
echo "Faltan $days días"
```

### openssl + cron

```bash
# Monitorear expiración en cron
0 8 * * * echo | openssl s_client -connect dominio.com:443 2>/dev/null | openssl x509 -noout -checkend 604800 || echo "CERT EXPIRE ALERT" | mail -s "TLS alert" admin@example.com
```

---

## 💡 Uno-liners imprescindibles

```bash
# Fecha de expiración de un dominio
echo | openssl s_client -servername dominio.com -connect dominio.com:443 2>/dev/null | openssl x509 -noout -enddate

# ¿El certificado expira en menos de 30 días?
echo | openssl s_client -connect dominio.com:443 2>/dev/null | openssl x509 -noout -checkend 2592000

# Días restantes hasta expiración
echo | openssl s_client -connect dominio.com:443 2>/dev/null | openssl x509 -noout -enddate | cut -d= -f2 | xargs -I{} sh -c 'echo $(( ($(date -d "{}" +%s) - $(date +%s)) / 86400 ))'

# Generar clave + certificado self-signed en 1 línea
openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes -subj "/CN=localhost"

# Hash SHA256 de un archivo
openssl dgst -sha256 archivo.tar.gz

# Extraer subject del certificado
echo | openssl s_client -connect dominio.com:443 2>/dev/null | openssl x509 -noout -subject

# Ver cadena completa con fingerprints
echo | openssl s_client -connect dominio.com:443 -showcerts 2>/dev/null | openssl x509 -noout -fingerprint

# Encriptar archivo con AES-256
openssl enc -aes-256-cbc -salt -in secreto.txt -out secreto.enc

# Probar si un puerto SMTP usa STARTTLS
echo | openssl s_client -connect mail.ejemplo.com:25 -starttls smtp 2>/dev/null | grep -c "Cipher"
```

---

## ⚠️ Errores comunes

| Error | Causa | Solución |
|-------|-------|----------|
| `unable to get local issuer certificate` | CA no está en el trust store | `-CAfile /etc/ssl/certs/ca-certificates.crt` |
| `certificate has expired` | Cert vencido | Renovar con Let's Encrypt o regenerar |
| `self-signed certificate` | Sin CA real | En producción, usar Let's Encrypt. En dev, está bien |
| `wrong version number` | No es TLS (probablemente HTTP simple) | Revisar si el puerto correcto es HTTPS |
| `Connection refused` | Servicio no corre o firewall bloquea | `ss -tlnp`, `iptables -L` |
| `sslv3 alert handshake failure` | TLS version mismatch | Forzar `-tls1_2` o `-tls1_3` |
| `unable to verify the first certificate` | Cadena incompleta en el servidor | Concatenar cert + intermediate en el servidor |

---

## ✅ Buenas prácticas

1. **Monitorear expiración automatizada**: cron job que verifica `-checkend` y alerta
2. **Usar `-servername`** siempre que el host tenga múltiples vhosts (SNI)
3. **No versionar certificados ni claves privadas** en git — usar `.gitignore`
4. **Usar `-brief`** en scripts para output reducido
5. **Preferir ECDSA sobre RSA** para mejor rendimiento (curvas elípticas)
6. **Usar `-noout`** cuando solo necesitás metadatos, no el certificado completo
7. **Siempre verificar la cadena completa** en producción (`-showcerts`)
8. **Renovar con antelación**: Let's Encrypt permite renovar 30 días antes
9. **Probar ciphers inseguros para detectar configuraciones débiles**
10. **Usar `echo |` para cerrar la conexión automáticamente** sin input manual

---

## 🔗 Referencias internas

- [`curl`](curl.md) — cliente HTTP para testing de APIs
- [`nginx`](nginx.md) — servidor HTTPS con configuración SSL
- [`systemd`](systemd.md) — timers para renovación automática de certificados
- [`cron`](cron.md) — monitoreo programado de expiración TLS
- [`scenario`](../scenarios/infrastructure/04-tls-expired.md) — resolución de TLS expirado
- [`scenario`](../scenarios/infrastructure/01-migrate-to-production.md) — SSL en migración a producción
