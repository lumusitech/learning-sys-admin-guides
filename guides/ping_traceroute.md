# ping y traceroute — Guía completa

**Nivel:** 🟢 Básico
**Archivos de práctica:** `labs/ping.txt`, `labs/traceroute.txt`
**Ver escenarios relacionados:** [`networking`](../scenarios/networking/), [`concepts/how-to-think-like-sysadmin`](../concepts/how-to-think-like-sysadmin.md)

## ⚡ Quick command

`ping -c 4 google.com`

## ⚡ Quick run

```bash
ping -c 4 google.com && traceroute google.com
```

---

## 📑 Índice

1. [ping — Introducción](#ping--introducción)
2. [Opciones de ping](#opciones-de-ping)
3. [Interpretar salida de ping](#interpretar-salida-de-ping)
4. [Escenarios de ping](#escenarios-de-ping)
5. [traceroute — Introducción](#traceroute--introducción)
6. [Opciones de traceroute](#opciones-de-traceroute)
7. [Interpretar salida de traceroute](#interpretar-salida-de-traceroute)
8. [mtr — La combinación](#mtr--la-combinación)
9. [Escenarios de traceroute/mtr](#escenarios-de-traceroutemtr)
10. [Uno-liners imprescindibles](#uno-liners-imprescindibles)

---

## 🧠 ¿Qué es ping?

**ping** envía paquetes ICMP ECHO_REQUEST a un host y espera respuestas ICMP ECHO_REPLY. Sirve para verificar conectividad, medir latencia (RTT) y detectar pérdida de paquetes. Es la primera herramienta de diagnóstico de red.

---

## ping — Introducción

**ping** envía paquetes ICMP ECHO_REQUEST a un host y espera respuestas ICMP ECHO_REPLY. Sirve para:

- Verificar si un host está **vivo** (reachable)
- Medir **latencia** (tiempo de ida y vuelta, RTT)
- Detectar **pérdida de paquetes**
- Verificar **resolución DNS** (el nombre se resuelve correctamente)
- Probar la **conectividad IP** básica

```bash
ping host
ping 8.8.8.8
ping google.com
```

---

## Opciones de ping

| Opción | Descripción |
|--------|-------------|
| `-c N` | Enviar N paquetes y salir |
| `-i N` | Intervalo entre paquetes en segundos (por defecto 1s) |
| `-s N` | Tamaño del payload en bytes (por defecto 56) |
| `-t N` | TTL (Time To Live) |
| `-W N` | Timeout en segundos para esperar respuesta |
| `-w N` | Tiempo total máximo en segundos |
| `-q` | Modo silencioso (solo resumen al final) |
| `-n` | No resolver nombres (IPs numéricas) |
| `-D` | Mostrar timestamp con fecha |
| `-O` | Reportar paquetes en tránsito (no llegados) |
| `-f` | Flood ping (envío masivo, solo root) |
| `-a` | Sonido audible cuando hay respuesta |
| `-4` | Forzar IPv4 |
| `-6` | Forzar IPv6 |
| `-I interfaz` | Usar interfaz específica |
| `-p patrón` | Rellenar paquete con patrón hexadecimal |
| `-M option` | PMTUD: `do` (DF=1), `dont` (DF=0), `want` |
| `-m TTL` | Fijar TTL (útil para traceroute manual) |
| `-R` | Registrar ruta (IPv4, graba IPs en opción de registro) |

### -c: paquetes contados

```bash
# Enviar 5 paquetes y mostrar resumen
ping -c 5 8.8.8.8
```

### -i: intervalo

```bash
# Ping rápido (0.2s entre paquetes)
ping -i 0.2 -c 10 google.com

# Ping lento (cada 5 segundos, monitoreo prolongado)
ping -i 5 google.com
```

### -s: tamaño del paquete

```bash
# Paquete normal (56 bytes = 64 ICMP)
ping -c 3 -s 56 google.com

# Paquete grande (1472 bytes, justo al límite de MTU 1500 en ethernet)
ping -c 3 -s 1472 google.com

# Paquete que fuerza fragmentación (más de 1472 bytes con MTU 1500)
ping -c 3 -s 1500 google.com
# Puede fallar si hay routers con MTU menor
```

### -M: Path MTU Discovery

```bash
# Probar MTU: con DF bit activado (Don't Fragment)
ping -c 3 -M do -s 1472 google.com
# -M do: DF activado. Si algún router intermedio tiene MTU < 1500, falla
# Si falla, reducir -s hasta encontrar el MTU máximo (MTU = -s + 28)

# Sin DF
ping -c 3 -M dont -s 1500 google.com
```

### -f: flood ping

```bash
# Envío masivo (solo root, mide rendimiento)
sudo ping -f -c 1000 google.com
```

### -w: timeout total

```bash
# Dejar de hacer ping después de 10 segundos
ping -w 10 google.com
```

---

## Interpretar salida de ping

### Salida exitosa

```text
PING google.com (142.250.80.46) 56(84) bytes of data.
64 bytes from 142.250.80.46: icmp_seq=1 ttl=116 time=15.2 ms
64 bytes from 142.250.80.46: icmp_seq=2 ttl=116 time=14.8 ms
64 bytes from 142.250.80.46: icmp_seq=3 ttl=116 time=15.1 ms

--- google.com ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 14.788/15.012/15.222/0.178 ms
```

| Campo | Significado |
|-------|-------------|
| `56(84) bytes` | 56 bytes de datos + 28 bytes de cabeceras ICMP+IP |
| `icmp_seq=1` | Número de secuencia del paquete |
| `ttl=116` | TTL restante (valor inicial típico: 128 Windows, 64 Linux, 255 routers) |
| `time=15.2 ms` | RTT (Round Trip Time) en milisegundos |
| `0% packet loss` | Porcentaje de pérdida |
| `min/avg/max/mdev` | RTT mínimo, promedio, máximo, desviación media |

### TTL y sistema operativo

El TTL inicial revela el sistema operativo remoto:

| TTL inicial | Sistema |
|-------------|---------|
| 64 | Linux, macOS, BSD, Solaris |
| 128 | Windows |
| 255 | Routers, dispositivos de red |
| 60 | Algunos Unix variantes |

```bash
# Si ves TTL=116 contra Google: TTL inicial era ~128? o ~255? o ~64?
# 128 - 12 = 116 → 12 saltos desde un Windows
# 64 - 12 = 52 no es (porque vemos 116)
# Es TTL inicial 128 (Windows no, pero podría ser cierto dispositivo con TTL 128)
# En realidad 255 - 116 = 139 saltos no tiene sentido
# Google usa TTL inicial 64 + saltos desde ellos hasta nosotros
# 116 es TTL que vemos nosotros = TTL inicial de Google - saltos
# Si Google usa TTL 64 inicial, entonces nosotros estamos a 64-116 = -52 saltos? No.
# En realidad, el TTL se decrementa en cada salto. Si el paquete llega con TTL 116,
# el emisor lo envió con TTL 128 y recorrió 12 saltos, o con TTL 255 y recorrió 139.
# Google suele usar TTL 128 o 255 en sus servidores.
```

### Salida de fallo

```text
From 192.168.1.1 icmp_seq=1 Destination Host Unreachable
From 192.168.1.1 icmp_seq=1 Destination Net Unreachable
From 192.168.1.1 icmp_seq=1 Destination Port Unreachable

--- 10.0.0.1 ping statistics ---
5 packets transmitted, 0 received, +5 errors, 100% packet loss
```

### Salida de timeout

```text
PING 10.0.0.1 (10.0.0.1) 56(84) bytes of data.

--- 10.0.0.1 ping statistics ---
5 packets transmitted, 0 received, 100% packet loss, time 4000ms
```

---

## Escenarios de ping

### 1. Host responde — conectividad OK

```text
64 bytes from 8.8.8.8: icmp_seq=1 ttl=116 time=15.2 ms
```

→ Red funcionando, host alive, latencia normal (<50ms es excelente, <100ms bueno)

### 2. Host no responde — 100% loss

```text
5 packets transmitted, 0 received, 100% packet loss
```

Causas posibles:

- Host **apagado** o caído
- **Firewall** bloqueando ICMP (común en muchos servidores)
- **Ruta de retorno** rota (el paquete llega pero la respuesta no vuelve)
- **Red intermedia** caída
- **ARP incompleto**: el router no sabe cómo llegar al destino

### 3. Destination Host Unreachable

```text
From 192.168.1.1 icmp_seq=1 Destination Host Unreachable
```

→ El **router local** (192.168.1.1) no tiene ruta al destino. Posibles causas:

- La IP destino no existe en la subred local
- Gateway por defecto no configurado correctamente
- Enlace entre routers caído

### 4. Pérdida parcial de paquetes (20-50%)

```text
5 packets transmitted, 3 received, 40% packet loss
```

→ Problemas de red intermitentes:

- **Congestión** (buffer overflow en router)
- **Enlace con errores** (cobre, fibra, WiFi con interferencia)
- **Colisiones** en half-duplex
- **MTU mismatch**: paquetes muy grandes se pierden

### 5. Latencia alta y variable

```text
time=250 ms
time=50 ms
time=800 ms
time=60 ms
```

→ Indica:

- **Congestión**: buffers de router llenos, colas largas
- **Enrutamiento asimétrico**: ida y vuelta por caminos diferentes
- **Enlace congestionado**: saturación de ancho de banda
- **Bufferbloat**: buffers demasiado grandes en routers domésticos

### 6. TTL exceeded in transit

```text
From 192.168.1.1: icmp_seq=1 Time to live exceeded
```

→ El TTL llegó a 0 antes de alcanzar el destino. Causas:

- **Bucle de enrutamiento** (loop)
- TTL inicial demasiado pequeño para la distancia real

### 7. Ping contra localhost

```bash
ping -c 3 localhost
ping -c 3 127.0.0.1
```

→ Prueba que la pila de red local funciona. Si falla, el problema es del **propio sistema** (loopback interface caída, kernel module no cargado).

### 8. Ping broadcast (Smurf attack)

```bash
# Hacer ping a la dirección de broadcast descubre hosts en la red
# PERO puede considerarse ataque si se hace a redes ajenas
ping -b -c 3 192.168.1.255
```

### 9. Probar MTU máximo sin fragmentación

```bash
# Probar diferentes tamaños hasta encontrar el MTU
for size in 1472 1462 1452 1400 1300 1200; do
  ping -c 1 -M do -s $size 8.8.8.8 > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "MTU $((size + 28)) OK"
  else
    echo "MTU $((size + 28)) FALLA"
  fi
done
```

---

## traceroute — Introducción

**traceroute** muestra la **ruta** que siguen los paquetes desde el origen hasta el destino, listando cada **salto** (router intermedio). Funciona enviando paquetes con TTL creciente: TTL=1 lo rechaza el primer router (que envía ICMP Time Exceeded), y así sucesivamente.

```bash
traceroute 8.8.8.8
traceroute google.com
```

### Paquetes usados por traceroute

- Por defecto en Linux: **UDP** a puertos altos (33434+)
- Con `-I`: **ICMP Echo** (como ping)
- Con `-T`: **TCP SYN** (típico a puerto 80)

---

## Opciones de traceroute

| Opción | Descripción |
|--------|-------------|
| `-n` | No resolver nombres (solo IPs) |
| `-I` | Usar ICMP Echo en lugar de UDP |
| `-T` | Usar TCP SYN |
| `-p puerto` | Puerto destino (con -T) |
| `-m N` | Máximo TTL (máximo número de saltos, por defecto 30) |
| `-q N` | Número de sondas por salto (por defecto 3) |
| `-N N` | Número de sondas simultáneas (por defecto 16) |
| `-w N` | Tiempo de espera por respuesta |
| `-z N` | Tiempo de espera entre sondas |
| `-f N` | TTL inicial (empezar desde el salto N) |
| `--mtu` | Descubrir MTU a lo largo de la ruta |
| `-4` | Forzar IPv4 |
| `-6` | Forzar IPv6 |

### -I (ICMP)

```bash
# Usar ICMP (similar a ping, menos probable que firewalls bloqueen)
traceroute -I -n 8.8.8.8
```

### -T (TCP SYN)

```bash
# Usar TCP SYN (más fiable para atravesar firewalls)
traceroute -T -n 8.8.8.8

# Con puerto específico (puerto 80 HTTP)
traceroute -T -p 80 -n google.com

# TCP SYN a puerto 443 (HTTPS) — parece tráfico normal
traceroute -T -p 443 -n google.com
```

### -f: saltar primeros N saltos

```bash
# Empezar desde el salto 10 (omitir red local)
traceroute -f 10 -n 8.8.8.8
```

### -m: máximo saltos

```bash
# Limitar a 15 saltos (más rápido)
traceroute -m 15 -n 8.8.8.8
```

---

## Interpretar salida de traceroute

### Salida exitosa

```text
traceroute to 8.8.8.8 (8.8.8.8), 30 hops max, 60 byte packets
 1  192.168.1.1  1.234 ms  1.189 ms  1.156 ms
 2  10.0.0.1    5.432 ms  5.210 ms  5.198 ms
 3  172.16.0.1  10.123 ms  9.876 ms  9.654 ms
 4  8.8.8.8     15.234 ms  14.987 ms  14.876 ms
```

| Columna | Significado |
|---------|-------------|
| `1` | Número de salto (TTL=1) |
| `192.168.1.1` | IP del router en ese salto |
| `1.234 ms` | Tiempo de respuesta de la sonda 1 |
| `1.189 ms` | Tiempo de respuesta de la sonda 2 |
| `1.156 ms` | Tiempo de respuesta de la sonda 3 |

### Salto sin respuesta

```text
 4  * * *
```

→ El router no respondió. Causas:

- **Firewall** bloquea ICMP Time Exceeded
- Router **no envía** ICMP Time Exceeded (por configuración o por ser demasiado lento)
- **Congestión** severa

### Salto con latencia alta

```text
 3  172.16.0.1  300.234 ms  250.189 ms  310.156 ms
```

→ Ese router en particular tiene problemas (congestión, saturado).

### Salto con nombres y resolución

```text
 1  router.home (192.168.1.1)  1.234 ms
 2  10.0.0.1 (10.0.0.1)  5.432 ms
 3  core-1.isp.net (172.16.0.1)  10.123 ms
 4  google.dns.google (8.8.8.8)  15.234 ms
```

### RTT incrementándose gradualmente

```text
 1  1 ms
 2  5 ms
 3  10 ms
 4  15 ms
```

→ Normal: cada salto añade propagación y procesamiento.

### RTT de un salto mucho mayor que el siguiente

```text
 3  100 ms
 4  5 ms
```

→ Posible **routing asimétrico**: ida y vuelta por caminos diferentes.

---

## mtr — La combinación

**mtr** fusiona ping + traceroute. Hace traceroute continuamente y muestra estadísticas de cada salto.

```bash
# Básico
mtr 8.8.8.8

# Modo reporte (no interactivo, para logs)
mtr -r -c 100 8.8.8.8

# Sin resolución de nombres
mtr -n 8.8.8.8

# Mostrar tanto IP como nombre
mtr -b 8.8.8.8
```

### Opciones de mtr

| Opción | Descripción |
|--------|-------------|
| `-r` | Modo reporte (no interactivo) |
| `-c N` | Enviar N paquetes por salto |
| `-n` | IPs numéricas |
| `-b` | Mostrar IP y nombre |
| `-i N` | Intervalo entre paquetes (segundos) |
| `-4` | IPv4 |
| `-6` | IPv6 |
| `-T` | TCP (no ICMP) |
| `-P puerto` | Puerto destino para TCP |
| `-u` | UDP |
| `-z` | Mostrar AS (Autonomous System) |

### Salida de mtr

```text
                              My traceroute  [v0.95]
host.local (192.168.1.100)                             2024-01-15T14:30:22+0000
Keys: Help   Display mode   Restart statistics   Order of fields   quit
                                        Packets               Pings
 Host                                 Loss%   Snt   Last   Avg  Best  Wrst StDev
 1. 192.168.1.1                       0.0%    100   1.2   1.3   0.8   5.4   0.5
 2. 10.0.0.1                         0.0%    100   5.1   5.3   4.2   8.7   0.8
 3. 172.16.0.1                       0.5%    100   10.2  15.3  9.1   120.3 18.2
 4. 8.8.8.8                          0.0%    100   14.8  15.1  13.9  18.2  1.1
```

| Columna | Significado |
|---------|-------------|
| `Loss%` | Porcentaje de pérdida en ese salto |
| `Snt` | Paquetes enviados |
| `Last` | RTT del último paquete |
| `Avg` | RTT promedio |
| `Best` | RTT mínimo |
| `Wrst` | RTT máximo |
| `StDev` | Desviación estándar (variabilidad) |

### Interpretación avanzada de mtr

#### Pérdida en un salto intermedio pero no en el destino

```text
 3. 172.16.0.1  50.0%  100
 4. 8.8.8.8     0.0%  100
```

→ El salto 3 tiene pérdida, pero el destino final no → El router 3 **limita ICMP** (responde a algunos Time Exceeded pero no a todos). No es pérdida real de tráfico. Los paquetes pasan, pero el router no responde a todas las sondas.

#### Pérdida en el último salto o acumulativa

```text
 3. 172.16.0.1  0.0%
 4. 8.8.8.8    50.0%
```

→ El destino **no responde a ICMP** siempre (tasa limitada) o hay pérdida real.

#### Pérdida creciente a partir de un salto

```text
 3. 172.16.0.1   0.0%
 4. 10.1.1.1    20.0%
 5. 10.2.2.2    40.0%
 6. 8.8.8.8     40.0%
```

→ El enlace entre el salto 3 y el 4 está **congestionado** o con **errores**.

#### StDev alto en un salto (jitter)

```text
 3. 172.16.0.1  Avg=50  StDev=45.2
```

→ Ese router tiene **alta variabilidad de latencia**. Causas: congestión, bufferbloat, QoS.

---

## Escenarios de traceroute/mtr

### 1. Red local funcionando normalmente

```text
 1  192.168.1.1   1ms
 2  10.0.0.1     20ms
 3  8.8.8.8      30ms
```

→ Primer salto <5ms (red local), resto latencia normal.

### 2. Internet lenta después de cierto punto

```text
 1  192.168.1.1     1ms
 2  10.0.0.1       5ms
 3  172.16.0.1    300ms  ← cuello de botella
 4  8.8.8.8       350ms
```

→ El salto 3 es el **cuello de botella** (router del ISP congestionado).

### 3. Pérdida de paquetes total en un salto (pero llega al destino)

```text
 3  * * *
 4  * * *
 5  8.8.8.8  15ms
```

→ Los routers 3 y 4 limitan ICMP. No indica problema necesariamente.

### 4. No se alcanza el destino (caída en medio)

```text
 1  192.168.1.1    1ms
 2  10.0.0.1       5ms
 3  * * *
 4  * * *
```

→ A partir del salto 2 no hay respuesta. Posibles causas:

- Router del ISP caído
- Corte de fibra/enlace
- Firewall bloqueando todo

### 5. Bucle de enrutamiento

```text
 1  192.168.1.1    1ms
 2  10.0.0.1       2ms
 3  192.168.1.1    1ms  ← volvió al salto 1
 4  10.0.0.1       2ms
 5  192.168.1.1    1ms
 ...
```

→ **Bucle de enrutamiento**: los routers se pasan el paquete mutuamente sin llegar al destino. Causa típica: configuración incorrecta de rutas estáticas o protocolo de enrutamiento mal configurado.

### 6. AS Path: detectar cambios de ISP

```bash
# mtr muestra los AS (sistemas autónomos)
mtr -z 8.8.8.8
```

### 7. Comparar ruta con traceroute -n

```bash
# Ejecutar múltiples veces y ver si la ruta cambia (anycast, load balancing)
for i in 1 2 3; do
  echo "=== Traza $i ==="
  traceroute -n 8.8.8.8
  sleep 5
done
```

---

## 💡 Uno-liners imprescindibles

```bash
# Ping básico (4 paquetes)
ping -c 4 google.com

# Ping sin resolución de nombres
ping -c 4 -n 8.8.8.8

# Ping flood (solo root)
sudo ping -f -c 1000 google.com

# Probar MTU con DF
ping -c 1 -M do -s 1472 8.8.8.8

# Ping con timestamp
ping -c 4 -D google.com

# Ping cada 0.5s
ping -i 0.5 -c 20 google.com

# Traceroute básico
traceroute -n 8.8.8.8

# Traceroute ICMP
traceroute -I -n 8.8.8.8

# Traceroute TCP (puerto 80)
traceroute -T -p 80 -n google.com

# mtr reporte (para logs/diagnóstico)
mtr -r -c 50 -n 8.8.8.8

# mtr mostrando AS
mtr -z 8.8.8.8

# mtr TCP
mtr -T -P 80 -n google.com

# Ver tráfico ICMP en vivo
sudo tcpdump -i any icmp

# Ver paquetes ICMP con TTL exceeded
sudo tcpdump -i any 'icmp[icmptype] = 11'

# Calcular jitter (variabilidad de latencia)
ping -c 100 google.com | tail -1 | awk '{print $10}' | cut -d/ -f4

# ¿Cuántos saltos hasta un destino?
traceroute -n 8.8.8.8 2>/dev/null | tail -1 | awk '{print $1}'

# Ping a broadcast para descubrir hosts en la LAN
ping -b -c 3 192.168.1.255
```
