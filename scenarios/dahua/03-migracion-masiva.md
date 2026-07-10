# 🧩 Escenario: Migración masiva de contraseñas Dahua

**Dominio:** infrastructure
**Nivel:** 🔴 Avanzado
**Herramientas:** `bash`, `curl`, `nmap`, `awk`
**Archivos:** N/A (scripting en vivo)

---

## 🎯 Problema

Tienes 50 cámaras Dahua con la contraseña por defecto `admin` y necesitas cambiarlas todas a una contraseña segura. Hacerlo una por una desde la interfaz web tomaría horas.

---

## ⚡ Quick command (SRE)

```bash
for ip in $(seq 10 60); do curl -s -m 2 -u admin:admin "http://192.168.100.$ip/cgi-bin/magicBox.cgi?action=getSystemInfo" 2>/dev/null | grep -q "deviceName" && echo "192.168.100.$ip"; done
```

---

## ✅ Salida esperada

```text
192.168.100.10
192.168.100.11
192.168.100.12
...
192.168.100.60
```

**Interpretación:**

- Lista de IPs con cámaras Dahua detectadas
- Cada IP responde a la API con credenciales `admin:admin`
- Listas para cambio masivo de contraseña

---

## 🧠 Diagnóstico

### Paso 1: Descubrir cámaras

```bash
# Descubrir cámaras en el rango
for ip in $(seq 10 60); do
  curl -s -m 2 -u admin:admin \
    "http://192.168.100.$ip/cgi-bin/magicBox.cgi?action=getSystemInfo" \
    2>/dev/null | grep -q "deviceName" && echo "192.168.100.$ip"
done > /tmp/camaras.txt

# Contar cámaras descubiertas
wc -l /tmp/camaras.txt
```

**Patrones clave:**

- Todas las cámaras responden → lista completa
- Algunas no responden → verificar conectividad individual
- Ninguna responde → credenciales incorrectas o rango equivocado

### Paso 2: Verificar conectividad

```bash
# Verificar que todas las cámaras responden a ping
while read ip; do
  ping -c 1 -W 1 "$ip" >/dev/null && echo "✅ $ip" || echo "❌ $ip"
done < /tmp/camaras.txt
```

**Patrones clave:**

- Todas responden → red OK
- Algunas no responden → problema de red o cámara apagada

### Paso 3: Backup de configuración

```bash
# Crear directorio de backup
mkdir -p /tmp/backup_$(date +%Y%m%d)

# Backup de cada cámara
while read ip; do
  curl -s -u admin:admin \
    "http://$ip/cgi-bin/configManager.cgi?action=getConfig" \
    -o "/tmp/backup_$(date +%Y%m%d)/${ip}.xml"
done < /tmp/camaras.txt
```

---

## 🛠️ Procedimiento (runbook)

### 1. Descubrir cámaras

```bash
#!/bin/bash
# discover.sh

echo "🔍 Descubriendo cámaras Dahua..."

for ip in $(seq 10 60); do
  IP="192.168.100.$ip"
  RESPONSE=$(curl -s -m 2 -u admin:admin \
    "http://$IP/cgi-bin/magicBox.cgi?action=getSystemInfo" 2>/dev/null)
  
  if echo "$RESPONSE" | grep -q "deviceName"; then
    DEVICE=$(echo "$RESPONSE" | sed -n 's/.*<deviceName>\([^<]*\).*/\1/p')
    echo "✅ $IP - $DEVICE"
    echo "$IP" >> /tmp/camaras.txt
  else
    echo "❌ $IP - No responde"
  fi
done

echo ""
echo "Total cámaras descubiertas: $(wc -l < /tmp/camaras.txt)"
```

### 2. Backup de configuraciones

```bash
#!/bin/bash
# backup.sh

BACKUP_DIR="/tmp/backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "💾 Haciendo backup de configuraciones..."

while read ip; do
  echo -n "Backup de $ip... "
  curl -s -u admin:admin \
    "http://$ip/cgi-bin/configManager.cgi?action=getConfig" \
    -o "$BACKUP_DIR/${ip}.xml" 2>/dev/null
  
  if [ -s "$BACKUP_DIR/${ip}.xml" ]; then
    echo "✅ OK ($(wc -c < "$BACKUP_DIR/${ip}.xml") bytes)"
  else
    echo "❌ FALLÓ"
    rm -f "$BACKUP_DIR/${ip}.xml"
  fi
done < /tmp/camaras.txt

echo ""
echo "Backup guardado en: $BACKUP_DIR"
```

### 3. Cambiar contraseñas

```bash
#!/bin/bash
# change_password.sh

PASS_NUEVA="NuevaPassword123!"
LOG_FILE="/tmp/change_password_$(date +%Y%m%d_%H%M%S).log"

echo "🔐 Cambiando contraseñas..." | tee "$LOG_FILE"
echo "Fecha: $(date)" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

EXITOS=0
FALLOS=0

while read ip; do
  echo -n "Cambiando en $ip... " | tee -a "$LOG_FILE"
  
  RESPONSE=$(curl -s -m 5 -u admin:admin \
    -d "user.Name=admin&user.Password=$PASS_NUEVA" \
    "http://$ip/cgi-bin/user.cgi?action=modify" 2>/dev/null)
  
  if echo "$RESPONSE" | grep -q "OK\|success"; then
    echo "✅ OK" | tee -a "$LOG_FILE"
    EXITOS=$((EXITOS + 1))
  else
    echo "❌ FALLÓ" | tee -a "$LOG_FILE"
    FALLOS=$((FALLOS + 1))
  fi
done < /tmp/camaras.txt

echo "" | tee -a "$LOG_FILE"
echo "Resumen: $EXITOS exitos, $FALLOS fallos" | tee -a "$LOG_FILE"
echo "Log: $LOG_FILE"
```

### 4. Verificar cambio de contraseñas

```bash
#!/bin/bash
# verify.sh

PASS_NUEVA="NuevaPassword123!"

echo "🔍 Verificando nuevas contraseñas..."

EXITOS=0
FALLOS=0

while read ip; do
  RESPONSE=$(curl -s -m 5 -u admin:$PASS_NUEVA \
    "http://$ip/cgi-bin/magicBox.cgi?action=getSystemInfo" 2>/dev/null)
  
  if echo "$RESPONSE" | grep -q "deviceName"; then
    echo "✅ $ip - Contraseña OK"
    EXITOS=$((EXITOS + 1))
  else
    echo "❌ $ip - Contraseña FAIL"
    FALLOS=$((FALLOS + 1))
  fi
done < /tmp/camaras.txt

echo ""
echo "Resumen: $EXITOS exitos, $FALLOS fallos"
```

### 5. Actualizar NVR con nuevas credenciales

```bash
#!/bin/bash
# update_nvr.sh

NVR_IP="192.168.100.100"
NVR_USER="admin"
NVR_PASS="NVRPassword123"
CAM_USER="admin"
CAM_PASS="NuevaPassword123!"

echo "🔄 Actualizando credenciales en NVR..."

CHANNEL=1

while read ip; do
  echo -n "Actualizando $ip en canal $CHANNEL... "
  
  # Eliminar cámara del NVR
  curl -s -u "$NVR_USER:$NVR_PASS" \
    -d "method=delete&channel=$CHANNEL" \
    "http://$NVR_IP/cgi-bin/record.cgi?action=deleteDevice" >/dev/null
  
  # Re-agregar con nuevas credenciales
  RESPONSE=$(curl -s -m 5 -u "$NVR_USER:$NVR_PASS" \
    -d "method=add&ip=$ip&port=37777&user=$CAM_USER&pass=$CAM_PASS&channel=$CHANNEL" \
    "http://$NVR_IP/cgi-bin/record.cgi?action=addDevice" 2>/dev/null)
  
  if echo "$RESPONSE" | grep -q "OK\|success"; then
    echo "✅ OK"
  else
    echo "❌ FALLÓ"
  fi
  
  CHANNEL=$((CHANNEL + 1))
done < /tmp/camaras.txt
```

---

## 🧯 Mitigación

**Verificar:**

```bash
# Verificar que todas las cámaras responden con nueva contraseña
while read ip; do
  curl -s -m 2 -u admin:NuevaPassword123! \
    "http://$ip/cgi-bin/magicBox.cgi?action=getSystemInfo" \
    2>/dev/null | grep -q "deviceName" && echo "✅ $ip" || echo "❌ $ip"
done < /tmp/camaras.txt
```

**Acción (rollback):**

```bash
# Si algo falla, restaurar desde backup
while read ip; do
  BACKUP_FILE="/tmp/backup_20240115_100000/${ip}.xml"
  if [ -f "$BACKUP_FILE" ]; then
    echo "Restaurando $ip..."
    curl -s -u admin:NuevaPassword123! \
      -d "@$BACKUP_FILE" \
      "http://$ip/cgi-bin/configManager.cgi?action=setConfig"
  fi
done < /tmp/camaras.txt
```

**Rollback (factory reset):**

```bash
# Si todo falla, factory reset de cámaras problemáticas
for ip in 192.168.100.10 192.168.100.15; do
  echo "Reset de $ip..."
  # Reset físico: mantener botón 10 segundos
  # O vía API si aún responde:
  curl -s -u admin:NuevaPassword123! \
    "http://$ip/cgi-bin/magicBox.cgi?action=reset"
done
```

**Casos comunes:**

- Algunas cámaras no responden → verificar conectividad individual
- Cambio de contraseña falla → cámara puede tener política de complejidad
- NVR no se reconecta → actualizar credenciales en NVR
- Backup corrupto → usar factory reset y reconfigurar manualmente

---

## ✅ Interpretación

- **Todas las cámaras responden** → migración exitosa
- **Algunas fallan** → verificar conectividad y política de contraseñas
- **NVR no se reconecta** → actualizar credenciales en NVR
- **Backup necesario** → siempre hacer backup antes de cambios masivos

---

## 📝 Notas importantes

1. **Siempre hacer backup** antes de cambios masivos
2. **Probar con 1-2 cámaras** antes de ejecutar en todas
3. **Mantener log** de todas las operaciones
4. **Verificar después** de cada cambio
5. **Tener plan de rollback** documentado

---

## 🧪 Cómo practicarlo en el lab

El [laboratorio Docker Dahua](../../labs/docker-compose.dahua.yml) incluye cámaras simuladas y NVR para practicar migración masiva:

```bash
# 1. Iniciar laboratorio
cd labs && docker compose -f docker-compose.dahua.yml up -d

# 2. Entrar al cliente de diagnóstico
docker exec -it dahua-client sh

# 3. Verificar que las cámaras responden
ping -c 3 10.0.100.108
curl -s -u admin:admin "http://10.0.100.108/cgi-bin/magicBox.cgi?action=getSystemInfo"

# 4. Practicar los scripts del escenario adaptándolos a estas IPs
# (reemplazar 192.168.100.x por 10.0.100.x en los scripts)
```

**Ejercicio:** Ejecutá el script de backup y cambio de contraseña sobre las cámaras simuladas del lab.

Ver [laboratorio completo →](../../labs/docker-compose.dahua.yml)

---

## 🔗 Referencias

- [`guides/dahua/dahua-mass-config.md`](../../guides/dahua/dahua-mass-config.md) — scripting masivo
- [`guides/dahua/dahua-camera-api.md`](../../guides/dahua/dahua-camera-api.md) — API HTTP/CGI
- [`guides/dahua/dahua-discovery.md`](../../guides/dahua/dahua-discovery.md) — descubrir cámaras
- [`reference/dahua-cheatsheet.md`](../../reference/dahua-cheatsheet.md) — referencia rápida
