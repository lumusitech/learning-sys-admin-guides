# 🧩 Escenario: Timeouts intermitentes en red

---

## 🎯 Problema

Los usuarios reportan fallos intermitentes al acceder a servicios web, APIs o sistemas internos. Las conexiones a veces funcionan y otras fallan sin un patrón claro. Es necesario determinar si el problema está relacionado con la red, DNS, o servicios backend.

---

## ⚡ Quick command (SRE)

```bash
ping -c 10 8.8.8.8; curl -I https://google.com || echo "FALLO"
```

---

## ✅ Salida esperada

- respuestas exitosas en ping y curl
- tiempos consistentes de respuesta
- ausencia de errores de conexión o timeout

Interpretación:

- fallos intermitentes → problema no determinístico
- ping OK pero curl falla → problema de capa superior (DNS / HTTP)
- curl intermitente → backend o red inestable

---

## 🧠 Diagnóstico

Los timeouts intermitentes son difíciles de detectar porque no siempre ocurren y pueden tener múltiples causas.

Patrones clave:

- conectividad intermitente → problemas de red o routing
- fallos selectivos → problema en backend o firewall
- DNS inestable → resolución inconsistente
- latencia variable → congestión o jitter

👉 Un sistema que falla intermitentemente es más difícil de diagnosticar que uno completamente caído.

---

## 🛠️ Procedimiento (runbook)

### 1. Verificar conectividad básica

```bash
ping -c 10 8.8.8.8
```

### 2. Probar acceso a servicio externo

```bash
curl -I https://google.com
```

### 3. Repetir pruebas (detectar intermitencia)

```bash
for i in {1..5}; do curl -I https://google.com || echo "FALLO"; done
```

### 4. Verificar resolución DNS

```bash
dig google.com +stats
```

### 5. Analizar ruta y pérdida

```bash
mtr -r -c 20 8.8.8.8
```

### 6. Verificar logs de sistema

```bash
journalctl -p err -b | tail -20
```

---

## 🧯 Mitigación

Si hay timeouts intermitentes:

Verificar:

```bash
ping -c 10 <destino>
mtr -r -c 10 <destino>
```

Acción:

```bash
# reiniciar interfaz de red
ip link set eth0 down && ip link set eth0 up
```

Mitigación adicional:

```bash
# cambiar DNS para descartar problemas
echo "nameserver 1.1.1.1" > /etc/resolv.conf
```

Rollback:

```bash
# reiniciar servicio de red
systemctl restart NetworkManager
```

Casos comunes:

- red congestionada → pérdida y latencia variable
- DNS inestable → resoluciones inconsistentes
- backend saturado → timeouts en aplicación
- firewall/IPS → bloqueos intermitentes
- conectividad WiFi → señal inestable

---

## ✅ Interpretación

- todo funciona tras repetir → intermitencia confirmada
- fallos al azar → problema de red o infraestructura
- mejora tras cambio DNS → problema externo identificado
- persistencia del problema → revisar proveedor o hardware

---

## 🐧 Variante Alpine (OpenRC + logs)

Este escenario asume systemd (Debian/Ubuntu). En Alpine Linux:

```bash
# Debian:                          # Alpine:
systemctl restart NetworkManager    rc-service networking restart
journalctl -p err -b | tail -20     logread | grep -i error | tail -20
```

> Alpine no tiene `NetworkManager` ni `journalctl`. La red se gestiona con `rc-service networking` y los logs se leen con `logread` o directamente de `/var/log/messages`.

---

## 🧑‍🏫 Modo docente

**Preguntas:** ¿Cómo reproducís un error intermitente de forma controlada? ¿Qué significa que ping funcione pero curl falle? ¿Qué capa de red descartás si dig funciona?

**Ejercicio:** Usar un loop de curl para reproducir timeouts, aplicar diagnóstico en capas, leer logs del sistema.

**Evaluación:** reproducción metódica del error, diagnóstico en capas correcto, uso de logs para confirmar causa raíz.

---

## 🔗 Referencias

- [`ping_traceroute`](../../guides/ping_traceroute.md)
- [`systemd_journalctl`](../../guides/systemd_journalctl.md)
- [`openrc`](../../guides/openrc.md) — Alpine Linux: servicios (rc-service, rc-update)
- [`busybox`](../../guides/busybox.md) — Alpine Linux: toolchain mínima (logread, dmesg)
