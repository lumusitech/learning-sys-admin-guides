# dig y curl — Guía completa de DNS y HTTP

**Nivel:** 🟡 Intermedio
**Archivos de práctica:** `labs/dig_output.txt`
**Ver escenarios relacionados:** [`networking/02-web-traffic`](../scenarios/networking/02-analyze-web-traffic-patterns.md)

## ⚡ Quick command

`dig +short google.com`

## ⚡ Quick run

```bash
dig +short google.com && curl -sI https://google.com | head -5
```

---

## Índice

1. [¿Qué es dig?](#qué-es-dig)
2. [Consultas básicas](#consultas-básicas)
3. [Tipos de registro DNS](#tipos-de-registro-dns)
4. [Opciones principales](#opciones-principales)
5. [Interpretar la salida](#interpretar-la-salida)
6. [Escenarios reales](#escenarios-reales)
7. [Escenarios de falla y ataque](#escenarios-de-falla-y-ataque)
8. [Uno-liners imprescindibles](#uno-liners-imprescindibles)

---

## ¿Qué es dig?

**dig** (Domain Information Groper) es la herramienta por excelencia para consultas DNS. Permite consultar cualquier tipo de registro, especificar servidores DNS, y obtener información detallada de la respuesta.

```bash
dig google.com
```

### Alternativas

| Herramienta | Uso |
|-------------|-----|
| `dig` | Consultas DNS detalladas, diagnóstico |
| `nslookup` | Consultas simples (modo interactivo y no interactivo) |
| `host` | Consultas simples, salida concisa |
| `whois` | Información de registro de dominio (no DNS) |

---

## Consultas básicas

```bash
# Consulta A (IPv4) por defecto
dig google.com

# Consulta específica con servidor DNS
dig @8.8.8.8 google.com

# Consulta AAAA (IPv6)
dig google.com AAAA

# Consulta MX (servidores de correo)
dig google.com MX

# Consulta NS (nameservers)
dig google.com NS
```

---

## Tipos de registro DNS

| Tipo | Significado | Uso |
|------|-------------|-----|
| `A` | IPv4 address | Dirección IPv4 |
| `AAAA` | IPv6 address | Dirección IPv6 |
| `CNAME` | Canonical Name | Alias de dominio |
| `MX` | Mail Exchange | Servidores de correo |
| `NS` | Name Server | Servidores DNS autoritativos |
| `TXT` | Text record | Verificación, SPF, DKIM |
| `SOA` | Start of Authority | Información de zona |
| `PTR` | Pointer | Resolución inversa (IP → dominio) |
| `SRV` | Service | Servicios específicos (voip, ldap) |
| `CAA` | Certification Authority | Qué CAs pueden emitir certificados |
| `ANY` | Cualquier registro | Todos los tipos (obsoleto, muchos servidores no lo soportan) |

```bash
# Registros A (IPv4)
dig A google.com

# Registros AAAA (IPv6)
dig AAAA google.com

# CNAME (alias)
dig CNAME www.blogger.com

# MX (mail)
dig MX gmail.com

# NS (nameservers)
dig NS google.com

# TXT (SPF, DKIM, verificaciones)
dig TXT google.com

# SOA (autoridad de la zona)
dig SOA google.com

# PTR (resolución inversa)
dig -x 8.8.8.8

# SRV (servicios)
dig SRV _sip._tcp.example.com

# CAA (autoridades de certificación)
dig CAA google.com
```

---

## Opciones principales

| Opción | Descripción |
|--------|-------------|
| `@servidor` | Servidor DNS a consultar |
| `-t tipo` | Tipo de registro (A, AAAA, MX, etc.) |
| `-x IP` | Resolución inversa (PTR) |
| `+short` | Salida concisa (solo respuestas) |
| `+noall +answer` | Solo sección ANSWER |
| `+trace` | Traza completa desde raíz |
| `+nocomments` | Sin comentarios |
| `+nostats` | Sin estadísticas |
| `+stats` | Solo estadísticas |
| `+dnssec` | Mostrar registros DNSSEC |
| `+tcp` | Usar TCP en lugar de UDP |
| `+time=N` | Timeout en segundos |
| `+tries=N` | Número de reintentos |
| `-4` | Solo IPv4 |
| `-6` | Solo IPv6 |
| `+multiline` | Salida multilínea (más legible) |
| `-f archivo` | Consultas desde archivo |
| `-p puerto` | Puerto DNS (por defecto 53) |

### +short

```bash
# Solo IPs, sin formato
dig +short google.com
# 142.250.80.46

# Múltiples resultados
dig +short gmail.com MX
# 30 alt2.gmail-smtp-in.l.google.com.
# 20 alt1.gmail-smtp-in.l.google.com.
```

### +noall +answer

```bash
# Solo la sección de respuestas
dig +noall +answer google.com
# google.com.     60    IN   A   142.250.80.46
```

### @servidor DNS específico

```bash
# Consultar a Cloudflare (1.1.1.1)
dig @1.1.1.1 google.com

# Consultar a Google (8.8.8.8)
dig @8.8.8.8 google.com

# Consultar a OpenDNS (208.67.222.222)
dig @208.67.222.222 google.com

# Consultar a un servidor local
dig @192.168.1.1 google.com
```

### +trace

```bash
# Traza completa: desde los root servers hasta el dominio
dig +trace google.com
```

Muestra:

1. Root servers (.)
2. TLD servers (.com)
3. Servidores autoritativos (google.com)
4. Respuesta final

### +dnssec

```bash
# Verificar DNSSEC
dig +dnssec google.com

# Verificar cadena de confianza
dig +dnssec +trace google.com
```

### +multiline

```bash
# Formato más legible para TXT, SOA
dig +multiline TXT google.com
```

---

## Interpretar la salida

### Estructura de la respuesta

```text
; <<>> DiG 9.16.1-Ubuntu <<>> google.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 12345
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096

;; QUESTION SECTION:
;google.com.                    IN      A

;; ANSWER SECTION:
google.com.             60      IN      A       142.250.80.46

;; Query time: 12 msec
;; SERVER: 127.0.0.53#53(127.0.0.53)
;; WHEN: Mon Jan 15 14:30:22 EST 2024
;; MSG SIZE  rcvd: 55
```

### Secciones de la respuesta

| Sección | Significado |
|---------|-------------|
| `HEADER` | Cabecera con opcode, status, flags |
| `QUESTION` | La consulta que enviamos |
| `ANSWER` | Las respuestas (registros DNS) |
| `AUTHORITY` | Servidores autoritativos para la zona |
| `ADDITIONAL` | Información adicional (IPs de NS, EDNS) |

### Códigos de estado (status)

| Status | Significado |
|--------|-------------|
| `NOERROR` | Consulta exitosa (aunque pueda no tener respuestas) |
| `NXDOMAIN` | El dominio NO existe |
| `SERVFAIL` | El servidor DNS no pudo procesar la consulta (fallo interno) |
| `REFUSED` | El servidor DNS rechazó la consulta (política) |
| `FORMERR` | Error de formato en la consulta |

### Flags

| Flag | Significado |
|------|-------------|
| `qr` | Query Response (es una respuesta, no una consulta) |
| `rd` | Recursion Desired (pedimos resolución recursiva) |
| `ra` | Recursion Available (el servidor soporta recursión) |
| `aa` | Authoritative Answer (respuesta autoritativa, no cache) |
| `ad` | Authentic Data (respuesta validada con DNSSEC) |
| `cd` | Checking Disabled (cliente no pide validación DNSSEC) |
| `tc` | Truncated (respuesta truncada, usar TCP) |

### TTL

```bash
# TTL en segundos
dig +noall +answer google.com
# google.com.     60   IN  A  142.250.80.46
#                 ^^
#                 TTL = 60 segundos
```

| TTL | Interpretación |
|-----|----------------|
| 300-3600 (5min-1h) | Normal para registros A |
| 60-300 (1-5min) | Bajo: cambios frecuentes (CDN, failover) |
| 86400 (24h) | Alto: registros estables (MX, NS) |

---

## Escenarios reales

### 1. ¿Funciona la resolución DNS?

```bash
# ¿El sistema resuelve nombres?
dig google.com +short

# Si devuelve IP → OK
# Si devuelve nada o error → DNS no funciona
```

### 2. Comparar servidores DNS

```bash
# Medir tiempo de respuesta de diferentes DNS
echo "Google: $(dig @8.8.8.8 +stats google.com | grep 'Query time' | awk '{print $4}') ms"
echo "Cloudflare: $(dig @1.1.1.1 +stats google.com | grep 'Query time' | awk '{print $4}') ms"
echo "Local: $(dig @192.168.1.1 +stats google.com | grep 'Query time' | awk '{print $4}') ms"
```

### 3. Verificar propagación DNS

```bash
# Consultar múltiples DNS públicos para ver si todos responden igual
for dns in 8.8.8.8 1.1.1.1 208.67.222.222 9.9.9.9; do
  echo -n "$dns: "
  dig @$dns +short example.com
done
```

### 4. Resolución inversa (PTR)

```bash
# ¿A qué dominio pertenece esta IP?
dig -x 8.8.8.8 +short
# dns.google.

# Verificar que el PTR coincide con el forward
dig -x 142.250.80.46 +short
```

### 5. Verificar configuración de correo

```bash
# Servidores MX
dig +short MX gmail.com

# Prioridad (menor número = mayor prioridad)
dig +noall +answer MX gmail.com | sort -n

# SPF (política de envío de correo)
dig TXT gmail.com | grep "v=spf1"

# DKIM (firma de correo)
dig TXT 20221208._domainkey.gmail.com

# DMARC (política de autenticación)
dig TXT _dmarc.gmail.com
```

### 6. Verificar delegación de zona

```bash
# ¿Son correctos los NS?
dig NS example.com +short

# ¿Coinciden con los NS del registrar?
whois example.com | grep "Name Server"

# Glue records (IPs de los NS)
dig +noall +additional example.com NS
```

---

## Escenarios de falla y ataque

### 1. NXDOMAIN — El dominio no existe

```text
status: NXDOMAIN
```

```bash
dig +short dominioquenoexiste12345.com
# Sin respuesta, código de salida 0 pero NOERROR no aparece
```

Causas:

- Dominio no registrado
- DNS mal configurado (falta registro A)
- **Cache poisoning**: si un resolver devuelve NXDOMAIN para un dominio que existe

### 2. SERVFAIL — Error de servidor

```text
status: SERVFAIL
```

Causas:

- El servidor DNS autoritativo no responde o está caído
- Problema de **delegación** (los NS no apuntan a IPs válidas)
- **DNSSEC validation failure**: la cadena de confianza está rota
- Timeout al consultar el servidor autoritativo

```bash
# Probar con +trace para ver dónde falla
dig +trace example.com
```

### 3. REFUSED — Consulta rechazada

```text
status: REFUSED
```

Causas:

- El servidor DNS no tiene autoridad sobre la zona
- El servidor no permite consultas recursivas (bloquea consultas de terceros)
- **Política de acceso**: solo permite consultas desde ciertas IPs

### 4. DNS spoofing / cache poisoning

```bash
# Verificar si un registro DNS es legítimo
# Comparar la respuesta con DNSSEC
dig +dnssec google.com

# Si ves "flags: ad" → respuesta validada con DNSSEC
# Si no ves "ad" → no se validó (posible spoofing)

# Comparar contra múltiples resolvers confiables
# Si dos resolvers devuelven IPs diferentes, hay problema
```

### 5. DNS tunneling (data exfiltration)

```bash
# Consultas TXT con textos muy largos (posible tunneling)
# Subdominios con nombres aleatorios muy largos
# Gran volumen de consultas a un dominio
dig +short TXT tunel.ejemplo.com
# Si el resultado es muy largo (>200 caracteres), posible tunneling
```

### 6. Amplification attack

```bash
# El servidor DNS permite consultas ANY?
dig +short ANY isc.org

# Si responde con muchos registros y el paquete es grande
# → Este servidor podría usarse para amplification DDoS

# Verificar tamaño de respuesta
dig +noall +stats ANY isc.org | grep "MSG SIZE"
```

### 7. Servidor DNS caído

```bash
# Consultar a un servidor DNS específico
dig @8.8.8.8 +time=3 +tries=1 google.com

# Si no responde en 3 segundos:
# - Servidor caído (no sabe de Google)
# - Firewall bloquea puerto 53
# - Red local no tiene conectividad
```

### 8. Tiempo de resolución alto

```bash
dig +stats google.com
# Query time: 120 msec → normal (<50 excelente, <100 bueno, >200 lento)
```

---

## Uno-liners imprescindibles

```bash
# Consulta básica
dig google.com

# Solo IP
dig +short google.com

# Solo respuesta corta
dig +noall +answer google.com

# Tipo específico
dig MX gmail.com +short
dig NS google.com +short
dig TXT google.com +short

# Con servidor específico
dig @8.8.8.8 +short google.com

# Resolución inversa
dig -x 8.8.8.8 +short

# Traza completa
dig +trace google.com

# Solo query time
dig +stats google.com | grep "Query time"

# DNSSEC
dig +dnssec +short google.com

# TTL
dig +noall +answer google.com | awk '{print $2}'

# Verificar propagación (múltiples resolvers)
for dns in 8.8.8.8 1.1.1.1 208.67.222.222; do
  echo "$dns: $(dig @$dns +short example.com)"
done

# SOA
dig SOA google.com +short

# CNAME
dig CNAME www.blogger.com +short

# Registro SRV
dig SRV _sip._tcp.example.com +short

# Todos los registros de un dominio
dig +noall +answer google.com ANY

# Verificar caché local
dig +norecuse @127.0.0.1 google.com

# Puertos no estándar
dig @ns.example.com -p 5353 example.com

# Consultas desde archivo (batch)
dig -f dominios.txt +short
```
