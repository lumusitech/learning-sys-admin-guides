# Access Points Consumer — Guía completa

**Nivel:** 🟡 Intermedio
**Archivos de práctica:** Sistema en vivo
**Ver escenarios relacionados:** N/A

---

## ⚡ Quick command

```bash
# Ver redes WiFi disponibles
iwlist wlan0 scan | grep -E "ESSID|Quality"
```

---

## 📑 Índice

1. [¿Qué son Access Points Consumer?](#qué-son-access-points-consumer)
2. [Modelo mental](#modelo-mental)
3. [TP-Link](#tp-link)
4. [D-Link](#d-link)
5. [Tenda](#tenda)
6. [Configuración básica](#configuración-básica)
7. [Modos de operación](#modos-de-operación)
8. [Diagnóstico básico](#diagnóstico-básico)
9. [Limitaciones vs Enterprise](#limitaciones-vs-enterprise)
10. [Troubleshooting](#troubleshooting)
11. [Uno-liners imprescindibles](#uno-liners-imprescindibles)
12. [Referencias internas](#referencias-internas)

---

## 🧠 ¿Qué son Access Points Consumer?

Los **Access Points Consumer** son puntos de acceso WiFi diseñados para hogares y pequeñas oficinas con:

- **Configuración web**: interfaz gráfica para configuración
- **Standalone**: funcionan sin controller central
- **Funciones básicas**: WPA2, DHCP, firewall básico
- **Precio accesible**: $30-100 USD
- **Densidad limitada**: 10-20 clientes simultáneos

### Diferencias vs Access Points Enterprise

| Característica | Enterprise | Consumer |
|----------------|------------|----------|
| **Controller** | ✅ Centralizado | ❌ Standalone |
| **Roaming** | ✅ Seamless | ⚠️ Básico |
| **VLANs** | ✅ Múltiples por SSID | ❌ Una sola |
| **RADIUS/LDAP** | ✅ Soportado | ❌ No |
| **Monitoreo** | ✅ Avanzado | ⚠️ Básico |
| **Densidad** | ✅ 50-100+ clientes | ⚠️ 10-20 clientes |
| **PoE** | ✅ 802.3af/at | ⚠️ Algunos modelos |
| **Precio** | 💰💰💰 $200-800 | 💰 $30-100 |

---

## 🧠 Modelo mental

Un AP consumer es un **router WiFi standalone**.

Piensa en el AP como:

- **Dispositivo independiente**: no necesita controller
- **Configuración web**: interfaz gráfica accesible por navegador
- **Funciones limitadas**: WPA2, DHCP, firewall básico
- **Sin roaming avanzado**: cada AP funciona de forma independiente

---

## 📡 TP-Link

### Modelos comunes

- **TL-WA850RE**: Range Extender
- **TL-WR841N**: Router WiFi 300Mbps
- **Archer C6**: Router WiFi AC1200
- **EAP225**: Access Point Enterprise (gama alta)

### Acceso a la interfaz web

```bash
# IP por defecto
http://192.168.0.1
# o
http://192.168.1.1

# Credenciales por defecto
Usuario: admin
Password: admin
```

### Configuración básica

```bash
# 1. Acceder a la interfaz web
# 2. Ir a Wireless → Wireless Settings
# 3. Configurar SSID y contraseña
# 4. Guardar y reiniciar
```

### Diagnóstico desde Linux

```bash
# Ver información del AP
iwconfig wlan0

# Ver señal y calidad
iw dev wlan0 link

# Escanear redes disponibles
iwlist wlan0 scan | grep -E "ESSID|Quality|Channel"

# Ver canales disponibles
iwlist wlan0 channel
```

---

## 📡 D-Link

### Modelos comunes

- **DIR-825**: Router WiFi AC1200
- **DAP-1360**: Access Point
- **DAP-1620**: Range Extender

### Acceso a la interfaz web

```bash
# IP por defecto
http://192.168.0.1
# o
http://192.168.1.1

# Credenciales por defecto
Usuario: admin
Password: (vacío)
```

### Configuración básica

```bash
# 1. Acceder a la interfaz web
# 2. Ir a Setup → Wireless Settings
# 3. Configurar SSID y contraseña
# 4. Guardar y reiniciar
```

---

## 📡 Tenda

### Modelos comunes

- **N301**: Router WiFi 300Mbps
- **AC10**: Router WiFi AC1200
- **A9**: Range Extender

### Acceso a la interfaz web

```bash
# IP por defecto
http://192.168.0.1

# Credenciales por defecto
Usuario: admin
Password: admin
```

---

## ⚙️ Configuración básica

### Configurar SSID y contraseña

```bash
# 1. Acceder a la interfaz web del AP
# 2. Ir a Wireless → Wireless Settings
# 3. Configurar:
#    - SSID: MiRedWiFi
#    - Security: WPA2-PSK
#    - Password: MiPasswordSeguro123
# 4. Guardar y reiniciar
```

### Configurar canal WiFi

```bash
# 1. Ir a Wireless → Wireless Settings
# 2. Seleccionar canal (1, 6, 11 recomendados para 2.4GHz)
# 3. O seleccionar "Auto" para selección automática
# 4. Guardar y reiniciar
```

### Configurar DHCP

```bash
# 1. Ir a LAN → DHCP Server
# 2. Habilitar DHCP Server
# 3. Configurar rango de IPs (ej: 192.168.1.100 - 192.168.1.200)
# 4. Guardar y reiniciar
```

---

## 🔄 Modos de operación

### Modo Access Point (AP)

```bash
# Función: Crear red WiFi desde conexión cableada
# Uso: Conectar AP a switch/router vía cable Ethernet
# Configurar en: Wireless → Mode → Access Point
```

### Modo Repeater

```bash
# Función: Extender red WiFi existente
# Uso: Conectar AP a red WiFi existente de forma inalámbrica
# Configurar en: Wireless → Mode → Repeater
# Seleccionar red a extender
```

### Modo Bridge

```bash
# Función: Conectar dos redes cableadas vía WiFi
# Uso: Conectar dos edificios o pisos sin cable
# Configurar en: Wireless → Mode → Bridge
# Configurar MAC del AP remoto
```

### Modo Client

```bash
# Función: Conectar dispositivo cableado a red WiFi
# Uso: Conectar PC, consola, smart TV a red WiFi
# Configurar en: Wireless → Mode → Client
# Seleccionar red WiFi
```

---

## 🔍 Diagnóstico básico

### Verificar conectividad

```bash
# Ping al AP
ping 192.168.1.1

# Verificar señal WiFi
iwconfig wlan0 | grep -E "Link|Quality|Signal"

# Ver información de la conexión
iw dev wlan0 link
```

### Verificar clientes conectados

```bash
# Desde la interfaz web del AP
# Ir a: Status → Wireless → Associated Stations

# O desde Linux (si el AP lo soporta)
iw dev wlan0 station dump
```

### Verificar canales e interferencia

```bash
# Escanear redes WiFi
iwlist wlan0 scan | grep -E "ESSID|Channel|Quality"

# Ver uso de canales
iw dev wlan0 survey dump

# Analizar espectro (requiere hardware compatible)
wavemon -i wlan0
```

---

## ⚠️ Limitaciones vs Enterprise

### Limitaciones técnicas

| Limitación | Impacto |
|------------|---------|
| **Sin controller** | No hay gestión centralizada |
| **Sin roaming avanzado** | Clientes pueden quedarse "pegados" a un AP |
| **Sin VLANs múltiples** | Todos los clientes en la misma red |
| **Sin RADIUS/LDAP** | Autenticación solo por contraseña |
| **Densidad limitada** | 10-20 clientes máximo |
| **Sin monitoreo avanzado** | No hay métricas de rendimiento |

### Cuándo usar Consumer

- ✅ Hogar o pequeña oficina (< 20 clientes)
- ✅ Presupuesto limitado
- ✅ Configuración simple
- ✅ Sin requerimientos enterprise

### Cuándo usar Enterprise

- ✅ Oficinas grandes (50+ clientes)
- ✅ Múltiples pisos o edificios
- ✅ Requerimientos de seguridad avanzados
- ✅ Roaming seamless necesario
- ✅ Monitoreo y gestión centralizada

---

## 🚨 Troubleshooting

### Problema 1: No puedo acceder a la interfaz web

```bash
# Verificar conectividad
ping 192.168.1.1

# Verificar que estás en la red correcta
iwconfig wlan0 | grep ESSID

# Factory reset (botón físico, mantener 10 segundos)

# Intentar con IP alternativa
ping 192.168.0.1
ping 192.168.1.1
```

### Problema 2: WiFi lento

```bash
# Verificar señal
iwconfig wlan0 | grep -E "Link|Quality"

# Verificar interferencia
iwlist wlan0 scan | grep -E "Channel|Quality"

# Cambiar canal (usar 1, 6, 11 para 2.4GHz)
# O cambiar a 5GHz si el AP lo soporta
```

### Problema 3: Clientes no se conectan

```bash
# Verificar SSID broadcast
iwlist wlan0 scan | grep "MiRedWiFi"

# Verificar contraseña
# (intentar desde otro dispositivo)

# Factory reset y reconfigurar
```

### Problema 4: AP se reinicia constantemente

```bash
# Verificar fuente de alimentación
# (usar fuente original o equivalente)

# Verificar temperatura
# (no cubrir el AP, asegurar ventilación)

# Factory reset
```

---

## 💡 Uno-liners imprescindibles

```bash
# Ver redes WiFi disponibles
iwlist wlan0 scan | grep -E "ESSID|Quality|Channel"

# Ver información de la conexión actual
iwconfig wlan0

# Ver detalles de la conexión (señal, ruido, etc.)
iw dev wlan0 link

# Ver canales disponibles
iwlist wlan0 channel

# Monitorear señal en tiempo real
watch -n 1 'iwconfig wlan0 | grep -E "Link|Quality"'

# Escanear y mostrar solo redes con buena señal
iwlist wlan0 scan | awk '/ESSID/{ssid=$0} /Quality/{print ssid, $0}' | grep -E "Signal level=-[0-6][0-9]"

# Ver MAC address del AP
iw dev wlan0 link | grep "Connected to"

# Ver frecuencia y canal
iw dev wlan0 link | grep -E "freq|channel"

# Capturar tráfico WiFi (modo monitor)
sudo airmon-ng start wlan0 && sudo tcpdump -i mon0 -n

# Ping al AP para verificar latencia
ping -c 10 192.168.1.1 | tail -1
```

---

## 🔗 Referencias internas

- [`guides/access_points_enterprise.md`](access_points_enterprise.md) — Access Points Enterprise
- [`guides/network_segmentation.md`](network_segmentation.md) — VLANs y segmentación
- [`guides/tcpdump.md`](tcpdump.md) — captura de paquetes WiFi
