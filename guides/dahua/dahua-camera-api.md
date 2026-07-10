# 📡 Dahua — API HTTP/ISAPI desde Terminal

**Nivel:** 🟡 Intermedio
**Herramientas:** `curl`, `jq` (opcional), `xmllint` (opcional)

---

## ⚡ Quick command

```bash
curl -k -u admin:contraseña "http://192.168.1.108/cgi-bin/magicBox.cgi?action=getSystemInfo"
```

---

## 🧠 Fundamentos

Todas las cámaras Dahua modernas exponen una API CGI/ISAPI mediante HTTP.

La autenticación es HTTP Basic Auth sobre HTTPS si está disponible.

**Formato base de las URLs:**

```text
http://<IP>/cgi-bin/<categoria>.cgi?action=<acción>[&parámetros]
```

---

## 📋 Categorías de API

| Categoría | Descripción |
|-----------|-------------|
| `magicBox.cgi` | Información del sistema, reboot, factory reset |
| `configManager.cgi` | Configuración general del dispositivo |
| `media.cgi` | Configuración de video/audio |
| `user.cgi` | Gestión de usuarios |
| `snapshot.cgi` | Captura de imágenes |
| `ivs.cgi` | Inteligencia de video (detección de movimiento, etc.) |
| `faceRecognition.cgi` | Reconocimiento facial (WizMind) |
| `storage.cgi` | Gestión de almacenamiento |
| `network.cgi` | Configuración de red |
| `ptz.cgi` | Control PTZ (pan/tilt/zoom) |
| `record.cgi` | Control de grabación |

---

## 📋 Ejemplos prácticos

### 1. Información del sistema

```bash
curl -s -k -u admin:contraseña \
  "http://192.168.1.108/cgi-bin/magicBox.cgi?action=getSystemInfo" \
  | xmllint --format -

# Salida:
# <systemInfo>
#   <deviceName>IPC-B52</deviceName>
#   <serialNumber>4P0720GAMG00001</serialNumber>
#   <deviceType>IPC-B52</deviceType>
#   <softwareVersion>V3.12.0001.0</softwareVersion>
#   <hardwareVersion>1.00</hardwareVersion>
# </systemInfo>
```

### 2. Sincronizar hora

```bash
# Sincronizar con la hora del servidor
curl -s -k -u admin:contraseña \
  "http://192.168.1.108/cgi-bin/global.cgi?action=setTime&time=$(date +%s)"

# Ver hora actual de la cámara
curl -s -k -u admin:contraseña \
  "http://192.168.1.108/cgi-bin/global.cgi?action=getTime"
```

### 3. Cambiar contraseña

```bash
curl -s -k -u admin:contraseña_actual \
  -d "user.Name=admin&user.Password=nueva_contraseña" \
  "http://192.168.1.108/cgi-bin/user.cgi?action=modify"
```

### 4. Configurar IP

```bash
curl -s -k -u admin:contraseña \
  "http://192.168.1.108/cgi-bin/network.cgi?action=setIP" \
  -d "ip=192.168.100.50&mask=255.255.255.0&gateway=192.168.100.1"
```

### 5. Capturar snapshot

```bash
curl -s -k -u admin:contraseña \
  "http://192.168.1.108/cgi-bin/snapshot.cgi" \
  -o camara_snapshot.jpg
```

### 6. Configurar NTP

```bash
curl -s -k -u admin:contraseña \
  -d "NTPServer=192.168.100.1&port=123&timeZone=ART" \
  "http://192.168.1.108/cgi-bin/configManager.cgi?action=setConfig&NTPServer=192.168.100.1"
```

### 7. Agregar cámara a NVR vía API (en el NVR)

```bash
curl -s -k -u admin:contraseña_nvr \
  -d "method=add&ip=192.168.100.50&port=37777&user=admin&pass=contraseña&channel=1" \
  "http://192.168.100.10/cgi-bin/record.cgi?action=addDevice"
```

### 8. Consultar eventos de IA (WizMind)

```bash
# Últimas detecciones de persona
curl -s -k -u admin:contraseña \
  "http://192.168.1.108/cgi-bin/ivs.cgi?action=getEvent&type=Human&count=10"

# Últimas patentes detectadas (ANPR)
curl -s -k -u admin:contraseña \
  "http://192.168.1.108/cgi-bin/faceRecognition.cgi?action=getLastPlate"
```

---

## 🧠 Parsear respuestas XML

Las respuestas de Dahua vienen en XML. Para procesarlas desde terminal:

```bash
# Extraer serial number
curl -s -k -u admin:contraseña \
  "http://192.168.1.108/cgi-bin/magicBox.cgi?action=getSystemInfo" \
  | sed -n 's/.*<serialNumber>\([^<]*\).*/\1/p'

# Extraer versión de firmware
curl -s -k -u admin:contraseña \
  "http://192.168.1.108/cgi-bin/magicBox.cgi?action=getSystemInfo" \
  | sed -n 's/.*<softwareVersion>\([^<]*\).*/\1/p'

# Extraer estado de detección IVS
curl -s -k -u admin:contraseña \
  "http://192.168.1.108/cgi-bin/ivs.cgi?action=getRule" \
  | sed -n 's/.*<Enable>\([^<]*\).*/\1/p'
```

---

## 🔄 Script de autenticación wrapper

Para no escribir `-u admin:contraseña` cada vez:

```bash
# ~/bin/dahua.sh
#!/bin/bash
DAHUA_USER="admin"
DAHUA_PASS="contraseña"

dahua() {
  local ip="$1"
  shift
  curl -s -k -u "$DAHUA_USER:$DAHUA_PASS" "http://$ip/cgi-bin/$*"
}

# Uso:
dahua 192.168.1.108 magicBox.cgi?action=getSystemInfo
dahua 192.168.1.108 snapshot.cgi > foto.jpg
```

---

## 💡 Uno-liners

```bash
# Ver modelo y versión
curl -su admin:pass http://192.168.1.108/cgi-bin/magicBox.cgi?action=getSystemInfo | sed -n 's/.*<\(deviceName\|softwareVersion\)>\([^<]*\).*/\1: \2/p'

# Capturar foto
curl -su admin:pass http://192.168.1.108/cgi-bin/snapshot.cgi -o /tmp/$(date +%s).jpg

# Ver hora de la cámara
curl -su admin:pass http://192.168.1.108/cgi-bin/global.cgi?action=getTime

# Sincronizar hora con el servidor
curl -su admin:pass "http://192.168.1.108/cgi-bin/global.cgi?action=setTime&time=$(date +%s)"

# Reboot remoto
curl -su admin:pass "http://192.168.1.108/cgi-bin/magicBox.cgi?action=reboot"

# Reset a fábrica
curl -su admin:pass "http://192.168.1.108/cgi-bin/magicBox.cgi?action=reset"
```

---

## 🔗 Ver también

- [`dahua-discovery.md`](dahua-discovery.md) — cómo encontrar las cámaras
- [`dahua-mass-config.md`](dahua-mass-config.md) — script para configurar muchas
- [`dahua-rtsp-stream.md`](dahua-rtsp-stream.md) — diagnóstico de video
