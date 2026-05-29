# 🧩 Escenario: Pérdida de paquetes y alta latencia en red

---

## 🎯 Problema

Los usuarios reportan lentitud en aplicaciones, cortes intermitentes o mala calidad en servicios en tiempo real (videollamadas, APIs). Es necesario determinar si el problema está relacionado con alta latencia o pérdida de paquetes en la red.

---

## ⚡ Quick command (SRE)

```bash
ping -c 10 -i 0.2 8.8.8.8
```

---

## ✅ Salida esperada

- tiempo de respuesta (RTT) en milisegundos
- porcentaje de paquetes perdidos
- consistencia en los tiempos de respuesta

Interpretación:

- latencia alta (>100ms) → posible problema de red
- paquetes perdidos (>0%) → pérdida de conectividad
- variación alta en tiempos → inestabilidad (jitter)

---

## 🧠 Diagnóstico

La latencia mide el tiempo que tarda un paquete en ir y volver entre origen y destino, mientras que la pérdida de paquetes indica que algunos datos no llegan correctamente.

Patrones clave:

- latencia alta → congestión, distancia o routing ineficiente
- pérdida de paquetes → congestión o fallos en red/hardware
- latencia variable → red inestable o saturada
- pérdida intermitente → problema en algún punto del camino

👉 Latencia alta degrada la experiencia; pérdida de paquetes rompe la comunicación.

---

## 🛠️ Procedimiento (runbook)

### 1. Verificar latencia y pérdida básica

```bash
ping -c 10 8.8.8.8
```

### 2. Analizar ruta hacia destino

```bash
traceroute 8.8.8.8
```

### 3. Diagnóstico continuo (latencia + pérdida)

```bash
mtr -r -c 20 8.8.8.8
```

### 4. Identificar salto problemático

👉 Buscar:

- incremento de latencia
- aparición de pérdida de paquetes en un hop específico

### 5. Verificar conexiones activas

```bash
ss -s
```

### 6. Comparar con otro destino

```bash
ping -c 10 1.1.1.1
```

---

## 🧯 Mitigación

Si se detecta latencia o pérdida:

Verificar:

```bash
ping -c 10 <gateway>
ping -c 10 8.8.8.8
```

Acción:

```bash
# reiniciar interfaz de red
ip link set eth0 down && ip link set eth0 up
```

Mitigación adicional:

```bash
# probar con otro destino (evitar problema externo)
echo "nameserver 1.1.1.1" > /etc/resolv.conf
```

Rollback:

```bash
systemctl restart NetworkManager
```

Casos comunes:

- congestión de red → exceso de tráfico
- routing deficiente → ISP o backbone
- hardware defectuoso → NIC, cables, switches
- WiFi inestable → interferencias o señal baja

---

## ✅ Interpretación

- latencia estable y baja → red saludable
- latencia alta constante → problema estructural
- pérdida de paquetes sostenida → fallo grave de conectividad
- pérdida en un salto específico → problema en ese segmento

---

## 🐧 Variante Alpine (OpenRC)

Este escenario asume systemd (Debian/Ubuntu). En Alpine Linux:

```bash
# Debian:                          # Alpine:
systemctl restart NetworkManager    rc-service networking restart
```

> Alpine no tiene `NetworkManager`. La red se gestiona con `/etc/network/interfaces` y `rc-service networking`.

---

## 🔗 Referencias

- [`ping_traceroute`](../../guides/ping_traceroute.md)
- [`ip_ss`](../../guides/ip_ss.md)
- [`openrc`](../../guides/openrc.md) — Alpine Linux: servicios (rc-service, rc-update)
