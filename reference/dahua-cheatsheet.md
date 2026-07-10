# Dahua — Referencia rápida

Tabla de consulta rápida para administración de cámaras IP Dahua desde terminal.

---

## 📡 Puertos

| Puerto | Protocolo | Servicio |
|--------|-----------|----------|
| 80 | TCP | HTTP (interfaz web) |
| 443 | TCP | HTTPS |
| 554 | TCP/UDP | RTSP (video stream) |
| 22 | TCP | SSH (NVR) |
| 37777 | TCP/UDP | Dahua (protocolo propietario) |
| 3702 | UDP | ONVIF discovery |
| 123 | UDP | NTP |

---

## 🎥 URLs RTSP

| Stream | URL |
|--------|-----|
| Main stream (alta calidad) | `rtsp://user:pass@IP:554/Streaming/Channels/101` |
| Sub stream (baja calidad) | `rtsp://user:pass@IP:554/Streaming/Channels/102` |
| Third stream | `rtsp://user:pass@IP:554/Streaming/Channels/103` |

---

## 🔌 Endpoints CGI más usados

| Endpoint | Acción | Descripción |
|----------|--------|-------------|
| `/cgi-bin/magicBox.cgi?action=getSystemInfo` | GET | Información del sistema |
| `/cgi-bin/magicBox.cgi?action=reboot` | GET | Reiniciar cámara |
| `/cgi-bin/magicBox.cgi?action=reset` | GET | Factory reset |
| `/cgi-bin/global.cgi?action=getTime` | GET | Obtener hora |
| `/cgi-bin/global.cgi?action=setTime&time=EPOCH` | GET | Configurar hora |
| `/cgi-bin/snapshot.cgi` | GET | Capturar imagen |
| `/cgi-bin/user.cgi?action=getUser` | GET | Listar usuarios |
| `/cgi-bin/user.cgi?action=modify` | POST | Modificar usuario |
| `/cgi-bin/network.cgi?action=getIP` | GET | Obtener configuración de red |
| `/cgi-bin/network.cgi?action=setIP` | POST | Configurar IP |
| `/cgi-bin/ivs.cgi?action=getRule` | GET | Obtener reglas IVS |
| `/cgi-bin/ivs.cgi?action=getEvent` | GET | Obtener eventos |
| `/cgi-bin/configManager.cgi?action=getConfig` | GET | Obtener configuración |
| `/cgi-bin/configManager.cgi?action=setConfig` | POST | Configurar parámetros |

---

## 🔍 Comandos rápidos de diagnóstico

### Descubrir cámaras

```bash
# Por puerto Dahua
sudo nmap -sU -p 37777 192.168.1.0/24

# Por ONVIF
sudo nmap -sU -p 3702 192.168.1.0/24

# Por MAC address (Dahua OUI)
grep -i "9c:eb\|54:bf" /var/lib/misc/dnsmasq.leases
```

### Verificar conectividad

```bash
# Ping
ping -c 3 192.168.1.108

# Verificar API
curl -s -u admin:pass http://192.168.1.108/cgi-bin/magicBox.cgi?action=getSystemInfo

# Verificar RTSP
ffprobe rtsp://admin:pass@192.168.1.108:554/Streaming/Channels/101
```

### Capturar snapshot

```bash
curl -s -u admin:pass http://192.168.1.108/cgi-bin/snapshot.cgi -o snapshot.jpg
```

### Reiniciar cámara

```bash
curl -s -u admin:pass "http://192.168.1.108/cgi-bin/magicBox.cgi?action=reboot"
```

### Factory reset

```bash
curl -s -u admin:pass "http://192.168.1.108/cgi-bin/magicBox.cgi?action=reset"
```

---

## ❌ Códigos de error comunes

| Código | Significado | Causa probable |
|--------|-------------|----------------|
| 200 | OK | Operación exitosa |
| 401 | Unauthorized | Credenciales incorrectas |
| 403 | Forbidden | Permisos insuficientes |
| 404 | Not Found | Endpoint no existe |
| 500 | Internal Error | Error del servidor |
| 503 | Service Unavailable | Servicio caído |

---

## 🏷️ OUI de MAC addresses

| Fabricante | OUI |
|------------|-----|
| Dahua | 9C:EB, 54:BF |
| Hikvision | A4:F3, 88:67 |
| Uniview | 68:C4 |
| Axis | 00:40:8C |
| Bosch | 00:07:7C |

---

## 📚 Referencias a guías completas

| Tema | Guía |
|------|------|
| Descubrir cámaras | [`guides/dahua/dahua-discovery.md`](../guides/dahua/dahua-discovery.md) |
| API HTTP/CGI | [`guides/dahua/dahua-camera-api.md`](../guides/dahua/dahua-camera-api.md) |
| Diagnóstico RTSP | [`guides/dahua/dahua-rtsp-stream.md`](../guides/dahua/dahua-rtsp-stream.md) |
| Configuración masiva | [`guides/dahua/dahua-mass-config.md`](../guides/dahua/dahua-mass-config.md) |
| SSH a NVR | [`guides/dahua/dahua-nvr-ssh.md`](../guides/dahua/dahua-nvr-ssh.md) |
| WizSense/WizMind | [`guides/dahua/dahua-wizsense-wizmind.md`](../guides/dahua/dahua-wizsense-wizmind.md) |
| Troubleshooting | [`guides/dahua/dahua-troubleshooting.md`](../guides/dahua/dahua-troubleshooting.md) |

---

## 🔗 Recursos externos

- Documentación oficial Dahua API: https://www.dahuasecurity.com/support/api
- ONVIF standard: https://www.onvif.org
- Dahua WizSense: https://www.dahuasecurity.com/products/wizsense
- Dahua WizMind: https://www.dahuasecurity.com/products/wizmind
