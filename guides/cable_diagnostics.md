# Cable Diagnostics — Guía completa

**Nivel:** 🟡 Intermedio
**Archivos de práctica:** Sistema en vivo
**Ver escenarios relacionados:** N/A

---

## ⚡ Quick command

```bash
# Ver estado del enlace y errores
ethtool eth0 | grep -E "Speed|Duplex|Link" && ip -s link show eth0 | grep -A 5 "RX:\|TX:"
```

---

## 📑 Índice

1. [¿Qué es Cable Diagnostics?](#qué-es-cable-diagnostics)
2. [Modelo mental](#modelo-mental)
3. [ethtool: diagnóstico de enlace](#ethtool-diagnóstico-de-enlace)
4. [Errores de TX/RX](#errores-de-txrx)
5. [Categorías de cable](#categorías-de-cable)
6. [Longitud máxima](#longitud-máxima)
7. [Herramientas de testing](#herramientas-de-testing)
8. [Problemas comunes](#problemas-comunes)
9. [Diagnóstico desde Linux](#diagnóstico-desde-linux)
10. [Troubleshooting](#troubleshooting)
11. [Uno-liners imprescindibles](#uno-liners-imprescindibles)
12. [Referencias internas](#referencias-internas)

---

## 🧠 ¿Qué es Cable Diagnostics?

**Cable Diagnostics** es el proceso de verificar la integridad y rendimiento de cables de red Ethernet. Incluye:

- **Verificar estado del enlace**: velocidad, duplex, conexión
- **Detectar errores**: CRC, frame, collisions
- **Identificar problemas físicos**: cable defectuoso, interferencia, longitud excesiva
- **Certificar instalación**: verificar que el cable cumple especificaciones

### Importancia

```text
Un cable defectuoso puede causar:
- Pérdida de paquetes
- Baja velocidad
- Conexiones intermitentes
- Dispositivos que no responden
- PoE que no funciona
```

---

## 🧠 Modelo mental

Un cable Ethernet es un **medio de transmisión físico**.

Piensa en el cable como:

- **Medio físico**: transporta señales eléctricas
- **Pares trenzados**: 4 pares (8 hilos) que reducen interferencia
- **Conectores RJ45**: terminaciones en ambos extremos
- **Longitud limitada**: máximo 100m para Ethernet

---

## 🔧 ethtool: diagnóstico de enlace

### Ver estado del enlace

```bash
# Ver velocidad, duplex y estado del link
ethtool eth0 | grep -E "Speed|Duplex|Link"

# Salida esperada:
# Speed: 1000Mb/s
# Duplex: Full
# Link detected: yes
```

### Ver información completa

```bash
# Ver todas las capacidades del enlace
ethtool eth0

# Salida (extracto):
# Settings for eth0:
#     Supported ports: [ TP MII ]
#     Supported link modes:   10baseT/Half 10baseT/Full
#                             100baseT/Half 100baseT/Full
#                             1000baseT/Half 1000baseT/Full
#     Supported pause frame use: No
#     Supports auto-negotiation: Yes
#     Advertised link modes:  10baseT/Half 10baseT/Full
#                             100baseT/Half 100baseT/Full
#                             1000baseT/Half 1000baseT/Full
#     Advertised pause frame use: Symmetric Receive-only
#     Advertised auto-negotiation: Yes
#     Speed: 1000Mb/s
#     Duplex: Full
#     Port: MII
#     PHYAD: 0
#     Transceiver: internal
#     Auto-negotiation: on
#     Link detected: yes
```

### Ver capacidades del enlace

```bash
# Ver modos de enlace soportados
ethtool eth0 | grep -A 10 "Supported link modes"

# Ver modos de enlace anunciados
ethtool eth0 | grep -A 10 "Advertised link modes"

# Ver auto-negotiation
ethtool eth0 | grep -A 5 "Auto-negotiation"
```

### Cambiar configuración del enlace

```bash
# Forzar velocidad y duplex (no recomendado)
sudo ethtool -s eth0 speed 1000 duplex full autoneg on

# Habilitar auto-negotiation
sudo ethtool -s eth0 autoneg on

# Verificar cambios
ethtool eth0 | grep -E "Speed|Duplex|Auto-negotiation"
```

---

## 📊 Errores de TX/RX

### Ver errores de transmisión/recepción

```bash
# Ver estadísticas completas
ip -s link show eth0

# Salida (extracto):
# 2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP mode DEFAULT group default qlen 1000
#     link/ether 08:00:27:ab:cd:ef brd ff:ff:ff:ff:ff:ff
#     RX:  bytes packets errors dropped  missed   mcast
#          1234567   12345      0       0       0       0
#     TX:  bytes packets errors dropped carrier collsns
#           123456   12345      0       0       0       0
```

### Interpretación de errores

| Error | Significado | Causa probable |
|-------|-------------|----------------|
| `RX errors` | Errores al recibir | Cable defectuoso, interferencia, duplex mismatch |
| `RX dropped` | Paquetes recibidos pero no procesados | Falta de buffers, sobrecarga |
| `RX overruns` | Paquetes perdidos por falta de buffer | Tráfico muy alto, hardware lento |
| `TX errors` | Errores al transmitir | Cable defectuoso, NIC defectuosa |
| `TX dropped` | Paquetes no transmitidos | Cola de transmisión llena |
| `TX collisions` | Colisiones en la red | Half-duplex, hub (no switch) |
| `carrier` | Pérdidas de señal | Cable desconectado, switch apagado |
| `missed` | Paquetes perdidos por hardware | NIC defectuosa, driver bug |

### Monitorear errores en tiempo real

```bash
# Ver errores cada 5 segundos
watch -n 5 'ip -s link show eth0 | grep -E "errors|drop"'

# Ver solo errores crescentes
ip -s link show eth0 | grep -E "errors|drop" | awk '{print $1, $2, $3}'
```

---

## 📏 Categorías de cable

### Cat5 (obsoleto)

```text
Velocidad máxima: 100 Mbps
Frecuencia: 100 MHz
Uso: Redes antiguas (10/100 Mbps)
No recomendado para instalaciones nuevas
```

### Cat5e (mejorado)

```text
Velocidad máxima: 1 Gbps
Frecuencia: 100 MHz
Uso: Gigabit Ethernet (10/100/1000 Mbps)
Mínimo recomendado para instalaciones nuevas
```

### Cat6

```text
Velocidad máxima: 10 Gbps (hasta 55m)
Frecuencia: 250 MHz
Uso: 10 Gigabit Ethernet (distancias cortas)
Recomendado para instalaciones nuevas
```

### Cat6a (aumentado)

```text
Velocidad máxima: 10 Gbps (hasta 100m)
Frecuencia: 500 MHz
Uso: 10 Gigabit Ethernet (distancias completas)
Recomendado para data centers
```

### Cat7 (blindado)

```text
Velocidad máxima: 10 Gbps (hasta 100m)
Frecuencia: 600 MHz
Blindaje: S/FTP (shielded)
Uso: Entornos con alta interferencia
No estándar oficial (proprietario)
```

### Cat8

```text
Velocidad máxima: 25/40 Gbps (hasta 30m)
Frecuencia: 2000 MHz
Blindaje: S/FTP (shielded)
Uso: Data centers, conexiones cortas de alta velocidad
```

### Tabla comparativa

| Categoría | Velocidad | Frecuencia | Distancia | Uso |
|-----------|-----------|------------|-----------|-----|
| Cat5 | 100 Mbps | 100 MHz | 100m | Obsoleto |
| Cat5e | 1 Gbps | 100 MHz | 100m | Gigabit Ethernet |
| Cat6 | 10 Gbps | 250 MHz | 55m | 10 Gigabit (corto) |
| Cat6a | 10 Gbps | 500 MHz | 100m | 10 Gigabit (completo) |
| Cat7 | 10 Gbps | 600 MHz | 100m | Alta interferencia |
| Cat8 | 40 Gbps | 2000 MHz | 30m | Data centers |

---

## 📏 Longitud máxima

### Estándar Ethernet

```text
Longitud máxima: 100m (328 pies)
Composición:
- 90m de cable horizontal (instalación fija)
- 5m de patch cord en cada extremo (conexiones flexibles)
```

### Por qué 100m

```text
- Atenuación de señal: la señal se debilita con la distancia
- Retardo de propagación: la señal tarda en llegar
- Reflexiones: señales rebotan en los extremos
- Interferencia: ruido externo afecta la señal
```

### Consecuencias de exceder 100m

```text
- Pérdida de paquetes
- Baja velocidad (auto-negotiation baja a 100 Mbps o 10 Mbps)
- Conexiones intermitentes
- Dispositivos que no responden
- PoE que no funciona (caída de voltaje)
```

### Soluciones para distancias > 100m

```text
1. Switch intermedio: colocar switch a mitad de camino
2. Fiber optic: usar fibra óptica (hasta 10km)
3. Ethernet extenders: dispositivos que extienden Ethernet
4. PoE extenders: extienden PoE hasta 200-300m
```

---

## 🔧 Herramientas de testing

### Toner probe (rastreador de cables)

```text
Función: Rastrear cable a través de paredes/techos
Uso: Identificar qué cable va a qué puerto
Componentes:
- Transmitter: emite tono en un extremo
- Receiver: detecta tono en el otro extremo
Precio: $20-50
```

### Cable tester básico

```text
Función: Verificar continuidad y wiring
Pruebas:
- Continuidad: cada pin está conectado
- Cable cruzado: pares correctos
- Cable abierto: pin no conectado
- Cable en corto: dos pines conectados entre sí
Precio: $15-30
```

### Cable certifier (Fluke, etc.)

```text
Función: Certificar que el cable cumple especificaciones
Pruebas:
- Longitud
- Atenuación
- NEXT (Near-End Crosstalk)
- Return Loss
- Propagation Delay
Precio: $1000-5000
Uso: Instalaciones profesionales, certificaciones
```

### Multímetro

```text
Función: Verificar continuidad y voltaje
Pruebas:
- Continuidad: verificar que cada pin está conectado
- Resistencia: verificar calidad del cable
- Voltaje: verificar PoE (48V DC)
Precio: $20-100
```

---

## ⚠️ Problemas comunes

### Cable cruzado (crossover) vs recto (straight-through)

```text
Straight-through (recto):
- PC → Switch
- Router → Switch
- Pares: 1-1, 2-2, 3-3, 6-6

Crossover (cruzado):
- PC → PC
- Switch → Switch
- Router → Router
- Pares: 1-3, 2-6, 3-1, 6-2

Nota: Dispositivos modernos soportan Auto-MDIX
(detectan automáticamente y ajustan)
```

### Conector RJ45 mal crimpado

```text
Síntomas:
- Conexión intermitente
- Errores de CRC crescentes
- Velocidad baja (100 Mbps en vez de 1 Gbps)

Causas:
- Hilos no llegan al final del conector
- Orden de colores incorrecto
- Conector dañado
- Herramienta de crimpado defectuosa

Solución:
- Recrimpado o reemplazo del conector
```

### Interferencia electromagnética (EMI)

```text
Fuentes de EMI:
- Cables de energía
- Motores eléctricos
- Luces fluorescentes
- Radios, transmisores
- Cables de red sin blindaje cerca de fuentes EMI

Síntomas:
- Errores de CRC
- Pérdida de paquetes
- Velocidad inconsistente

Soluciones:
- Usar cable blindado (FTP/STP)
- Alejar cables de fuentes EMI
- Usar cable de fibra óptica
```

### Cable demasiado largo

```text
Síntomas:
- Dispositivo no responde
- Velocidad baja (auto-negotiation a 100 Mbps)
- PoE no funciona

Causas:
- Cable > 100m
- Cable de mala calidad (CCA en vez de cobre)

Soluciones:
- Reducir longitud del cable
- Usar cable de mejor calidad (Cat6, cobre puro)
- Agregar switch intermedio
```

### Cable dañado

```text
Tipos de daño:
- Mordeduras (roedores)
- Dobleces excesivos
- Aplastamiento
- Humedad/agua
- Exposición al sol (UV)

Síntomas:
- Conexión intermitente
- Errores crescentes
- Dispositivo no responde

Solución:
- Reemplazar cable
```

---

## 🐧 Diagnóstico desde Linux

### ethtool

```bash
# Ver estado del enlace
ethtool eth0 | grep -E "Speed|Duplex|Link"

# Ver información completa
ethtool eth0

# Ver capacidades
ethtool eth0 | grep -A 10 "Supported link modes"

# Ver auto-negotiation
ethtool eth0 | grep -A 5 "Auto-negotiation"
```

### ip -s link

```bash
# Ver estadísticas completas
ip -s link show eth0

# Ver errores de TX/RX
ip -s link show eth0 | grep -A 5 "RX:\|TX:"

# Monitorear errores en tiempo real
watch -n 5 'ip -s link show eth0 | grep -E "errors|drop"'
```

### dmesg

```bash
# Ver mensajes del kernel sobre la interfaz
dmesg | grep eth0 | tail -20

# Ver errores de enlace
dmesg | grep -i "link\|eth0" | tail -20
```

### SNMP (monitoreo remoto)

```bash
# Ver estado del enlace vía SNMP
snmpwalk -v2c -c public switch_ip 1.3.6.1.2.1.2.2.1.8

# Ver errores de TX/RX vía SNMP
snmpwalk -v2c -c public switch_ip 1.3.6.1.2.1.2.2.1.14

# Ver velocidad del enlace vía SNMP
snmpwalk -v2c -c public switch_ip 1.3.6.1.2.1.2.2.1.5
```

---

## 🚨 Troubleshooting

### Problema 1: Link down

```bash
# 1. Verificar que el cable está conectado
# (LED del puerto encendido)

# 2. Verificar estado del enlace
ethtool eth0 | grep "Link detected"

# 3. Probar con otro cable
# 4. Probar con otro puerto
# 5. Verificar que el switch está encendido
```

### Problema 2: Link up pero sin tráfico

```bash
# 1. Verificar errores de TX/RX
ip -s link show eth0 | grep -A 5 "RX:\|TX:"

# 2. Si hay errores crescentes:
# - Cable defectuoso
# - Interferencia
# - Conector mal crimpado

# 3. Verificar velocidad y duplex
ethtool eth0 | grep -E "Speed|Duplex"

# 4. Si velocidad es baja (100 Mbps en vez de 1 Gbps):
# - Cable Cat5 o inferior
# - Cable dañado
# - Interferencia
```

### Problema 3: Velocidad baja

```bash
# 1. Verificar velocidad del enlace
ethtool eth0 | grep "Speed"

# 2. Si es 100 Mbps en vez de 1 Gbps:
# - Cable Cat5 o inferior → usar Cat5e o superior
# - Cable dañado → reemplazar cable
# - Interferencia → usar cable blindado

# 3. Verificar auto-negotiation
ethtool eth0 | grep "Auto-negotiation"

# 4. Si auto-negotiation está deshabilitado:
sudo ethtool -s eth0 autoneg on
```

### Problema 4: Errores de CRC crescentes

```bash
# 1. Monitorear errores
watch -n 5 'ip -s link show eth0 | grep -E "errors"'

# 2. Si los errores crecen constantemente:
# - Cable defectuoso
# - Interferencia EMI
# - Conector mal crimpado

# 3. Soluciones:
# - Reemplazar cable
# - Usar cable blindado
# - Alejar de fuentes EMI
# - Recrimpado de conectores
```

### Problema 5: PoE no funciona

```bash
# 1. Verificar que el switch/inyector soporta PoE
# 2. Verificar voltaje con multímetro
# (debe ser 48V DC ±10%)

# 3. Verificar longitud del cable
# (debe ser < 100m)

# 4. Verificar calidad del cable
# (usar cable Cat5e o superior, cobre puro)

# 5. Verificar consumo del dispositivo
# (no debe exceder capacidad del puerto PoE)
```

---

## 💡 Uno-liners imprescindibles

```bash
# Ver estado del enlace y errores
ethtool eth0 | grep -E "Speed|Duplex|Link" && ip -s link show eth0 | grep -A 5 "RX:\|TX:"

# Monitorear errores en tiempo real
watch -n 5 'ip -s link show eth0 | grep -E "errors|drop"'

# Ver mensajes del kernel sobre la interfaz
dmesg | grep eth0 | tail -20

# Ver capacidades del enlace
ethtool eth0 | grep -A 10 "Supported link modes"

# Ver auto-negotiation
ethtool eth0 | grep -A 5 "Auto-negotiation"

# Calcular caída de voltaje en cable PoE
# Fórmula: V_drop = (I × R × L) / 1000
echo "scale=2; 0.3 * 93 * 50 / 1000" | bc
# Resultado: caída de voltaje en 50m de cable Cat5e

# Verificar que el cable soporta Gigabit
ethtool eth0 | grep "Speed" | grep -q "1000Mb/s" && echo "✅ Gigabit OK" || echo "❌ No Gigabit"

# Contar errores de CRC en las últimas 24 horas
ip -s link show eth0 | grep "RX errors" | awk '{print $3}'

# Verificar estado de todos los puertos de un switch
for port in $(seq 1 24); do ssh admin@switch "show interface Gi1/0/$port | include line protocol"; done

# Calcular longitud máxima de cable PoE
# Fórmula: L_max = (V_source - V_device_min) / (I × R)
echo "scale=2; (50 - 44) / (0.3 * 93)" | bc
# Resultado: longitud máxima en metros
```

---

## 🔗 Referencias internas

- [`guides/ip_ss.md`](ip_ss.md) — Diagnóstico de link físico y PoE
- [`guides/poe_switches_managed.md`](poe_switches_managed.md) — PoE Switches Managed
- [`guides/poe_injectors.md`](poe_injectors.md) — PoE Injectors
- [`guides/network_segmentation.md`](network_segmentation.md) — VLANs y segmentación
