# 🎥 Dahua — Diagnóstico de Video (RTSP)

**Nivel:** 🟡 Intermedio
**Herramientas:** `ffprobe`, `ffplay`, `ffmpeg`, `tcpdump`, `curl`

---

## ⚡ Quick command

```bash
ffprobe rtsp://admin:contraseña@192.168.1.108:554/Streaming/Channels/101
```

---

## 📋 URLs RTSP en Dahua

Las cámaras Dahua tienen dos streams principales accesibles por RTSP:

| Canal | URL |
|-------|-----|
| Main stream | `rtsp://user:pass@IP:554/Streaming/Channels/101` |
| Sub stream | `rtsp://user:pass@IP:554/Streaming/Channels/102` |

---

## 🔍 Diagnóstico básico

### 1. Verificar que el stream responde

```bash
ffprobe rtsp://admin:contraseña@192.168.1.108:554/Streaming/Channels/101 2>&1
```

**Salida esperada (extracto):**

```text
Input #0, rtsp, from 'rtsp://admin:contraseña@192.168.1.108:554/...':
  Duration: N/A, start: 0.000000, bitrate: N/A
  Stream #0:0: Video: h264 (High), yuvj420p(pc, bt709, progressive),
    2592x1944, 25 fps, 25 tbr, 90k tbn, 50 tbc
```

**Lo que dice:**

- `h264 (High)` → codec H.264 perfil alto
- `2592x1944` → resolución 5MP
- `25 fps` → 25 cuadros por segundo (normal en PAL)

### 2. Ver video en vivo desde terminal

```bash
# Reproducir en ventana
ffplay rtsp://admin:contraseña@192.168.1.108:554/Streaming/Channels/101

# Reproducir sin ventana (solo audio si hay, o mute)
ffplay -nodisp rtsp://admin:contraseña@192.168.1.108:554/Streaming/Channels/101

# Bajo demanda (para ahorrar ancho de banda)
ffplay -rtsp_transport tcp rtsp://admin:contraseña@192.168.1.108:554/Streaming/Channels/102
```

### 3. Capturar segmento de video a archivo

```bash
# Capturar 10 segundos
ffmpeg -t 10 -i rtsp://admin:contraseña@192.168.1.108:554/Streaming/Channels/101 \
  -c copy captura.mp4

# Capturar 1 frame (foto de diagnóstico)
ffmpeg -i rtsp://admin:contraseña@192.168.1.108:554/Streaming/Channels/101 \
  -frames:v 1 -q:v 2 frame_diagnostico.jpg
```

---

## 🚨 Diagnóstico de problemas comunes

### Problema 1: "Connection refused" o timeout

```bash
# Verificar que el puerto RTSP (554) está abierto
nmap -p 554 192.168.1.108

# Capturar tráfico RTSP para ver qué responde
tcpdump -i eth0 -nn port 554 -X
```

**Causas posibles:**

1. La cámara no tiene RTSP habilitado (revisar por API)
2. Firewall bloqueando el puerto
3. La cámara está en otra VLAN y no hay ruteo

### Problema 2: "Unauthorized"

```bash
# Verificar credenciales
curl -s -o /dev/null -w "%{http_code}" -u admin:contraseña \
  "http://192.168.1.108/cgi-bin/user.cgi?action=getUser"
# Debería devolver 200, si devuelve 401 son credenciales incorrectas
```

### Problema 3: Video pixelado / entrecortado

```bash
# Verificar FPS real vs nominal
ffprobe rtsp://admin:contraseña@192.168.1.108:554/Streaming/Channels/101 2>&1 \
  | grep fps

# Verificar ancho de banda usado (desde el NVR o router)
sudo nload eth0

# Verificar pérdida de paquetes en el switch (SNMP)
snmpwalk -v2c -c public 192.168.1.1 1.3.6.1.2.1.2.2.1.14
# Si hay muchos "out errors" o "discards", el switch está saturado
```

### Problema 4: Cámara no envía video (stream muerto)

```bash
# 1. Verificar que la cámara responde
ping -c 3 192.168.1.108

# 2. Verificar que el servicio RTSP está vivo
curl -s -u admin:contraseña \
  "http://192.168.1.108/cgi-bin/media.cgi?action=getMain" \
  | sed -n 's/.*<status>\([^<]*\).*/\1/p'
# Debería devolver "Running"

# 3. Verificar codecs habilitados
curl -s -u admin:contraseña \
  "http://192.168.1.108/cgi-bin/configManager.cgi?action=getConfig&name=Video" \
  | sed -n 's/.*<Compression>\([^<]*\).*/\1/p'
# Debería ser H.264 o H.265
```

---

## ⚙️ Cambiar configuración de video desde terminal

```bash
# Cambiar resolución a 1080p (2MP)
curl -s -k -u admin:contraseña \
  -d "video.ChannelNumber=0&video.EncodeMode=H.264&video.Resolution=1920x1080&video.FPS=25" \
  "http://192.168.1.108/cgi-bin/configManager.cgi?action=setConfig"

# Cambiar a 4K
curl -s -k -u admin:contraseña \
  -d "video.ChannelNumber=0&video.EncodeMode=H.265&video.Resolution=3840x2160&video.FPS=20" \
  "http://192.168.1.108/cgi-bin/configManager.cgi?action=setConfig"
```

---

## 💡 Uno-liners

```bash
# Ver resolución y FPS
ffprobe -v quiet -print_format json rtsp://admin:pass@192.168.1.108:554/Streaming/Channels/101 | jq '.streams[0] | {width, height, r_frame_rate}'

# Capturar 1 frame para diagnóstico
ffmpeg -rtsp_transport tcp -i rtsp://admin:pass@192.168.1.108:554/Streaming/Channels/101 -frames:v 1 -f image2 - 2>/dev/null | base64

# Verificar conectividad RTSP con timeout
timeout 5 ffprobe rtsp://admin:pass@192.168.1.108:554/Streaming/Channels/101 2>&1 && echo "✅ OK" || echo "❌ FALLA"

# Calcular ancho de banda del stream (en kbps)
ffprobe -v quiet rtsp://admin:pass@192.168.1.108:554/Streaming/Channels/101 2>&1 | grep bitrate | awk '{print $NF}'
```

---

## 🔗 Ver también

- [`dahua-camera-api.md`](dahua-camera-api.md) — cambiar configuración de video por API
- [`../tcpdump.md`](../tcpdump.md) — captura de paquetes para diagnóstico avanzado
- [`../../labs/docker-compose.dahua-broken.yml`](../../labs/docker-compose.dahua-broken.yml) — laboratorio con pérdida de paquetes: `cd labs && docker compose -f docker-compose.dahua-broken.yml up -d`
