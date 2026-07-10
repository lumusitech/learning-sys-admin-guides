# 🔄 Dahua — Scripting y configuración masiva

**Nivel:** 🔴 Avanzado
**Herramientas:** `bash`, `curl`, `nmap`, `awk`

---

## ⚡ Quick command

```bash
for ip in $(nmap -sP 192.168.100.0/24 | grep "Nmap scan" | awk '{print $5}'); do curl -s -u admin:admin "http://$ip/cgi-bin/magicBox.cgi?action=getSystemInfo"; done
```

---

## 🧠 ¿Por qué scripting masivo?

En instalaciones grandes (50+ cámaras), configurar una por una es inviable. Necesitas:

- Cambiar contraseñas en lote
- Configurar NTP en todas las cámaras
- Asignar IPs estáticas
- Agregar cámaras a NVR automáticamente
- Hacer backup de configuraciones

---

## 📋 Script 1: Descubrir cámaras en rango de IPs

```bash
#!/bin/bash
# discover_dahua.sh - Descubre cámaras Dahua en un rango de IPs

RANGO="192.168.100"
USUARIO="admin"
PASSWORD="admin"

echo "🔍 Buscando cámaras Dahua en $RANGO.0/24..."
echo ""

for i in $(seq 1 254); do
  IP="$RANGO.$i"
  
  # Intentar obtener información del sistema
  RESPONSE=$(curl -s -m 2 -u "$USUARIO:$PASSWORD" \
    "http://$IP/cgi-bin/magicBox.cgi?action=getSystemInfo" 2>/dev/null)
  
  if echo "$RESPONSE" | grep -q "deviceName"; then
    DEVICE=$(echo "$RESPONSE" | sed -n 's/.*<deviceName>\([^<]*\).*/\1/p')
    SERIAL=$(echo "$RESPONSE" | sed -n 's/.*<serialNumber>\([^<]*\).*/\1/p')
    VERSION=$(echo "$RESPONSE" | sed -n 's/.*<softwareVersion>\([^<]*\).*/\1/p')
    
    echo "✅ $IP - $DEVICE (SN: $SERIAL, FW: $VERSION)"
  fi
done
```

**Uso:**

```bash
chmod +x discover_dahua.sh
./discover_dahua.sh
```

---

## 📋 Script 2: Cambiar contraseña masivamente

```bash
#!/bin/bash
# change_password.sh - Cambia contraseña en múltiples cámaras

USUARIO="admin"
PASS_ANTIGUA="admin"
PASS_NUEVA="NuevaPassword123"
CAMARAS="192.168.100.10 192.168.100.11 192.168.100.12"

echo "🔐 Cambiando contraseña en ${#CAMARAS[@]} cámaras..."
echo ""

for IP in $CAMARAS; do
  echo -n "Cambiando en $IP... "
  
  RESPONSE=$(curl -s -m 5 -u "$USUARIO:$PASS_ANTIGUA" \
    -d "user.Name=$USUARIO&user.Password=$PASS_NUEVA" \
    "http://$IP/cgi-bin/user.cgi?action=modify" 2>/dev/null)
  
  if echo "$RESPONSE" | grep -q "OK\|success"; then
    echo "✅ OK"
  else
    echo "❌ FALLÓ"
  fi
done
```

**Uso:**

```bash
chmod +x change_password.sh
./change_password.sh
```

---

## 📋 Script 3: Configurar NTP en múltiples cámaras

```bash
#!/bin/bash
# set_ntp.sh - Configura NTP en múltiples cámaras

USUARIO="admin"
PASSWORD="NuevaPassword123"
NTP_SERVER="192.168.100.1"
TIMEZONE="ART"
CAMARAS=$(seq 10 30)  # 192.168.100.10 a 192.168.100.30

echo "⏰ Configurando NTP en cámaras..."
echo ""

for i in $CAMARAS; do
  IP="192.168.100.$i"
  echo -n "Configurando $IP... "
  
  RESPONSE=$(curl -s -m 5 -u "$USUARIO:$PASSWORD" \
    -d "NTPServer=$NTP_SERVER&port=123&timeZone=$TIMEZONE" \
    "http://$IP/cgi-bin/configManager.cgi?action=setConfig&NTPServer=$NTP_SERVER" 2>/dev/null)
  
  if echo "$RESPONSE" | grep -q "OK\|success"; then
    echo "✅ OK"
  else
    echo "❌ FALLÓ"
  fi
done
```

**Uso:**

```bash
chmod +x set_ntp.sh
./set_ntp.sh
```

---

## 📋 Script 4: Asignar IPs estáticas en lote

```bash
#!/bin/bash
# set_static_ip.sh - Asigna IPs estáticas a cámaras

USUARIO="admin"
PASSWORD="NuevaPassword123"

# Array de IPs actuales y nuevas
declare -A IP_MAP
IP_MAP["192.168.1.108"]="192.168.100.10"
IP_MAP["192.168.1.109"]="192.168.100.11"
IP_MAP["192.168.1.110"]="192.168.100.12"

echo "🌐 Asignando IPs estáticas..."
echo ""

for IP_ACTUAL in "${!IP_MAP[@]}"; do
  IP_NUEVA="${IP_MAP[$IP_ACTUAL]}"
  echo -n "Cambiando $IP_ACTUAL → $IP_NUEVA... "
  
  RESPONSE=$(curl -s -m 5 -u "$USUARIO:$PASSWORD" \
    -d "ip=$IP_NUEVA&mask=255.255.255.0&gateway=192.168.100.1" \
    "http://$IP_ACTUAL/cgi-bin/network.cgi?action=setIP" 2>/dev/null)
  
  if echo "$RESPONSE" | grep -q "OK\|success"; then
    echo "✅ OK (la cámara se reiniciará)"
  else
    echo "❌ FALLÓ"
  fi
done
```

**Uso:**

```bash
chmod +x set_static_ip.sh
./set_static_ip.sh
```

---

## 📋 Script 5: Agregar cámaras a NVR vía API

```bash
#!/bin/bash
# add_to_nvr.sh - Agrega cámaras a NVR automáticamente

NVR_IP="192.168.100.100"
NVR_USER="admin"
NVR_PASS="NVRPassword123"
CAM_USER="admin"
CAM_PASS="NuevaPassword123"
CAMARAS=$(seq 10 30)  # 192.168.100.10 a 192.168.100.30

echo "📹 Agregando cámaras a NVR $NVR_IP..."
echo ""

CHANNEL=1

for i in $CAMARAS; do
  IP="192.168.100.$i"
  echo -n "Agregando $IP en canal $CHANNEL... "
  
  RESPONSE=$(curl -s -m 5 -u "$NVR_USER:$NVR_PASS" \
    -d "method=add&ip=$IP&port=37777&user=$CAM_USER&pass=$CAM_PASS&channel=$CHANNEL" \
    "http://$NVR_IP/cgi-bin/record.cgi?action=addDevice" 2>/dev/null)
  
  if echo "$RESPONSE" | grep -q "OK\|success"; then
    echo "✅ OK"
  else
    echo "❌ FALLÓ"
  fi
  
  CHANNEL=$((CHANNEL + 1))
done
```

**Uso:**

```bash
chmod +x add_to_nvr.sh
./add_to_nvr.sh
```

---

## 📋 Script 6: Backup de configuración

```bash
#!/bin/bash
# backup_config.sh - Backup de configuración de cámaras

USUARIO="admin"
PASSWORD="NuevaPassword123"
BACKUP_DIR="/tmp/dahua_backup_$(date +%Y%m%d)"
CAMARAS=$(seq 10 30)

mkdir -p "$BACKUP_DIR"

echo "💾 Haciendo backup de configuraciones..."
echo ""

for i in $CAMARAS; do
  IP="192.168.100.$i"
  BACKUP_FILE="$BACKUP_DIR/camera_$IP.xml"
  
  echo -n "Backup de $IP... "
  
  curl -s -m 10 -u "$USUARIO:$PASSWORD" \
    "http://$IP/cgi-bin/configManager.cgi?action=getConfig" \
    -o "$BACKUP_FILE" 2>/dev/null
  
  if [ -s "$BACKUP_FILE" ]; then
    echo "✅ OK ($(wc -c < "$BACKUP_FILE") bytes)"
  else
    echo "❌ FALLÓ"
    rm -f "$BACKUP_FILE"
  fi
done

echo ""
echo "Backup guardado en: $BACKUP_DIR"
```

**Uso:**

```bash
chmod +x backup_config.sh
./backup_config.sh
```

---

## 📋 Script 7: Restaurar configuración

```bash
#!/bin/bash
# restore_config.sh - Restaura configuración desde backup

USUARIO="admin"
PASSWORD="NuevaPassword123"
BACKUP_DIR="/tmp/dahua_backup_20240115"

echo "♻️ Restaurando configuraciones..."
echo ""

for BACKUP_FILE in "$BACKUP_DIR"/camera_*.xml; do
  IP=$(basename "$BACKUP_FILE" | sed 's/camera_\(.*\)\.xml/\1/')
  
  echo -n "Restaurando $IP... "
  
  RESPONSE=$(curl -s -m 10 -u "$USUARIO:$PASSWORD" \
    -d "@$BACKUP_FILE" \
    "http://$IP/cgi-bin/configManager.cgi?action=setConfig" 2>/dev/null)
  
  if echo "$RESPONSE" | grep -q "OK\|success"; then
    echo "✅ OK (la cámara se reiniciará)"
  else
    echo "❌ FALLÓ"
  fi
done
```

**Uso:**

```bash
chmod +x restore_config.sh
./restore_config.sh
```

---

## ⚠️ Manejo de errores y logging

Para scripts en producción, agrega logging:

```bash
#!/bin/bash
LOG_FILE="/tmp/dahua_script_$(date +%Y%m%d_%H%M%S).log"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "Iniciando script..."

# Tu código aquí...

log "Script finalizado. Log: $LOG_FILE"
```

---

## 💡 Uno-liners

```bash
# Descubrir todas las cámaras y guardar en archivo
for i in $(seq 1 254); do curl -s -m 2 -u admin:admin "http://192.168.100.$i/cgi-bin/magicBox.cgi?action=getSystemInfo" 2>/dev/null | grep -q "deviceName" && echo "192.168.100.$i"; done > cameras.txt

# Cambiar contraseña en todas las cámaras descubiertas
for ip in $(cat cameras.txt); do curl -s -u admin:admin -d "user.Name=admin&user.Password=NuevaPass" "http://$ip/cgi-bin/user.cgi?action=modify"; done

# Configurar NTP en todas las cámaras
for ip in $(cat cameras.txt); do curl -s -u admin:NuevaPass -d "NTPServer=192.168.100.1&port=123&timeZone=ART" "http://$ip/cgi-bin/configManager.cgi?action=setConfig&NTPServer=192.168.100.1"; done

# Capturar snapshot de todas las cámaras
for ip in $(cat cameras.txt); do curl -s -u admin:NuevaPass "http://$ip/cgi-bin/snapshot.cgi" -o "snapshot_$ip.jpg"; done
```

---

## 🔗 Ver también

- [`dahua-discovery.md`](dahua-discovery.md) — descubrir cámaras
- [`dahua-camera-api.md`](dahua-camera-api.md) — API completa
- [`../../scenarios/dahua/03-migracion-masiva.md`](../../scenarios/dahua/03-migracion-masiva.md) — escenario práctico
