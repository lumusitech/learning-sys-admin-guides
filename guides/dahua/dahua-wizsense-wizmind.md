# 🧠 Dahua — WizSense vs WizMind: Capacidades IA

**Nivel:** 🔴 Avanzado
**Herramientas:** `curl`, `jq`, `xmllint`

---

## ⚡ Quick command

```bash
curl -s -u admin:contraseña "http://192.168.1.108/cgi-bin/ivs.cgi?action=getRule" | xmllint --format -
```

---

## 📊 Diferencias entre series

| Característica | Lite | WizSense | WizMind |
|----------------|------|----------|---------|
| **Detección de movimiento** | ✅ | ✅ | ✅ |
| **Detección de humanos** | ❌ | ✅ | ✅ |
| **Detección de vehículos** | ❌ | ✅ | ✅ |
| **Reconocimiento facial** | ❌ | ❌ | ✅ |
| **LPR/ANPR (patentes)** | ❌ | ❌ | ✅ |
| **Conteo de personas** | ❌ | ✅ | ✅ |
| **Protección perimetral** | ❌ | ✅ | ✅ |
| **Mapa de calor** | ❌ | ❌ | ✅ |
| **Análisis de comportamiento** | ❌ | ❌ | ✅ |

---

## 🎯 WizSense: Detección de humanos y vehículos

### ¿Qué es WizSense?

WizSense es la línea de cámaras Dahua con **IA básica** que permite:

- Distinguir humanos de otros objetos (animales, vehículos, vegetación)
- Distinguir vehículos de otros objetos
- Reducir falsas alarmas
- Detección perimetral inteligente

### APIs de WizSense

```bash
# Obtener reglas de detección IVS
curl -s -u admin:contraseña \
  "http://192.168.1.108/cgi-bin/ivs.cgi?action=getRule" \
  | xmllint --format -

# Obtener eventos de detección
curl -s -u admin:contraseña \
  "http://192.168.1.108/cgi-bin/ivs.cgi?action=getEvent&type=Human&count=10"

# Obtener eventos de vehículos
curl -s -u admin:contraseña \
  "http://192.168.1.108/cgi-bin/ivs.cgi?action=getEvent&type=Vehicle&count=10"
```

### Configurar detección de humanos

```bash
curl -s -u admin:contraseña \
  -d "IVS.Rule[0].Type=Tripwire&IVS.Rule[0].Enable=true&IVS.Rule[0].DetectHuman=true" \
  "http://192.168.1.108/cgi-bin/configManager.cgi?action=setConfig"
```

### Configurar detección de vehículos

```bash
curl -s -u admin:contraseña \
  -d "IVS.Rule[0].Type=Tripwire&IVS.Rule[0].Enable=true&IVS.Rule[0].DetectVehicle=true" \
  "http://192.168.1.108/cgi-bin/configManager.cgi?action=setConfig"
```

---

## 🧠 WizMind: IA avanzada

### ¿Qué es WizMind?

WizMind es la línea premium de cámaras Dahua con **IA avanzada** que incluye todo lo de WizSense más:

- **Reconocimiento facial**: identificar personas específicas
- **LPR/ANPR**: lectura de patentes vehiculares
- **Conteo de personas**: estadísticas de flujo
- **Mapa de calor**: zonas de mayor actividad
- **Análisis de comportamiento**: merodeo, objetos abandonados, etc.

### APIs de WizMind

```bash
# Reconocimiento facial - obtener última detección
curl -s -u admin:contraseña \
  "http://192.168.1.108/cgi-bin/faceRecognition.cgi?action=getLastPlate"

# LPR/ANPR - obtener última patente detectada
curl -s -u admin:contraseña \
  "http://192.168.1.108/cgi-bin/faceRecognition.cgi?action=getLastPlate"

# Conteo de personas
curl -s -u admin:contraseña \
  "http://192.168.1.108/cgi-bin/ivs.cgi?action=getPeopleCounting"

# Mapa de calor
curl -s -u admin:contraseña \
  "http://192.168.1.108/cgi-bin/ivs.cgi?action=getHeatMap"
```

### Configurar reconocimiento facial

```bash
# Habilitar reconocimiento facial
curl -s -u admin:contraseña \
  -d "FaceRecognition.Enable=true&FaceRecognition.Confidence=80" \
  "http://192.168.1.108/cgi-bin/configManager.cgi?action=setConfig"

# Agregar persona a base de datos
curl -s -u admin:contraseña \
  -F "name=Juan Perez" \
  -F "photo=@/path/to/photo.jpg" \
  "http://192.168.1.108/cgi-bin/faceRecognition.cgi?action=addFace"
```

### Configurar LPR/ANPR

```bash
# Habilitar LPR
curl -s -u admin:contraseña \
  -d "LPR.Enable=true&LPR.Confidence=85" \
  "http://192.168.1.108/cgi-bin/configManager.cgi?action=setConfig"

# Obtener últimas patentes detectadas
curl -s -u admin:contraseña \
  "http://192.168.1.108/cgi-bin/faceRecognition.cgi?action=getLastPlate&count=20"
```

---

## 📋 Ejemplos prácticos

### Ejemplo 1: Extraer todas las detecciones de humanos del día

```bash
#!/bin/bash
CAMARA="192.168.1.108"
USUARIO="admin"
PASSWORD="contraseña"

# Obtener eventos de humanos
curl -s -u "$USUARIO:$PASSWORD" \
  "http://$CAMARA/cgi-bin/ivs.cgi?action=getEvent&type=Human&count=100" \
  | xmllint --format - \
  | grep -E "<Time>|<Confidence>" \
  | paste - - \
  | awk '{print $2, $4}'
```

### Ejemplo 2: Contar detecciones por hora

```bash
#!/bin/bash
CAMARA="192.168.1.108"
USUARIO="admin"
PASSWORD="contraseña"

curl -s -u "$USUARIO:$PASSWORD" \
  "http://$CAMARA/cgi-bin/ivs.cgi?action=getEvent&type=Human&count=1000" \
  | grep "<Time>" \
  | sed 's/.*<Time>\([^<]*\).*/\1/' \
  | cut -d'T' -f2 | cut -d':' -f1 \
  | sort | uniq -c | sort -rn
```

### Ejemplo 3: Extraer patentes detectadas

```bash
#!/bin/bash
CAMARA="192.168.1.108"
USUARIO="admin"
PASSWORD="contraseña"

curl -s -u "$USUARIO:$PASSWORD" \
  "http://$CAMARA/cgi-bin/faceRecognition.cgi?action=getLastPlate&count=50" \
  | xmllint --format - \
  | grep -E "<PlateNumber>|<Time>|<Confidence>" \
  | paste - - - \
  | awk '{print "Patente:", $2, "| Hora:", $4, "| Confianza:", $6}'
```

### Ejemplo 4: Monitorear detecciones en tiempo real

```bash
#!/bin/bash
CAMARA="192.168.1.108"
USUARIO="admin"
PASSWORD="contraseña"

echo "🔍 Monitoreando detecciones en $CAMARA..."
echo ""

while true; do
  EVENTS=$(curl -s -u "$USUARIO:$PASSWORD" \
    "http://$CAMARA/cgi-bin/ivs.cgi?action=getEvent&type=Human&count=1")
  
  if echo "$EVENTS" | grep -q "<Event>"; then
    TIME=$(echo "$EVENTS" | sed -n 's/.*<Time>\([^<]*\).*/\1/p')
    CONF=$(echo "$EVENTS" | sed -n 's/.*<Confidence>\([^<]*\).*/\1/p')
    echo "$(date '+%H:%M:%S') - Humano detectado (confianza: $CONF%)"
  fi
  
  sleep 5
done
```

---

## 🔍 Diagnóstico de IA

### Problema 1: IA no detecta

```bash
# Verificar que IVS está habilitado
curl -s -u admin:contraseña \
  "http://192.168.1.108/cgi-bin/ivs.cgi?action=getRule" \
  | grep -o "<Enable>[^<]*</Enable>"

# Debe devolver <Enable>true</Enable>

# Verificar configuración de detección
curl -s -u admin:contraseña \
  "http://192.168.1.108/cgi-bin/configManager.cgi?action=getConfig&name=IVS" \
  | xmllint --format -
```

### Problema 2: Muchas falsas alarmas

```bash
# Aumentar umbral de confianza
curl -s -u admin:contraseña \
  -d "IVS.Rule[0].Confidence=90" \
  "http://192.168.1.108/cgi-bin/configManager.cgi?action=setConfig"

# Filtrar por tamaño mínimo
curl -s -u admin:contraseña \
  -d "IVS.Rule[0].MinObjectSize=100" \
  "http://192.168.1.108/cgi-bin/configManager.cgi?action=setConfig"
```

### Problema 3: Reconocimiento facial no funciona

```bash
# Verificar que FaceRecognition está habilitado
curl -s -u admin:contraseña \
  "http://192.168.1.108/cgi-bin/configManager.cgi?action=getConfig&name=FaceRecognition" \
  | grep -o "<Enable>[^<]*</Enable>"

# Verificar base de datos de caras
curl -s -u admin:contraseña \
  "http://192.168.1.108/cgi-bin/faceRecognition.cgi?action=getFaceList"
```

---

## 💡 Uno-liners

```bash
# Ver todas las reglas IVS configuradas
curl -su admin:pass http://192.168.1.108/cgi-bin/ivs.cgi?action=getRule | xmllint --format -

# Contar detecciones de humanos en la última hora
curl -su admin:pass "http://192.168.1.108/cgi-bin/ivs.cgi?action=getEvent&type=Human&count=1000" | grep "<Time>" | grep "$(date -d '1 hour ago' '+%Y-%m-%dT%H')" | wc -l

# Extraer última patente detectada
curl -su admin:pass "http://192.168.1.108/cgi-bin/faceRecognition.cgi?action=getLastPlate" | sed -n 's/.*<PlateNumber>\([^<]*\).*/\1/p'

# Ver configuración de reconocimiento facial
curl -su admin:pass "http://192.168.1.108/cgi-bin/configManager.cgi?action=getConfig&name=FaceRecognition" | xmllint --format -

# Habilitar detección de humanos y vehículos
curl -su admin:pass -d "IVS.Rule[0].DetectHuman=true&IVS.Rule[0].DetectVehicle=true" "http://192.168.1.108/cgi-bin/configManager.cgi?action=setConfig"
```

---

## 🔗 Ver también

- [`dahua-camera-api.md`](dahua-camera-api.md) — API completa
- [`dahua-troubleshooting.md`](dahua-troubleshooting.md) — diagnóstico de fallas
- Documentación oficial Dahua WizSense: https://www.dahuasecurity.com/products/wizsense
- Documentación oficial Dahua WizMind: https://www.dahuasecurity.com/products/wizmind
