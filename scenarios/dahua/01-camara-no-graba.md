# 🧩 Escenario: Cámara Dahua no transmite video

**Dominio:** networking / infrastructure
**Nivel:** 🟡 Intermedio
**Herramientas:** `ping`, `nmap`, `curl`, `ffprobe`, `tcpdump`
**Archivos:** N/A (diagnóstico en vivo)

---

## 🎯 Problema

Una cámara IP Dahua aparece como "online" en el NVR pero no muestra video. El NVR reporta "disconnected" o "no signal" en el canal correspondiente.

---

## ⚡ Quick command (SRE)

```bash
ping -c 3 192.168.1.108 && nmap -p 554 192.168.1.108 && curl -s -u admin:admin "http://192.168.1.108/cgi-bin/magicBox.cgi?action=getSystemInfo" | grep -q "deviceName" && echo "✅ Cámara responde" || echo "❌ Cámara no responde"
```

---

## ✅ Salida esperada

```text
PING 192.168.1.108 (192.168.1.108) 56(84) bytes of data.
64 bytes from 192.168.1.108: icmp_seq=1 ttl=64 time=0.5ms
64 bytes from 192.168.1.108: icmp_seq=2 ttl=64 time=0.4ms
64 bytes from 192.168.1.108: icmp_seq=3 ttl=64 time=0.5ms

--- 192.168.1.108 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss

Starting Nmap 7.93 ( https://nmap.org )
Nmap scan report for 192.168.1.108
Host is up (0.00045s latency).
PORT    STATE SERVICE
554/tcp open  rtsp

✅ Cámara responde
```

**Interpretación:**

- Ping exitoso → conectividad de red OK
- Puerto 554 abierto → servicio RTSP activo
- API responde → cámara funcionando

---

## 🧠 Diagnóstico

### Paso 1: Verificar conectividad básica

```bash
# ¿La cámara responde a ping?
ping -c 3 192.168.1.108

# ¿El puerto RTSP está abierto?
nmap -p 554 192.168.1.108

# ¿El puerto Dahua está abierto?
nmap -p 37777 192.168.1.108
```

**Patrones clave:**

- Ping falla → problema de red (cable, VLAN, IP)
- Ping OK pero puertos cerrados → servicio caído o firewall
- Todo abierto → problema de configuración o credenciales

### Paso 2: Verificar API HTTP

```bash
# ¿La API responde?
curl -s -u admin:admin \
  "http://192.168.1.108/cgi-bin/magicBox.cgi?action=getSystemInfo" \
  | grep -q "deviceName" && echo "✅ API OK" || echo "❌ API FAIL"

# Ver información del sistema
curl -s -u admin:admin \
  "http://192.168.1.108/cgi-bin/magicBox.cgi?action=getSystemInfo" \
  | sed -n 's/.*<deviceName>\([^<]*\).*/Modelo: \1/p'
```

**Patrones clave:**

- 401 Unauthorized → credenciales incorrectas
- Connection refused → servicio web caído
- Timeout → firewall bloqueando puerto 80

### Paso 3: Verificar stream RTSP

```bash
# ¿El stream RTSP responde?
ffprobe rtsp://admin:admin@192.168.1.108:554/Streaming/Channels/101 2>&1 | grep -q "h264" && echo "✅ RTSP OK" || echo "❌ RTSP FAIL"

# Ver detalles del stream
ffprobe rtsp://admin:admin@192.168.1.108:554/Streaming/Channels/101 2>&1 | grep -E "Stream|Video|Audio"
```

**Patrones clave:**

- Connection refused → servicio RTSP caído
- Unauthorized → credenciales incorrectas
- Timeout → firewall bloqueando puerto 554

### Paso 4: Capturar tráfico para diagnóstico avanzado

```bash
# Capturar tráfico RTSP
sudo tcpdump -i eth0 host 192.168.1.108 and port 554 -w /tmp/rtsp.pcap

# Capturar tráfico Dahua
sudo tcpdump -i eth0 host 192.168.1.108 and port 37777 -w /tmp/dahua.pcap

# Analizar captura
tcpdump -r /tmp/rtsp.pcap -n | head -20
```

---

## 🛠️ Procedimiento (runbook)

### 1. Verificar conectividad de red

```bash
# Ping a la cámara
ping -c 3 192.168.1.108

# Si falla, verificar:
# - Cable conectado (LED del puerto)
# - PoE activo (si usa PoE)
# - VLAN correcta
# - IP correcta (hacer discovery)
```

### 2. Verificar puertos

```bash
# Escanear puertos principales
nmap -p 80,443,554,37777 192.168.1.108

# Si puertos cerrados:
# - Verificar firewall (iptables, firewalld)
# - Verificar configuración de red de la cámara
# - Reiniciar cámara
```

### 3. Verificar API HTTP

```bash
# Probar API
curl -v -u admin:admin \
  "http://192.168.1.108/cgi-bin/magicBox.cgi?action=getSystemInfo"

# Si falla con 401:
# - Verificar credenciales
# - Cambiar contraseña vía API o factory reset

# Si falla con connection refused:
# - Reiniciar servicio web
ssh admin@192.168.1.108 "/etc/init.d/httpd restart"
```

### 4. Verificar stream RTSP

```bash
# Probar RTSP con ffprobe
ffprobe rtsp://admin:admin@192.168.1.108:554/Streaming/Channels/101

# Si falla:
# - Verificar URL correcta (101 = main, 102 = sub)
# - Verificar credenciales
# - Cambiar codec a H.264 (más compatible)
curl -s -u admin:admin \
  -d "video.EncodeMode=H.264" \
  "http://192.168.1.108/cgi-bin/configManager.cgi?action=setConfig"
```

### 5. Reiniciar servicios

```bash
# Reiniciar cámara vía API
curl -s -u admin:admin \
  "http://192.168.1.108/cgi-bin/magicBox.cgi?action=reboot"

# Esperar 30 segundos y verificar
sleep 30
ping -c 3 192.168.1.108
```

### 6. Factory reset (último recurso)

```bash
# Reset físico: mantener botón 10 segundos
# O vía API:
curl -s -u admin:admin \
  "http://192.168.1.108/cgi-bin/magicBox.cgi?action=reset"

# Después del reset, credenciales son admin/admin
# Reconfigurar IP, contraseña, NTP
```

---

## 🧯 Mitigación

**Verificar:**

```bash
# Diagnóstico completo
ping -c 1 192.168.1.108 >/dev/null && echo "✅ Ping" || echo "❌ Ping"
nmap -p 554 192.168.1.108 | grep -q "open" && echo "✅ RTSP" || echo "❌ RTSP"
curl -s -u admin:admin "http://192.168.1.108/cgi-bin/magicBox.cgi?action=getSystemInfo" | grep -q "deviceName" && echo "✅ API" || echo "❌ API"
```

**Acción:**

```bash
# Si todo falla, reiniciar cámara
curl -s -u admin:admin "http://192.168.1.108/cgi-bin/magicBox.cgi?action=reboot"

# Si no responde, factory reset físico
# (botón en la cámara, mantener 10 segundos)
```

**Rollback:**

```bash
# Si el reset causa problemas, reconfigurar:
# 1. Asignar IP estática
curl -s -u admin:admin \
  -d "ip=192.168.1.108&mask=255.255.255.0&gateway=192.168.1.1" \
  "http://192.168.1.108/cgi-bin/network.cgi?action=setIP"

# 2. Cambiar contraseña
curl -s -u admin:admin \
  -d "user.Name=admin&user.Password=NuevaPassword123" \
  "http://192.168.1.108/cgi-bin/user.cgi?action=modify"

# 3. Configurar NTP
curl -s -u admin:admin \
  -d "NTPServer=192.168.1.1&port=123&timeZone=ART" \
  "http://192.168.1.108/cgi-bin/configManager.cgi?action=setConfig"
```

**Casos comunes:**

- Cable desconectado → reconectar cable
- PoE inactivo → verificar switch PoE o injector
- IP incorrecta → hacer discovery y reconfigurar
- Firewall bloqueando → abrir puertos 80, 554, 37777
- Servicio caído → reiniciar cámara

---

## ✅ Interpretación

- **Ping falla** → problema de capa 1-3 (cable, switch, VLAN, IP)
- **Ping OK, puertos cerrados** → servicio caído o firewall
- **Puertos abiertos, API falla** → credenciales incorrectas
- **API OK, RTSP falla** → problema de codec o configuración de video
- **Todo OK pero NVR no muestra** → problema de configuración del NVR

---

## 🧪 Cómo practicarlo en el lab

Usá el [laboratorio Docker Dahua](../../labs/docker-compose.dahua.yml) para simular los comandos del escenario contra una cámara y NVR virtualizados. Aplicá los pasos del procedimiento para diagnosticar cada caso.

---

## 🧑‍🏫 Modo docente

**Preguntas:** ¿Qué puertos verificás en una cámara Dahua? ¿Cómo probás el stream RTSP con ffprobe? ¿Qué endpoint de la API HTTP usás para obtener información del sistema?

**Ejercicio:** Diagnosticar una cámara que no transmite: verificar conectividad RTSP, consultar API HTTP, revisar logs de la cámara.

**Evaluación:** diagnóstico capa por capa (red -> puertos -> API -> RTSP), identificación correcta del problema.

---

## 🔗 Referencias

- [`guides/dahua/dahua-discovery.md`](../../guides/dahua/dahua-discovery.md) — descubrir cámaras
- [`guides/dahua/dahua-camera-api.md`](../../guides/dahua/dahua-camera-api.md) — API HTTP/CGI
- [`guides/dahua/dahua-rtsp-stream.md`](../../guides/dahua/dahua-rtsp-stream.md) — diagnóstico RTSP
- [`guides/dahua/dahua-troubleshooting.md`](../../guides/dahua/dahua-troubleshooting.md) — troubleshooting completo
- [`reference/dahua-cheatsheet.md`](../../reference/dahua-cheatsheet.md) — referencia rápida
