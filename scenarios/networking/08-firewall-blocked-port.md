# 🧩 Escenario: Puerto bloqueado por firewall

---

## 🎯 Problema

Un servicio no es accesible desde la red o desde otro servidor. Aunque el servicio parece estar corriendo, las conexiones fallan. Es necesario determinar si el puerto está bloqueado por un firewall.

---

## ⚡ Quick command (SRE)

```bash
ss -tuln && iptables -L -n | grep -E "DROP|REJECT"
```

## ✅ Salida esperada

- listado de puertos en escucha
- reglas de firewall aplicadas
- posibles coincidencias con bloqueos (DROP, REJECT)

Interpretación:

- puerto no aparece → servicio no está escuchando
- puerto presente pero inaccesible → posible bloqueo de firewall
- reglas DROP/REJECT activas → tráfico bloqueado

---

## 🧠 Diagnóstico

El problema puede estar en diferentes capas: servicio, firewall local o red.

Patrones clave:

- puerto cerrado → servicio no iniciado o mal configurado
- puerto abierto pero inaccesible → firewall bloqueando tráfico
- reglas restrictivas → política de seguridad activa
- acceso local OK pero remoto falla → bloqueo en firewall o red
- conexión rechazada inmediatamente → firewall o servicio cerrando puerto

👉 Que un servicio esté corriendo no garantiza que sea accesible: el firewall puede bloquearlo.

---

## 🛠️ Procedimiento (runbook)

### 1. Verificar puertos en escucha

```bash
ss -tuln
```

### 2. Verificar servicio asociado

```bash
systemctl status <servicio>
```

### 3. Probar acceso local

```bash
nc -zv localhost <puerto>
```

### 4. Probar acceso remoto

```bash
nc -zv <host> <puerto>
```

### 5. Revisar reglas del firewall

```bash
# iptables (tradicional)
iptables -L -n

# ufw (si está en uso)
sudo ufw status
```

### 6. Ver políticas por defecto

```bash
iptables -L | grep policy
```

---

## 🧯 Mitigación

Si el firewall bloquea el puerto:

Verificar:

```bash
iptables -L -n
ss -tuln
```

Acción:

```bash
# permitir puerto específico (temporal)
iptables -A INPUT -p tcp --dport <puerto> -j ACCEPT
```

Mitigación adicional:

```bash
# guardar reglas (según sistema)
iptables-save > /etc/iptables.rules
```

Rollback:

```bash
# eliminar regla agregada
iptables -D INPUT -p tcp --dport <puerto> -j ACCEPT
```

Casos comunes:

- servicio escuchando pero bloqueado → firewall restrictivo
- puerto incorrecto → error en configuración
- reglas duplicadas/confusas → mala gestión de firewall
- entorno cloud → reglas externas (security groups)

---

## ✅ Interpretación

- puerto accesible tras abrir firewall → bloqueo confirmado
- sigue inaccesible → problema en red o servicio
- acceso solo local → firewall bloquea tráfico externo
- problema recurrente → revisar política de seguridad

---

## 🐧 Variante Alpine (OpenRC)

Este escenario asume systemd (Debian/Ubuntu). En Alpine Linux:

### Servicios

```bash
# Debian:                          # Alpine:
systemctl status <servicio>         rc-service <servicio> status
```

### Firewall

Debian/Ubuntu puede usar `ufw`. Alpine usa `iptables` directamente (ya viene instalado):

```bash
# Debian:                          # Alpine:
sudo ufw status                     iptables -L -v -n
```

---

## 🧑‍🏫 Modo docente

**Preguntas:** ¿Cómo verificás que un servicio está escuchando en un puerto? ¿Qué comando probás primero para testear conectividad local? ¿Cómo listás las reglas de iptables activas?

**Ejercicio:** Verificar si un puerto está bloqueado por firewall: test local con nc, test remoto, listar reglas iptables.

**Evaluación:** diagnóstico metódico (local -> remoto -> firewall), identificación de la regla bloqueante, propuesta de apertura controlada.

---

## 🔗 Referencias

- [`ip_ss`](../../guides/ip_ss.md)
- [`iptables`](../../guides/iptables.md)
- [`openrc`](../../guides/openrc.md) — Alpine Linux: servicios (rc-service, rc-update)
