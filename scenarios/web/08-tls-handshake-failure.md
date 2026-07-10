# 🧩 Escenario: Handshake TLS roto — diagnosticar y reparar

**Dominio:** web
**Nivel:** 🟡 Intermedio
**Herramientas:** `openssl`, `curl`, `tcpdump`
**Archivos:** `labs/docker-compose.tls.yml`

---

## 🎯 Problema

Los clientes reportan `SSL_ERROR_HANDSHAKE_FAILURE` al conectarse al servidor HTTPS. El servidor responde al ping y el puerto 443 está abierto, pero el handshake TLS falla. El certificado no está expirado. Necesitás diagnosticar exactamente por qué el handshake no se completa.

---

## ⚡ Quick command (SRE)

```bash
echo | openssl s_client -connect localhost:443 2>&1 | grep -E "error|alert|Cipher|failure"
```

---

## ✅ Salida esperada

```text
SSL routines: ...:sslv3 alert handshake failure
Cipher    : (NONE)
```

Interpretación:

- `handshake failure` → el cliente y el servidor no lograron negociar un cipher común
- `Cipher: (NONE)` → ningún cipher fue aceptado, el handshake se abortó
- `alert` → el servidor cerró activamente la conexión TLS

---

## 🧠 Diagnóstico

El handshake TLS falla cuando cliente y servidor no se ponen de acuerdo en:

- Versión de TLS (TLS 1.2 vs 1.3)
- Cipher suites (algoritmos de cifrado disponibles)
- Parámetros de curva elíptica (curvas EC)
- Certificado (aunque no haya expirado, puede ser inválido por otro motivo)

Patrones clave:

- Misma versión de openssl → mismo resultado (el problema está en la config del servidor)
- Diferentes clientes → mismo error (no es problema del cliente, es del servidor)
- Handshake con TLS 1.3 funciona pero con 1.2 no → el servidor solo acepta versiones específicas

---

## 🛠️ Procedimiento (runbook)

### 1. Verificar que el puerto está abierto

```bash
ss -tlnp | grep 443
echo | openssl s_client -connect localhost:443 2>&1 | head -5
```

### 2. Diagnosticar versión de TLS

```bash
for v in tls1 tls1_1 tls1_2 tls1_3; do
  echo -n "$v: "
  echo | openssl s_client -${v} -connect localhost:443 2>&1 | grep -c "Cipher"
done
```

Si `tls1_2` y `tls1_3` devuelven 0, el servidor está mal configurado.

### 3. Probar ciphers individualmente

```bash
openssl ciphers -v | awk '{print $1}' | head -20 | while read c; do
  echo -n "$c: "
  echo | openssl s_client -cipher "$c" -connect localhost:443 2>&1 | grep -c "Cipher"
done
```

### 4. Verificar configuración del servidor

```bash
grep -i "ssl_ciphers\|ssl_protocols\|ssl_certificate" /etc/nginx/sites-enabled/default
```

Errores comunes en nginx:

- `ssl_protocols` muy restrictivo (solo TLSv1.3 sin backup)
- `ssl_ciphers` con sintaxis incorrecta o ciphers obsoletos
- `ssl_certificate` apuntando a archivo que no existe o sin permisos

### 5. Corregir configuración

```nginx
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
ssl_prefer_server_ciphers off;
```

### 6. Verificar y recargar

```bash
nginx -t && systemctl reload nginx
echo | openssl s_client -connect localhost:443 2>&1 | grep "Cipher"
```

---

## 🧯 Mitigación

Verificar:

```bash
grep "ssl_protocols" /etc/nginx/nginx.conf
```

Acción: Corregir `ssl_protocols` y `ssl_ciphers`, recargar nginx.

Rollback: Restaurar archivo de config anterior (`cp nginx.conf.bak nginx.conf && nginx -s reload`).

---

## ✅ Interpretación

El error `sslv3 alert handshake failure` en TLS no es un problema de certificado expirado — es un problema de negociación de parámetros. Ocurre cuando la configuración del servidor es demasiado restrictiva o incompatible con los clientes.

Un sysadmin que solo verifica "puerto abierto" y "certificado no expirado" puede pasar horas debugueando. La clave es probar versiones y ciphers de forma aislada para identificar exactamente qué combinación falla.

---

## 🔗 Referencias

- [`openssl`](../../guides/openssl.md) — diagnóstico TLS con s_client
- [`nginx`](../../guides/nginx.md) — configuración SSL en servidor web
- [`tcpdump`](../../guides/tcpdump.md) — captura de paquetes TLS
- [`ss`](../../guides/ip_ss.md) — verificación de puertos
- [`scenario`](../infrastructure/04-tls-expired.md) — certificado expirado (síntoma similar, causa diferente)
