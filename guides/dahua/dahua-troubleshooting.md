# 🚨 Dahua — Diagnóstico de fallas comunes

**Nivel:** 🟡 Intermedio
**Herramientas:** `ping`, `nmap`, `curl`, `ffprobe`, `tcpdump`

---

## ⚡ Quick command

```bash
ping -c 3 192.168.1.108 && curl -s -u admin:admin "http://192.168.1.108/cgi-bin/magicBox.cgi?action=getSystemInfo" | grep -q "deviceName" && echo "✅ Cámara responde" || echo "❌ Cámara no responde"
```

---

## 🌳 Árbol de decisión

```text
¿La cámara responde a ping?
├─ NO → Problema de red (ver Falla 1)
└─ SÍ → ¿Puedes acceder por web/API?
         ├─ NO → Problema de servicio (ver Falla 8)
         └─ SÍ → ¿El video se ve?
                  ├─ NO → Problema de RTSP (ver Falla 9)
                  └─ SÍ → ¿La IA detecta?
                           ├─ NO → Problema de IA (ver Falla 10)
                           └─ SÍ → ✅ Cámara funcionando
```

---

## 🔴 Falla 1: Cámara no responde

### Síntomas

- `ping` no devuelve respuesta
- Cámara no aparece en discovery
- NVR no detecta la cámara

### Diagnóstico

```bash
# 1. Verificar conectividad básica
ping -c 3 192.168.1.108

# 2. Verificar que el puerto HTTP está abierto
nmap -p 80 192.168.1.108

# 3. Verificar que el puerto Dahua está abierto
nmap -p 37777 192.168.1.108

# 4. Verificar tabla ARP
arp -n | grep 192.168.1.108

# 5. Capturar tráfico para ver si hay respuesta
tcpdump -i eth0 host 192.168.1.108 -n
```

### Causas posibles

1. **Cámara sin energía**
   - Verificar PoE: ¿el switch muestra el puerto activo?
   - Verificar cable: ¿el LED del puerto está encendido?
   - Verificar injector PoE: ¿tiene voltaje?

2. **Cámara en otra VLAN**
   - Verificar configuración de VLAN en el switch
   - Verificar que hay ruteo entre VLANs

3. **Cámara con IP incorrecta**
   - Hacer discovery para encontrarla
   - Verificar leases DHCP

4. **Cable defectuoso**
   - Probar con otro cable
   - Verificar con toner/cable tester

### Solución

```bash
# Si es PoE, resetear puerto
# (comando varía según marca del switch)
# Ejemplo Ubiquiti:
ssh admin@switch "set poe off 10 && set poe on 10"

# Si es DHCP, verificar leases
cat /var/lib/misc/dnsmasq.leases | grep 192.168.1.108

# Si no responde, hacer factory reset
# (botón físico en la cámara, mantener 10 segundos)
```

---

## 🔴 Falla 2: Video pixelado / entrecortado

### Síntomas

- Video se ve con artefactos
- Frame rate bajo
- Congelamientos frecuentes

### Diagnóstico

```bash
# 1. Verificar FPS real
ffprobe rtsp://admin:contraseña@192.168.1.108:554/Streaming/Channels/101 2>&1 | grep fps

# 2. Verificar ancho de banda
sudo nload eth0

# 3. Verificar pérdida de paquetes
ping -c 100 192.168.1.108 | grep "packet loss"

# 4. Verificar errores en interfaz
ip -s link show eth0 | grep -A 5 "RX:\|TX:"

# 5. Capturar tráfico RTSP
tcpdump -i eth0 port 554 -w /tmp/rtsp.pcap
```

### Causas posibles

1. **Ancho de banda insuficiente**
   - Cámara 4K consume ~8 Mbps
   - 50 cámaras = 400 Mbps
   - Verificar capacidad del switch

2. **Cable defectuoso**
   - Verificar errores de TX/RX
   - Probar con otro cable

3. **Switch saturado**
   - Verificar uso de CPU del switch
   - Verificar buffer overflow

4. **Configuración de codec incorrecta**
   - H.265 consume menos que H.264
   - Reducir bitrate

### Solución

```bash
# Reducir bitrate
curl -s -u admin:contraseña \
  -d "video.BitRate=2048" \
  "http://192.168.1.108/cgi-bin/configManager.cgi?action=setConfig"

# Cambiar a H.265
curl -s -u admin:contraseña \
  -d "video.EncodeMode=H.265" \
  "http://192.168.1.108/cgi-bin/configManager.cgi?action=setConfig"

# Reducir FPS
curl -s -u admin:contraseña \
  -d "video.FPS=15" \
  "http://192.168.1.108/cgi-bin/configManager.cgi?action=setConfig"
```

---

## 🔴 Falla 3: NVR no detecta cámara

### Síntomas

- Cámara responde a ping
- NVR muestra "disconnected" o "offline"

### Diagnóstico

```bash
# 1. Verificar que la cámara responde
ping -c 3 192.168.1.108

# 2. Verificar credenciales
curl -s -o /dev/null -w "%{http_code}" -u admin:contraseña \
  "http://192.168.1.108/cgi-bin/user.cgi?action=getUser"

# 3. Verificar que el puerto Dahua está abierto
nmap -p 37777 192.168.1.108

# 4. Verificar configuración de red de la cámara
curl -s -u admin:contraseña \
  "http://192.168.1.108/cgi-bin/network.cgi?action=getIP"

# 5. Verificar que NVR y cámara están en la misma VLAN
# (verificar gateway y máscara)
```

### Causas posibles

1. **Credenciales incorrectas**
   - Verificar usuario/contraseña
   - La cámara puede tener credenciales diferentes al NVR

2. **Cámara en otra subred**
   - Verificar IP, máscara, gateway
   - Verificar que hay ruteo

3. **Firewall bloqueando**
   - Verificar reglas de iptables
   - Verificar que puerto 37777 está abierto

4. **Versión de protocolo incompatible**
   - Cámara muy nueva, NVR muy viejo
   - Actualizar firmware del NVR

### Solución

```bash
# Re-agregar cámara al NVR vía API
curl -s -u admin:contraseña_nvr \
  -d "method=add&ip=192.168.1.108&port=37777&user=admin&pass=contraseña&channel=1" \
  "http://192.168.100.100/cgi-bin/record.cgi?action=addDevice"

# Si no funciona, eliminar y re-agregar
curl -s -u admin:contraseña_nvr \
  -d "method=delete&channel=1" \
  "http://192.168.100.100/cgi-bin/record.cgi?action=deleteDevice"
```

---

## 🔴 Falla 4: NVR no graba

### Síntomas

- NVR está online
- No hay grabaciones en el timeline

### Diagnóstico

```bash
# 1. SSH al NVR
ssh admin@192.168.100.100

# 2. Verificar estado de discos
df -h

# 3. Verificar que los discos están montados
ls -la /mnt/

# 4. Verificar logs de grabación
cat /var/log/record.log | tail -50

# 5. Verificar que el servicio de grabación está corriendo
ps aux | grep record

# 6. Verificar configuración de grabación
curl -s -u admin:contraseña \
  "http://192.168.100.100/cgi-bin/configManager.cgi?action=getConfig&name=Record"
```

### Causas posibles

1. **Disco lleno**
   - Verificar espacio con `df -h`
   - Configurar rotación automática

2. **Disco no montado**
   - Verificar `/mnt/sda/` existe
   - Verificar `dmesg` para errores de disco

3. **Servicio de grabación caído**
   - Reiniciar servicio
   - Verificar logs

4. **Configuración de grabación incorrecta**
   - Verificar horarios
   - Verificar canales habilitados

### Solución

```bash
# Reiniciar servicio de grabación
/etc/init.d/record restart

# Limpiar grabaciones viejas
find /mnt/sda/record -name "*.mp4" -mtime +30 -delete

# Verificar espacio
df -h /mnt/sda

# Configurar rotación automática
curl -s -u admin:contraseña \
  -d "Record.Overwrite=true&Record.PreRecord=5" \
  "http://192.168.100.100/cgi-bin/configManager.cgi?action=setConfig"
```

---

## 🔴 Falla 5: Disco lleno / error de disco

### Síntomas

- NVR muestra alerta de disco
- No se pueden guardar grabaciones
- `df -h` muestra 100% de uso

### Diagnóstico

```bash
# SSH al NVR
ssh admin@192.168.100.100

# Ver uso de disco
df -h

# Ver tamaño de grabaciones
du -sh /mnt/sda/record/*

# Ver SMART status
smartctl -a /dev/sda

# Ver logs de errores de disco
dmesg | grep -i "sda\|error\|bad"

# Verificar integridad del sistema de archivos
fsck /dev/sda
```

### Causas posibles

1. **Disco lleno**
   - Grabaciones muy antiguas
   - Rotación no configurada

2. **Disco defectuoso**
   - SMART muestra errores
   - `dmesg` muestra I/O errors

3. **Sistema de archivos corrupto**
   - Apagón inesperado
   - Disco removido en caliente

### Solución

```bash
# Limpiar grabaciones viejas
find /mnt/sda/record -name "*.mp4" -mtime +7 -delete

# Configurar rotación automática
curl -s -u admin:contraseña \
  -d "Record.RetentionDays=7" \
  "http://192.168.100.100/cgi-bin/configManager.cgi?action=setConfig"

# Si el disco está defectuoso, reemplazar
# 1. Apagar NVR
# 2. Reemplazar disco
# 3. Encender NVR
# 4. Formatear disco desde interfaz web
```

---

## 🔴 Falla 6: Error de autenticación

### Síntomas

- `curl` devuelve 401 Unauthorized
- Interfaz web pide credenciales constantemente
- NVR no puede conectarse a la cámara

### Diagnóstico

```bash
# Verificar credenciales
curl -s -o /dev/null -w "%{http_code}" -u admin:contraseña \
  "http://192.168.1.108/cgi-bin/user.cgi?action=getUser"

# Si devuelve 401, credenciales incorrectas
# Si devuelve 200, credenciales correctas

# Verificar usuarios configurados
curl -s -u admin:contraseña \
  "http://192.168.1.108/cgi-bin/user.cgi?action=getUser"
```

### Causas posibles

1. **Contraseña incorrecta**
   - Cambio reciente no actualizado
   - Typo en el script

2. **Usuario bloqueado**
   - Muchos intentos fallidos
   - Política de seguridad

3. **Credenciales por defecto**
   - Cámara nueva con admin/admin
   - Necesita cambio inicial

### Solución

```bash
# Cambiar contraseña
curl -s -u admin:contraseña_actual \
  -d "user.Name=admin&user.Password=nueva_contraseña" \
  "http://192.168.1.108/cgi-bin/user.cgi?action=modify"

# Si está bloqueado, hacer factory reset
# (botón físico en la cámara, mantener 10 segundos)

# Después del reset, credenciales son admin/admin
```

---

## 🔴 Falla 7: Hora incorrecta

### Síntomas

- Timestamps en grabaciones son incorrectos
- Hora en OSD (on-screen display) es wrong
- Logs muestran hora equivocada

### Diagnóstico

```bash
# Ver hora actual de la cámara
curl -s -u admin:contraseña \
  "http://192.168.1.108/cgi-bin/global.cgi?action=getTime"

# Ver configuración NTP
curl -s -u admin:contraseña \
  "http://192.168.1.108/cgi-bin/configManager.cgi?action=getConfig&name=NTP"
```

### Causas posibles

1. **NTP no configurado**
   - Cámara sin servidor NTP
   - Hora se desincroniza

2. **Servidor NTP inaccesible**
   - Firewall bloqueando puerto 123
   - Servidor NTP caído

3. **Timezone incorrecto**
   - Configurado UTC en vez de ART
   - Diferencia de 3 horas

### Solución

```bash
# Configurar NTP
curl -s -u admin:contraseña \
  -d "NTPServer=192.168.100.1&port=123&timeZone=ART" \
  "http://192.168.1.108/cgi-bin/configManager.cgi?action=setConfig"

# Sincronizar manualmente
curl -s -u admin:contraseña \
  "http://192.168.1.108/cgi-bin/global.cgi?action=setTime&time=$(date +%s)"

# Verificar
curl -s -u admin:contraseña \
  "http://192.168.1.108/cgi-bin/global.cgi?action=getTime"
```

---

## 🔴 Falla 8: No se puede acceder por web

### Síntomas

- Navegador no puede cargar interfaz web
- `curl` no responde
- Puerto 80 cerrado

### Diagnóstico

```bash
# Verificar que el puerto HTTP está abierto
nmap -p 80 192.168.1.108

# Verificar que el puerto HTTPS está abierto
nmap -p 443 192.168.1.108

# Verificar que el servicio web está corriendo
# (requiere SSH)
ssh admin@192.168.1.108 "ps aux | grep httpd"

# Verificar logs
ssh admin@192.168.1.108 "cat /var/log/httpd.log | tail -50"
```

### Causas posibles

1. **Servicio web caído**
   - Crash del proceso
   - Memoria insuficiente

2. **Firewall bloqueando**
   - Regla de iptables
   - Firewall del switch

3. **Puerto incorrecto**
   - Cámara configurada en puerto 8080
   - Navegador usando puerto 80

### Solución

```bash
# Reiniciar servicio web
ssh admin@192.168.1.108 "/etc/init.d/httpd restart"

# Si no funciona, reiniciar cámara
curl -s -u admin:contraseña \
  "http://192.168.1.108/cgi-bin/magicBox.cgi?action=reboot"

# Si no responde, factory reset
# (botón físico, mantener 10 segundos)
```

---

## 🔴 Falla 9: RTSP no funciona

### Síntomas

- `ffprobe` no puede conectar
- Video no se ve en VLC
- NVR no muestra video

### Diagnóstico

```bash
# Verificar que el puerto RTSP está abierto
nmap -p 554 192.168.1.108

# Verificar URL RTSP
ffprobe rtsp://admin:contraseña@192.168.1.108:554/Streaming/Channels/101

# Capturar tráfico RTSP
tcpdump -i eth0 port 554 -X

# Verificar que el servicio RTSP está corriendo
ssh admin@192.168.1.108 "ps aux | grep rtsp"
```

### Causas posibles

1. **Servicio RTSP caído**
   - Crash del proceso
   - Recursos insuficientes

2. **URL incorrecta**
   - Canal incorrecto (101 vs 102)
   - Typo en la URL

3. **Firewall bloqueando**
   - Puerto 554 cerrado
   - NAT incorrecto

4. **Codec incompatible**
   - H.265 no soportado por cliente
   - Cambiar a H.264

### Solución

```bash
# Reiniciar servicio RTSP
ssh admin@192.168.1.108 "/etc/init.d/rtsp restart"

# Cambiar codec a H.264
curl -s -u admin:contraseña \
  -d "video.EncodeMode=H.264" \
  "http://192.168.1.108/cgi-bin/configManager.cgi?action=setConfig"

# Verificar URL correcta
# Main stream: rtsp://user:pass@IP:554/Streaming/Channels/101
# Sub stream: rtsp://user:pass@IP:554/Streaming/Channels/102
```

---

## 🔴 Falla 10: IA no detecta

### Síntomas

- WizSense/WizMind no detecta humanos/vehículos
- Falsas alarmas constantes
- Detecciones no aparecen en logs

### Diagnóstico

```bash
# Verificar que IVS está habilitado
curl -s -u admin:contraseña \
  "http://192.168.1.108/cgi-bin/ivs.cgi?action=getRule" \
  | grep -o "<Enable>[^<]*</Enable>"

# Verificar configuración de detección
curl -s -u admin:contraseña \
  "http://192.168.1.108/cgi-bin/configManager.cgi?action=getConfig&name=IVS"

# Verificar eventos
curl -s -u admin:contraseña \
  "http://192.168.1.108/cgi-bin/ivs.cgi?action=getEvent&type=Human&count=10"
```

### Causas posibles

1. **IVS deshabilitado**
   - Configuración incorrecta
   - Firmware no soporta

2. **Umbral muy alto**
   - Confidence > 95%
   - Objetos muy pequeños

3. **Escena incorrecta**
   - Mucha vegetación
   - Poca iluminación
   - Ángulo incorrecto

### Solución

```bash
# Habilitar IVS
curl -s -u admin:contraseña \
  -d "IVS.Rule[0].Enable=true" \
  "http://192.168.1.108/cgi-bin/configManager.cgi?action=setConfig"

# Reducir umbral de confianza
curl -s -u admin:contraseña \
  -d "IVS.Rule[0].Confidence=70" \
  "http://192.168.1.108/cgi-bin/configManager.cgi?action=setConfig"

# Configurar tamaño mínimo de objeto
curl -s -u admin:contraseña \
  -d "IVS.Rule[0].MinObjectSize=50" \
  "http://192.168.1.108/cgi-bin/configManager.cgi?action=setConfig"
```

---

## 💡 Uno-liners de diagnóstico

```bash
# Diagnóstico rápido completo
ping -c 1 192.168.1.108 >/dev/null && echo "✅ Ping OK" || echo "❌ Ping FAIL"
nmap -p 80,554,37777 192.168.1.108 | grep open
curl -s -u admin:admin "http://192.168.1.108/cgi-bin/magicBox.cgi?action=getSystemInfo" | grep -q "deviceName" && echo "✅ API OK" || echo "❌ API FAIL"
ffprobe rtsp://admin:admin@192.168.1.108:554/Streaming/Channels/101 2>&1 | grep -q "h264" && echo "✅ RTSP OK" || echo "❌ RTSP FAIL"

# Verificar todas las cámaras en un rango
for i in $(seq 10 30); do ping -c 1 -W 1 192.168.100.$i >/dev/null && echo "✅ 192.168.100.$i" || echo "❌ 192.168.100.$i"; done

# Extraer información de todas las cámaras
for i in $(seq 10 30); do curl -s -m 2 -u admin:admin "http://192.168.100.$i/cgi-bin/magicBox.cgi?action=getSystemInfo" 2>/dev/null | grep -q "deviceName" && echo "192.168.100.$i: $(curl -s -u admin:admin "http://192.168.100.$i/cgi-bin/magicBox.cgi?action=getSystemInfo" | sed -n 's/.*<deviceName>\([^<]*\).*/\1/p')"; done
```

---

## 🔗 Ver también

- [`dahua-discovery.md`](dahua-discovery.md) — descubrir cámaras
- [`dahua-camera-api.md`](dahua-camera-api.md) — API completa
- [`dahua-rtsp-stream.md`](dahua-rtsp-stream.md) — diagnóstico RTSP
- [`../../scenarios/dahua/`](../../scenarios/dahua/) — escenarios prácticos
- [`../../labs/docker-compose.dahua.yml`](../../labs/docker-compose.dahua.yml) — laboratorio Dahua: `cd labs && docker compose -f docker-compose.dahua.yml up -d`
