# nc — Guía completa de diagnóstico de conectividad

**Nivel:** 🟢 Básico
**Archivos de práctica:** `labs/docker-compose.network.yml`
**Ver escenarios relacionados:** [`networking/08-firewall-blocked-port`](../scenarios/networking/08-firewall-blocked-port.md)

---

## ⚡ Quick command

`nc -zv example.com 80`

> ⚠️ nc puede usar flags distintos según la versión (netcat-openbsd vs netcat-traditional vs ncat). Esta guía asume **netcat-openbsd** (la más común en Debian/Ubuntu/Alpine).

---

## ⚡ Quick run

```bash
nc -zv google.com 80 443 && echo "Puertos abiertos" || echo "Puertos cerrados"
```

---

## 📑 Índice

1. [¿Qué es nc?](#qué-es-nc)
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

## 🧠 ¿Qué es nc?

nc (netcat) es la navaja suiza de redes en TCP/IP. Su función más simple y más usada: **verificar si un puerto está abierto y escuchando**. Pero también puede:

- Enviar y recibir datos por TCP/UDP
- Actuar como servidor temporal (escuchar en un puerto)
- Transferir archivos entre dos hosts
- Hacer banner grabbing (leer la respuesta de un servicio)
- Crear túneles y proxies TCP simples

Para el sysadmin, nc es la primera herramienta de diagnóstico de conectividad: más simple que `telnet`, más rápido que `nmap`, más directo que `curl`.

---

## 🧠 Modelo mental

Pensá en nc como un **walkie-talkie TCP**. Cuando ejecutás `nc host puerto`:

- Si el puerto está abierto → se establece conexión, podés "hablar" y "escuchar"
- Si el puerto está cerrado o filtrado → conexión rechazada o timeout

Es la verificación más directa de que hay un servicio escuchando del otro lado, sin importar el protocolo.

---

## 📝 Sintaxis básica

```text
nc [opciones] <host> <puerto>
```

### Modos de uso más comunes

| Uso | Comando |
|-----|---------|
| Verificar puerto TCP | `nc -zv host puerto` |
| Conectarse y enviar datos | `echo "data" \| nc host puerto` |
| Escuchar en un puerto | `nc -l puerto` |
| Transferir archivo | `nc -l puerto > archivo` (recibir) / `nc host puerto < archivo` (enviar) |

---

## 🔑 Salida clave

### Puerto abierto

```text
$ nc -zv google.com 80
Connection to google.com (142.250.78.14) 80 port [tcp/http] succeeded!
```

### Puerto cerrado

```text
$ nc -zv localhost 9999
nc: connect to localhost (127.0.0.1) port 9999 (tcp) failed: Connection refused
```

### Puerto filtrado (firewall DROP, no REJECT)

```text
$ nc -zv -w 3 firewalled.com 22
nc: connect to firewalled.com port 22 (tcp) timed out: Operation now in progress
```

**Diferencia clave:** `Connection refused` significa que el host llegó pero no hay servicio. `Timed out` significa que los paquetes no llegaron (firewall, host caído, etc.).

---

## 🎛️ Opciones principales

| Flag | Significado |
|------|-------------|
| `-z` | Zero-I/O mode: escanear sin enviar datos |
| `-v` | Verbose: mostrar más información |
| `-n` | No resolver DNS (solo IPs numéricas) |
| `-w N` | Timeout de N segundos |
| `-l` | Modo listen (servidor) |
| `-k` | Keep listening (no cerrar tras la primera conexión) |
| `-p puerto` | Puerto local para modo listen |
| `-u` | Modo UDP (por defecto es TCP) |
| `-4` / `-6` | Forzar IPv4 o IPv6 |
| `-s IP` | Source IP (IP de origen) |

---

## 📋 Patrones de uso

### Verificar múltiples puertos

```bash
nc -zv host 22 80 443 3306 8080
```

### Banner grabbing (ver qué servicio responde)

```bash
echo "" | nc -w 2 host 22    # SSH banner
echo "" | nc -w 2 host 80    # HTTP banner (luego hacer GET)
```

### Rango de puertos

```bash
nc -zv host 8000-8100 2>&1 | grep succeeded
```

### Servidor TCP temporal

```bash
nc -l -p 9090              # Escuchar en 9090 (terminal 1)
nc localhost 9090          # Conectar desde terminal 2
```

### Transferencia rápida de archivo

```bash
# Receptor (ejecutar primero)
nc -l -p 1234 > archivo_recibido.tar.gz

# Emisor
nc host_receptor 1234 < archivo_a_enviar.tar.gz
```

---

## 🔍 Uso en troubleshooting

### "No puedo conectarme a la base de datos"

```bash
nc -zv db-server 3306
```

Si falla, verificar:

- Servicio corriendo en el host destino
- Firewall (DROP vs REJECT)
- Binding correcto (0.0.0.0 vs 127.0.0.1)

### "El balanceador de carga no forwardea al backend"

```bash
nc -zv backend1 8080
nc -zv backend2 8080
```

### "¿Por qué el cliente recibe timeout en vez de connection refused?"

```bash
nc -zv -w 5 api.externa.com 443
```

Si timeout, probablemente firewall DROP. Si connection refused, el servicio no está corriendo.

### Cómo diferenciar DROP de REJECT

- `Connection refused` inmediato → REJECT (el firewall responde con RST)
- `Timed out` después de N segundos → DROP (los paquetes se descartan sin respuesta)

---

## 🛠️ Combinación con otras herramientas

### nc + ss

```bash
ss -tlnp | grep 8080 && nc -zv localhost 8080
```

### nc + iptables

```bash
# Bloquear y verificar
iptables -A INPUT -p tcp --dport 9999 -j DROP
nc -zv -w 2 localhost 9999    # Debería dar timeout
iptables -D INPUT -p tcp --dport 9999 -j DROP
```

### nc + nmap

```bash
# Descubrir IP y verificar puerto
nmap -sn 192.168.1.0/24 | grep "scan report" | awk '{print $5}' | while read ip; do nc -zv -w 1 "$ip" 22 2>&1 | grep succeeded; done
```

---

## 💡 Uno-liners imprescindibles

```bash
# Verificar si un puerto está abierto
nc -zv host 80

# Escanear puertos comunes de un host
for p in 22 80 443 3306 5432 6379 8080 9090 3000 9100; do nc -zv host $p 2>&1 | grep succeeded; done

# Banner de SSH
echo "" | nc -w 3 host 22 | head -1

# Headers HTTP manuales
printf "GET / HTTP/1.1\r\nHost: host\r\n\r\n" | nc host 80

# Test de conectividad UDP (DNS)
echo "test" | nc -u -w 2 host 53

# Servidor eco simple para testing
nc -l -k -p 12345

# Encontrar el primer puerto abierto en un rango
for p in $(seq 8000 8100); do nc -zv -w 1 host $p 2>&1 | grep -q succeeded && echo "$p: open" && break; done
```

---

## ⚠️ Errores comunes

| Error | Causa | Solución |
|-------|-------|----------|
| `Connection refused` | Servicio no corriendo o firewall REJECT | `ss -tlnp`, verificar que el servicio escucha en la IP correcta |
| `Timed out` | Firewall DROP o host inaccesible | `ping`, `traceroute`, verificar reglas iptables |
| `Name or service not known` | DNS no resuelve el host | `dig`, `nslookup`, `/etc/hosts` |
| `nc: invalid option -- 'z'` | Versión de nc incorrecta (netcat-traditional) | Instalar `netcat-openbsd` |
| Conexión exitosa pero sin banner | Servicio no envía datos hasta recibir protocolo correcto | Enviar payload adecuado en vez de `echo ""` |

---

## ✅ Buenas prácticas

1. **Siempre usar `-zv`** para escanear sin enviar datos innecesarios
2. **Siempre usar `-w`** en scripts para evitar bloqueos infinitos en DROP
3. **Preferir `nc -zv` sobre `telnet`** para verificar puertos (más simple, no interactivo)
4. **No usar nc como servidor HTTP real** — es solo para diagnósticos temporales
5. **Para transferencias seguras**, usar nc sobre SSH o usar rsync/scp en vez de nc
6. **Para UDP, recordar que no hay confirmación** — nc -u envía y no sabe si llegó

---

## 🔗 Referencias internas

- [`ip_ss`](ip_ss.md) — sockets y puertos locales
- [`nmap`](nmap.md) — escaneo avanzado de puertos y servicios
- [`iptables`](iptables.md) — reglas de firewall que afectan nc
- [`ping_traceroute`](ping_traceroute.md) — diagnóstico de ruta y pérdida
- [`curl`](curl.md) — diagnóstico HTTP (nc crudo vs curl con protocolo)
- [`ssh`](ssh.md) — túneles seguros
- [`scenario`](../scenarios/networking/08-firewall-blocked-port.md) — diagnóstico de puerto bloqueado
