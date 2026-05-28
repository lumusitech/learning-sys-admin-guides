# 🧩 Escenario: Fallo en resolución DNS

---

## 🎯 Problema

Los usuarios no pueden acceder a sitios web o servicios por nombre de dominio (ej: api.empresa.com), aunque la conectividad de red parece estar activa. Es necesario determinar si el problema se debe a fallos en la resolución DNS.

---

## ⚡ Quick command (SRE)

```bash
nslookup google.com && dig google.com
```

---

## ✅ Salida esperada

- resolución de nombre a dirección IP
- respuesta desde un servidor DNS
- tiempo de respuesta bajo

Interpretación:

- sin respuesta → fallo en DNS
- respuesta lenta → problema de red o servidor DNS
- dominio no resuelto → error de configuración o dominio inválido

---

## 🧠 Diagnóstico

Los problemas de DNS pueden ocurrir en múltiples niveles: configuración local, red o servidores externos.
Patrones clave:

- `Temporary failure in name resolution` → DNS inaccesible
- `NXDOMAIN` → dominio no existe
- retrasos en respuesta → servidor DNS lento o saturado
- resolución intermitente → problemas de conectividad o cache
- funciona por IP pero no por nombre → problema exclusivo de DNS

👉 Sin DNS funcional, los servicios parecen “caídos” aunque estén operativos.

---

## 🛠️ Procedimiento (runbook)

### 1. Verificar resolución básica

```bash
nslookup google.com
```

### 2. Probar con dig

```bash
dig google.com
```

### 3. Verificar configuración DNS local

```bash
cat /etc/resolv.conf
```

### 4. Probar conectividad por IP

```bash
ping -c 2 8.8.8.8
```

### 5. Probar DNS específico

```bash
dig @8.8.8.8 google.com

## o menos potente
nslookup google.com 8.8.8.8
```

### 6. Verificar servicios locales DNS (si aplica)

```bash
systemctl status systemd-resolved
```

---

## 🧯 Mitigación

Si la resolución DNS falla:

Verificar:

```bash
cat /etc/resolv.conf
ping -c 2 8.8.8.8
```

Acción:

```bash
# configuración temporal (puede sobrescribirse)
echo "nameserver 8.8.8.8" > /etc/resolv.conf
```

Reiniciar servicio DNS local:

```bash
systemctl restart systemd-resolved
```

Rollback:

```bash
# restaurar configuración anterior
cp /etc/resolv.conf.bak /etc/resolv.conf
```

Casos comunes:

- DNS mal configurado → resolv.conf incorrecto
- servidor DNS caído → dependencia externa
- firewall bloqueando DNS → puerto 53 cerrado
- cache corrupto → reinicio necesario

---

## ✅ Interpretación

- resolución vuelve a funcionar → problema era de configuración DNS
- funciona por IP pero no por nombre → problema exclusivo de DNS
- sigue fallando → problema de red o proveedor DNS
- fallo intermitente → inestabilidad del servidor DNS

---

## 🐧 Variante Alpine (OpenRC)

Este escenario asume systemd (Debian/Ubuntu). En Alpine Linux:

```bash
# Debian:                          # Alpine:
systemctl status systemd-resolved    cat /etc/resolv.conf; rc-service networking status
systemctl restart systemd-resolved   rc-service networking restart
```

> Alpine no tiene `systemd-resolved`. La resolución DNS se configura directamente en `/etc/resolv.conf`.

---

## 🔗 Referencias

- [`network_dns`](../../guides/network_dns.md)
- [`ip_ss`](../../guides/ip_ss.md)
- [`openrc`](../../guides/openrc.md) — Alpine Linux: servicios (rc-service, rc-update)
