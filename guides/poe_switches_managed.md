# PoE Switches Managed — Guía completa

**Nivel:** 🟡 Intermedio
**Archivos de práctica:** Sistema en vivo
**Ver escenarios relacionados:** N/A

---

## ⚡ Quick command

```bash
# Ubiquiti: Ver estado PoE
ssh admin@switch "show poe"

# Cisco: Ver estado PoE
ssh admin@switch "show power inline"
```

---

## 📑 Índice

1. [¿Qué son PoE Switches Managed?](#qué-son-poe-switches-managed)
2. [Modelo mental](#modelo-mental)
3. [Estándares PoE](#estándares-poe)
4. [Ubiquiti](#ubiquiti)
5. [TP-Link](#tp-link)
6. [Netgear](#netgear)
7. [Cisco](#cisco)
8. [HPE/Aruba](#hpearuba)
9. [Diagnóstico PoE](#diagnóstico-poe)
10. [Troubleshooting](#troubleshooting)
11. [Uno-liners imprescindibles](#uno-liners-imprescindibles)
12. [Referencias internas](#referencias-internas)

---

## 🧠 ¿Qué son PoE Switches Managed?

Los **PoE Switches Managed** son switches de red que:

- **Proveen energía por Ethernet (PoE)**: alimentan dispositivos vía cable de red
- **Son gestionables**: configuración vía CLI, web, SNMP
- **Monitorean consumo**: watts, voltaje, corriente por puerto
- **Protegen dispositivos**: detección de cortocircuitos, sobrecarga
- **Priorizan tráfico**: QoS para voz, video, datos

### Ventajas vs Switches No-PoE

| Ventaja | Descripción |
|---------|-------------|
| **Menos cables** | Solo un cable para datos y energía |
| **Instalación flexible** | Dispositivos en cualquier lugar con cable de red |
| **Centralización** | UPS central protege todos los dispositivos |
| **Monitoreo** | Ver consumo y estado de cada puerto |
| **Reset remoto** | Power cycle de puertos específicos |

---

## 🧠 Modelo mental

Un PoE Switch es un **switch de red + fuente de alimentación inteligente**.

Piensa en el switch como:

- **Switch**: conecta dispositivos de red (cámaras, APs, teléfonos)
- **Fuente PoE**: provee energía a los dispositivos conectados
- **Gestor inteligente**: monitorea consumo, protege contra cortos, permite reset remoto

---

## ⚡ Estándares PoE

### IEEE 802.3af (PoE)

```text
Potencia máxima: 15.4W por puerto
Potencia usable: 12.95W por puerto
Voltaje: 44-57V DC
Uso típico: Cámaras IP básicas, teléfonos VoIP, APs básicos
```

### IEEE 802.3at (PoE+)

```text
Potencia máxima: 30W por puerto
Potencia usable: 25.5W por puerto
Voltaje: 50-57V DC
Uso típico: Cámaras IP con PTZ, APs de alta densidad, pantallas táctiles
```

### IEEE 802.3bt (PoE++)

```text
Tipo 3: 60W por puerto (51W usable)
Tipo 4: 100W por puerto (71.3W usable)
Voltaje: 50-57V DC
Uso típico: Laptops, TVs, estaciones de trabajo, cámaras PTZ con calefacción
```

### PoE Pasivo (No estándar)

```text
Voltaje: 24V o 48V (fijo, sin negociación)
Potencia: Variable
Uso típico: Equipos legacy, dispositivos específicos
⚠️ Riesgo: Puede dañar dispositivos si el voltaje es incorrecto
```

### Tabla comparativa

| Estándar | Potencia | Voltaje | Uso típico |
|----------|----------|---------|------------|
| 802.3af | 15.4W | 44-57V | Cámaras básicas, teléfonos |
| 802.3at | 30W | 50-57V | Cámaras PTZ, APs |
| 802.3bt (Tipo 3) | 60W | 50-57V | Laptops, TVs |
| 802.3bt (Tipo 4) | 100W | 50-57V | Estaciones de trabajo |
| Pasivo 24V | Variable | 24V | Equipos legacy |
| Pasivo 48V | Variable | 48V | Equipos legacy |

---

## 📡 Ubiquiti

### Modelos comunes

- **US-8-60W**: 8 puertos, 60W total
- **US-16-150W**: 16 puertos, 150W total
- **US-24-250W**: 24 puertos, 250W total
- **US-48-500W**: 48 puertos, 500W total
- **USW-Enterprise**: 24/48 puertos, PoE++

### Acceso SSH

```bash
ssh admin@192.168.1.20
# Password: configurado en UniFi Controller
```

### Comandos CLI

```bash
# Ver estado PoE de todos los puertos
show poe

# Ver estado PoE de un puerto específico
show poe port 1

# Ver consumo detallado
show poe detail

# Ver presupuesto de potencia
show poe budget

# Resetear puerto PoE (power cycle)
set poe off 1
set poe on 1

# Deshabilitar PoE en un puerto
set poe off 1

# Habilitar PoE en un puerto
set poe on 1

# Ver logs de PoE
show log | grep poe
```

### API de UniFi Controller

```bash
# Autenticar y obtener token
curl -k -X POST "https://controller:8443/api/login" \
  -d '{"username":"admin","password":"admin"}' \
  -c /tmp/unifi_cookies

# Ver estado PoE de todos los switches
curl -k -b /tmp/unifi_cookies \
  "https://controller:8443/api/s/default/stat/device" | jq '.data[] | select(.type=="usw") | {name, poe: .port_overrides}'

# Resetear puerto PoE
curl -k -b /tmp/unifi_cookies -X POST \
  "https://controller:8443/api/s/default/cmd/devmgr" \
  -d '{"cmd":"power-cycle","mac":"00:11:22:33:44:55","port_idx":1}'
```

---

## 📡 TP-Link

### Modelos comunes

- **TL-SG1005P**: 5 puertos, 60W total
- **TL-SG1008P**: 8 puertos, 62W total
- **TL-SG1016PE**: 16 puertos, 180W total
- **TL-SG1024PE**: 24 puertos, 250W total

### Acceso web

```bash
http://192.168.0.1
# Usuario: admin
# Password: admin
```

### Configuración PoE

```bash
# 1. Acceder a la interfaz web
# 2. Ir a PoE → PoE Settings
# 3. Habilitar PoE en puertos específicos
# 4. Configurar prioridad (Low, Medium, High, Critical)
# 5. Guardar
```

### SNMP (monitoreo)

```bash
# Ver estado PoE vía SNMP
snmpwalk -v2c -c public 192.168.0.1 1.3.6.1.2.1.105.1.3.1

# Ver consumo por puerto
snmpwalk -v2c -c public 192.168.0.1 1.3.6.1.2.1.105.1.3.1.1
```

---

## 📡 Netgear

### Modelos comunes

- **GS305P**: 5 puertos, 60W total
- **GS308P**: 8 puertos, 62W total
- **GS110TP**: 8 puertos, 76W total
- **GS310TP**: 10 puertos, 100W total

### Acceso web

```bash
http://192.168.0.239
# Usuario: admin
# Password: password
```

### Comandos CLI

```bash
# Ver estado PoE
show poe

# Ver consumo por puerto
show poe power

# Resetear puerto PoE
poe reset-port 1

# Deshabilitar PoE
poe shutdown port 1

# Habilitar PoE
poe enable port 1
```

---

## 📡 Cisco

### Modelos comunes

- **SG350-10P**: 10 puertos, 75W total
- **SG350-28P**: 28 puertos, 200W total
- **C9200-24P**: 24 puertos, 370W total
- **C9200-48P**: 48 puertos, 740W total

### Acceso SSH

```bash
ssh admin@192.168.1.1
# Password: configurado
```

### Comandos CLI

```bash
# Ver estado PoE
show power inline

# Ver estado PoE detallado
show power inline detail

# Ver consumo por puerto
show power inline | include Gi

# Ver presupuesto de potencia
show power inline budget

# Resetear puerto PoE
test power inline port reset Gi1/0/1

# Deshabilitar PoE
interface Gi1/0/1
 power inline never

# Habilitar PoE
interface Gi1/0/1
 power inline auto

# Ver logs de PoE
show logging | include POWER
```

---

## 📡 HPE/Aruba

### Modelos comunes

- **2530-8P**: 8 puertos, 74W total
- **2530-24P**: 24 puertos, 185W total
- **2930F-24G-PoE+**: 24 puertos, 370W total
- **2930F-48G-PoE+**: 48 puertos, 740W total

### Acceso SSH

```bash
ssh admin@192.168.1.1
# Password: configurado
```

### Comandos CLI

```bash
# Ver estado PoE
show poe

# Ver estado PoE detallado
show poe detailed

# Ver consumo por puerto
show poe power

# Ver presupuesto de potencia
show poe budget

# Resetear puerto PoE
poe reset-port 1

# Deshabilitar PoE
interface 1
 poe disable

# Habilitar PoE
interface 1
 poe enable

# Ver logs de PoE
show log | include POE
```

---

## 🔍 Diagnóstico PoE

### Verificar estado del puerto

```bash
# Ubiquiti
ssh admin@switch "show poe port 1"

# Cisco
ssh admin@switch "show power inline | include Gi1/0/1"

# HPE/Aruba
ssh admin@switch "show poe | include 1"
```

### Verificar consumo de energía

```bash
# Ubiquiti
ssh admin@switch "show poe detail | grep -E 'port|power'"

# Cisco
ssh admin@switch "show power inline detail | include Gi1/0/1"

# HPE/Aruba
ssh admin@switch "show poe power"
```

### Verificar presupuesto de potencia

```bash
# Ubiquiti
ssh admin@switch "show poe budget"

# Cisco
ssh admin@switch "show power inline budget"

# HPE/Aruba
ssh admin@switch "show poe budget"
```

### Verificar errores PoE

```bash
# Ubiquiti
ssh admin@switch "show log | grep poe"

# Cisco
ssh admin@switch "show logging | include POWER"

# HPE/Aruba
ssh admin@switch "show log | include POE"
```

### SNMP (monitoreo)

```bash
# Ver estado PoE vía SNMP
snmpwalk -v2c -c public switch_ip 1.3.6.1.2.1.105.1.3.1

# Ver consumo por puerto
snmpwalk -v2c -c public switch_ip 1.3.6.1.2.1.105.1.3.1.1

# Ver voltaje por puerto
snmpwalk -v2c -c public switch_ip 1.3.6.1.2.1.105.1.3.1.2

# Ver corriente por puerto
snmpwalk -v2c -c public switch_ip 1.3.6.1.2.1.105.1.3.1.3
```

---

## 🚨 Troubleshooting

### Problema 1: Dispositivo no enciende

```bash
# Verificar que PoE está habilitado en el puerto
ssh admin@switch "show poe port 1"

# Verificar que el dispositivo es compatible con el estándar PoE
# (802.3af, 802.3at, 802.3bt)

# Verificar que el cable es de buena calidad (Cat5e o superior)

# Verificar longitud del cable (< 100m)

# Resetear puerto PoE
ssh admin@switch "set poe off 1 && set poe on 1"
```

### Problema 2: Dispositivo se reinicia constantemente

```bash
# Verificar consumo del dispositivo
ssh admin@switch "show poe port 1"

# Si el consumo es cercano al límite del puerto:
# - Cambiar a puerto con mayor capacidad
# - Usar switch con mayor presupuesto PoE

# Verificar que el presupuesto total del switch no se exceda
ssh admin@switch "show poe budget"
```

### Problema 3: Puerto PoE muestra "fault"

```bash
# Ver logs de errores
ssh admin@switch "show log | grep poe"

# Causas comunes:
# - Cortocircuito en el cable
# - Dispositivo incompatible
# - Sobrecarga

# Resetear puerto
ssh admin@switch "set poe off 1 && set poe on 1"

# Si el problema persiste:
# - Probar con otro cable
# - Probar con otro dispositivo
# - Deshabilitar puerto si está defectuoso
```

### Problema 4: Presupuesto PoE excedido

```bash
# Ver presupuesto total y consumo
ssh admin@switch "show poe budget"

# Si el consumo total > presupuesto:
# - Deshabilitar PoE en puertos no críticos
# - Reducir prioridad de puertos
# - Agregar switch PoE adicional

# Configurar prioridades
ssh admin@switch "set poe priority 1 critical"
ssh admin@switch "set poe priority 2 low"
```

---

## 💡 Uno-liners imprescindibles

```bash
# Ubiquiti: Ver estado PoE de todos los puertos
ssh admin@switch "show poe | grep -E 'port|power|status'"

# Cisco: Ver estado PoE de todos los puertos
ssh admin@switch "show power inline | grep -E 'Gi|power'"

# HPE/Aruba: Ver estado PoE de todos los puertos
ssh admin@switch "show poe | grep -E 'port|power|status'"

# Ver consumo total de todos los switches
for switch in switch1 switch2 switch3; do ssh admin@$switch "show poe budget"; done

# Resetear todos los puertos PoE de un switch
for port in $(seq 1 24); do ssh admin@switch "set poe off $port && set poe on $port"; done

# Ver dispositivos con mayor consumo
ssh admin@switch "show poe detail | sort -k3 -n -r | head -10"

# Monitorear consumo PoE en tiempo real
watch -n 5 'ssh admin@switch "show poe | grep power"'

# Ver puertos con errores PoE
ssh admin@switch "show log | grep -i 'poe.*fault\|poe.*error'"

# Calcular presupuesto PoE restante
ssh admin@switch "show poe budget | awk '/Budget/{print \$3-\$5}'"
```

---

## 🔗 Referencias internas

- [`guides/poe_injectors.md`](poe_injectors.md) — PoE Injectors básicos
- [`guides/network_segmentation.md`](network_segmentation.md) — VLANs y segmentación
- [`guides/cable_diagnostics.md`](cable_diagnostics.md) — Diagnóstico de cables
