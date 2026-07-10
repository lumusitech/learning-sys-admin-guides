# PoE Injectors — Guía completa

**Nivel:** 🟢 Básico
**Archivos de práctica:** Sistema en vivo
**Ver escenarios relacionados:** N/A

---

## ⚡ Quick command

```bash
# Verificar voltaje con multímetro
# Conectar puntas en los pines 1,2 (+) y 3,6 (-) del conector PoE
# Voltaje esperado: 48V DC (±5%)
```

---

## 📑 Índice

1. [¿Qué son PoE Injectors?](#qué-son-poe-injectors)
2. [Modelo mental](#modelo-mental)
3. [Tipos de Injectors](#tipos-de-injectors)
4. [Diagnóstico con multímetro](#diagnóstico-con-multímetro)
5. [Problemas comunes](#problemas-comunes)
6. [Splitters PoE](#splitters-poe)
7. [Cuándo usar Injector vs Switch PoE](#cuándo-usar-injector-vs-switch-poe)
8. [Cálculo de presupuesto de potencia](#cálculo-de-presupuesto-de-potencia)
9. [Troubleshooting](#troubleshooting)
10. [Uno-liners imprescindibles](#uno-liners-imprescindibles)
11. [Referencias internas](#referencias-internas)

---

## 🧠 ¿Qué son PoE Injectors?

Los **PoE Injectors** son dispositivos que:

- **Inyectan energía PoE**: agregan energía a un cable Ethernet
- **Convierten enchufe estándar a PoE**: permiten alimentar dispositivos PoE desde enchufes normales
- **Son standalone**: no requieren switch PoE
- **Son económicos**: $15-50 USD vs $200-800 de un switch PoE

### Ventajas vs Switch PoE

| Ventaja | Descripción |
|---------|-------------|
| **Precio** | $15-50 vs $200-800 |
| **Simplicidad** | Un dispositivo por cámara/AP |
| **Flexibilidad** | Agregar PoE donde no hay switch PoE |
| **Portabilidad** | Fácil de mover/reemplazar |

### Desventajas vs Switch PoE

| Desventaja | Descripción |
|------------|-------------|
| **Sin gestión** | No hay monitoreo ni control remoto |
| **Ocupa espacio** | Un injector por dispositivo |
| **Sin reset remoto** | Hay que desconectar físicamente |
| **Cable adicional** | Necesita enchufe cerca del switch |

---

## 🧠 Modelo mental

Un PoE Injector es un **combinador de datos y energía**.

Piensa en el injector como:

- **Entrada 1**: Cable Ethernet desde el switch (solo datos)
- **Entrada 2**: Enchufe eléctrico (solo energía)
- **Salida**: Cable Ethernet con datos + energía (PoE)

El injector combina ambas señales en un solo cable Ethernet.

---

## 🔌 Tipos de Injectors

### Injectors Passive (no estándar)

```text
Voltaje fijo: 24V o 48V
Sin negociación: Siempre entrega el voltaje configurado
Riesgo: Puede dañar dispositivos si el voltaje es incorrecto
Uso: Equipos legacy, dispositivos específicos
```

### Injectors Active (estándar IEEE)

```text
802.3af: 48V, 15.4W máximo
802.3at: 48V, 30W máximo
802.3bt: 48V, 60W/100W máximo
Negociación: Detecta dispositivo y entrega solo la energía necesaria
Seguridad: No entrega energía si no hay dispositivo compatible
```

### Tabla comparativa

| Tipo | Voltaje | Potencia | Negociación | Seguridad | Uso |
|------|---------|----------|-------------|-----------|-----|
| Passive 24V | 24V fijo | Variable | ❌ No | ⚠️ Baja | Equipos legacy |
| Passive 48V | 48V fijo | Variable | ❌ No | ⚠️ Baja | Equipos legacy |
| 802.3af | 44-57V | 15.4W | ✅ Sí | ✅ Alta | Cámaras básicas |
| 802.3at | 50-57V | 30W | ✅ Sí | ✅ Alta | Cámaras PTZ, APs |
| 802.3bt | 50-57V | 60W/100W | ✅ Sí | ✅ Alta | Laptops, TVs |

### Modelos comunes

#### TP-Link

- **TL-POE150S**: 802.3af, 15.4W, $20
- **TL-POE200**: 802.3at, 30W, $30

#### Ubiquiti

- **U-POE-af**: 802.3af, 15.4W, $25
- **U-POE-at**: 802.3at, 30W, $35
- **U-POE-++**: 802.3bt, 60W, $50

#### Netgear

- **GS110P**: 802.3af, 15.4W, $25
- **GS308P**: 802.3at, 30W, $35

#### Generic

- **POE-150S**: 802.3af, 15.4W, $15
- **POE-300**: 802.3at, 30W, $25

---

## 🔍 Diagnóstico con multímetro

### Verificar voltaje de salida

```bash
# Configuración del multímetro:
# - Modo: DC Voltage
# - Rango: 200V

# Conectar puntas:
# - Punta roja: Pin 1 o 2 (+) del conector PoE
# - Punta negra: Pin 3 o 6 (-) del conector PoE

# Voltajes esperados:
# - Passive 24V: 24V ±10% (21.6V - 26.4V)
# - Passive 48V: 48V ±10% (43.2V - 52.8V)
# - 802.3af/at/bt: 44-57V
```

### Pinout de PoE

```text
Conector RJ45 (visto de frente):

  1 2 3 4 5 6 7 8
  ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓
  ┌─────────────────┐
  │ 1 2 3 4 5 6 7 8 │
  └─────────────────┘

Modo A (802.3af/at/bt):
- Pares 1,2: Datos + Energía (+)
- Pares 3,6: Datos + Energía (-)
- Pares 4,5: No usados
- Pares 7,8: No usados

Modo B (802.3af/at/bt):
- Pares 1,2: Solo datos
- Pares 3,6: Solo datos
- Pares 4,5: Energía (+)
- Pares 7,8: Energía (-)

Passive 24V/48V:
- Pares 4,5: Energía (+)
- Pares 7,8: Energía (-)
```

### Verificar continuidad del cable

```bash
# Configuración del multímetro:
# - Modo: Continuidad (beep)
# - O resistencia (Ω)

# Probar cada par:
# - Pin 1 → Pin 1 (otro extremo)
# - Pin 2 → Pin 2 (otro extremo)
# - Pin 3 → Pin 3 (otro extremo)
# - Pin 6 → Pin 6 (otro extremo)

# Debe haber continuidad (beep o resistencia baja < 1Ω)
```

---

## ⚠️ Problemas comunes

### Problema 1: Cable largo (> 100m)

```text
Síntoma: Dispositivo no enciende o se reinicia
Causa: Caída de voltaje por resistencia del cable
Solución:
- Usar cable de mejor calidad (Cat6 en vez de Cat5e)
- Usar cable con conductor de cobre puro (no CCA)
- Reducir longitud del cable
- Usar injector con mayor voltaje de salida
```

### Problema 2: Cable de mala calidad

```text
Síntoma: Dispositivo funciona intermitentemente
Causa: Resistencia alta del cable (CCA en vez de cobre)
Solución:
- Reemplazar cable con cable de cobre puro
- Usar cable Cat5e o superior
- Verificar que el cable no esté dañado
```

### Problema 3: Injector defectuoso

```text
Síntoma: Dispositivo no enciende
Causa: Injector quemado o defectuoso
Solución:
- Verificar voltaje con multímetro
- Probar con otro injector
- Reemplazar injector
```

### Problema 4: Dispositivo incompatible

```text
Síntoma: Dispositivo no enciende
Causa: Voltaje incorrecto (24V en dispositivo de 48V o viceversa)
Solución:
- Verificar voltaje requerido por el dispositivo
- Usar injector con voltaje correcto
- Usar splitter PoE si es necesario
```

### Problema 5: Sobrecalentamiento

```text
Síntoma: Injector se apaga después de un tiempo
Causa: Sobrecalentamiento por mala ventilación
Solución:
- Asegurar ventilación adecuada
- No cubrir el injector
- Usar injector con mayor capacidad de potencia
```

---

## 🔀 Splitters PoE

### ¿Qué son?

Los **Splitters PoE** son dispositivos que:

- **Separan datos y energía**: convierten PoE en Ethernet + DC
- **Permiten usar dispositivos no-PoE**: conectan dispositivos que necesitan enchufe DC
- **Reducen voltaje**: convierten 48V PoE a 12V/24V DC

### Tipos de Splitters

| Tipo | Entrada | Salida | Uso |
|------|---------|--------|-----|
| 48V → 12V | PoE 802.3af/at | 12V DC + Ethernet | Cámaras consumer, routers |
| 48V → 24V | PoE 802.3af/at | 24V DC + Ethernet | Equipos legacy |
| 48V → 5V | PoE 802.3af/at | 5V USB + Ethernet | Raspberry Pi, dispositivos USB |

### Modelos comunes

- **TP-Link TL-POE10R**: 48V → 12V, $15
- **Ubiquiti U-POE-R**: 48V → 24V, $20
- **Generic 48V-12V**: 48V → 12V, $10

### Cuándo usar Splitter

```text
✅ Dispositivo no soporta PoE pero está cerca de un switch PoE
✅ Necesitas reducir voltaje (48V → 12V)
✅ Quieres alimentar dispositivo desde cable Ethernet

❌ Dispositivo soporta PoE nativamente
❌ Tienes enchufe eléctrico cerca del dispositivo
❌ Necesitas alta potencia (> 25W)
```

---

## 📊 Cuándo usar Injector vs Switch PoE

### Usar Injector cuando

```text
✅ Solo necesitas alimentar 1-2 dispositivos
✅ No tienes switch PoE y no quieres comprar uno
✅ Presupuesto limitado ($15-50 vs $200-800)
✅ Dispositivo está lejos del switch
✅ Necesitas solución temporal
```

### Usar Switch PoE cuando

```text
✅ Necesitas alimentar 4+ dispositivos
✅ Quieres gestión centralizada
✅ Necesitas reset remoto de puertos
✅ Quieres monitoreo de consumo
✅ Necesitas QoS y VLANs
✅ Presupuesto permite ($200-800)
```

---

## 🧮 Cálculo de presupuesto de potencia

### Fórmula básica

```text
Potencia total = Σ (Potencia de cada dispositivo)
Ejemplo:
- 4 cámaras IP (802.3af, 12W cada una) = 48W
- 2 APs WiFi (802.3at, 15W cada uno) = 30W
- Total = 78W
```

### Margen de seguridad

```text
Potencia recomendada = Potencia total × 1.2
Ejemplo:
- Potencia total = 78W
- Margen 20% = 15.6W
- Potencia recomendada = 93.6W
```

### Ejemplo práctico

```text
Escenario: 8 cámaras IP + 2 APs

Cámaras:
- 8 × 802.3af (12W) = 96W

APs:
- 2 × 802.3at (15W) = 30W

Total: 126W
Margen 20%: 25.2W
Recomendado: 151.2W

Opciones:
1. Switch PoE 16 puertos 250W ✅
2. 10 injectors individuales (802.3af/at) ✅
3. Switch PoE 8 puertos 120W ❌ (no suficiente)
```

---

## 🚨 Troubleshooting

### Problema 1: Dispositivo no enciende

```bash
# 1. Verificar que el injector tiene energía
# (LED encendido)

# 2. Verificar voltaje con multímetro
# (debe ser 48V ±10%)

# 3. Verificar cable Ethernet
# (probar con otro cable)

# 4. Verificar que el dispositivo es compatible
# (802.3af/at/bt o passive 48V)

# 5. Probar con otro injector
```

### Problema 2: Dispositivo se reinicia constantemente

```bash
# 1. Verificar consumo del dispositivo
# (debe ser menor a la capacidad del injector)

# 2. Verificar longitud del cable
# (debe ser < 100m)

# 3. Verificar calidad del cable
# (usar cable Cat5e o superior, cobre puro)

# 4. Verificar voltaje en el extremo del dispositivo
# (debe ser > 44V para 802.3af/at)
```

### Problema 3: Injector se calienta mucho

```bash
# 1. Verificar consumo del dispositivo
# (no debe exceder capacidad del injector)

# 2. Asegurar ventilación adecuada
# (no cubrir el injector)

# 3. Verificar que el injector no esté defectuoso
# (probar con otro injector)
```

---

## 💡 Uno-liners imprescindibles

```bash
# Verificar voltaje con multímetro (manual)
# Conectar puntas en pines 1,2 (+) y 3,6 (-)
# Leer voltaje DC (debe ser 44-57V para 802.3af/at)

# Calcular potencia necesaria para N dispositivos
echo "scale=2; (8 * 12 + 2 * 15) * 1.2" | bc

# Listar dispositivos PoE conectados (requiere switch managed)
ssh admin@switch "show poe | grep -E 'port|power|status'"

# Verificar compatibilidad de dispositivo
# Consultar datasheet del dispositivo para estándar PoE requerido

# Calcular caída de voltaje en cable largo
# Fórmula: V_drop = (I × R × L) / 1000
# Donde: I = corriente (A), R = resistencia (Ω/km), L = longitud (m)
echo "scale=2; 0.3 * 93 * 50 / 1000" | bc
# Resultado: caída de voltaje en 50m de cable Cat5e

# Verificar presupuesto PoE total
echo "Suma de potencias: $(echo '8*12 + 2*15' | bc)W"
echo "Con margen 20%: $(echo '(8*12 + 2*15) * 1.2' | bc)W"
```

---

## 🔗 Referencias internas

- [`guides/poe_switches_managed.md`](poe_switches_managed.md) — PoE Switches Managed
- [`guides/cable_diagnostics.md`](cable_diagnostics.md) — Diagnóstico de cables
- [`guides/network_segmentation.md`](network_segmentation.md) — VLANs y segmentación
