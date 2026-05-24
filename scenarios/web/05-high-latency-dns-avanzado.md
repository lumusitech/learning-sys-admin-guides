# 🧩 Escenario: Alta latencia y problemas DNS avanzados

---

## 🎯 Problema

Los usuarios reportan lentitud al acceder a servicios web o APIs. Las consultas DNS funcionan, pero presentan demoras o fallos intermitentes. Es necesario determinar si la latencia está relacionada con problemas en la resolución DNS o en la red.

---

## ⚡ Quick command (SRE)

```bash
dig google.com +stats
```

---

## ✅ Salida esperada


- tiempo total de resolución (`Query time`)
- servidor DNS consultado (`SERVER`)
- respuesta válida con dirección IP

Interpretación:

- Query time alto (>100ms) → DNS lento
- SERVER incorrecto → configuración errónea
- respuesta inconsistente → problema intermitente

---

## 🧠 Diagnóstico

Los problemas de DNS avanzados suelen manifestarse como latencia alta o fallos intermitentes, no como caída total.

Patrones clave:

- Query time alto → servidor DNS lento o lejano
- resolución intermitente → problema de red o cache DNS
- diferencia entre DNS internos y externos → problema local
- múltiples reintentos → timeouts en resolución

👉 Un DNS que responde lento puede afectar todo el sistema aunque esté “funcionando”.

---

## 🛠️ Procedimiento (runbook)

### 1. Medir tiempo de resolución

```bash
dig google.com +stats
```

### 2. Comparar con otro DNS

```bash
dig google.com @8.8.8.8 +stats
```

### 3. Ver servidores configurados

```bash
cat /etc/resolv.conf
```

### 4. Probar múltiples consultas (consistencia)

```bash
for i in {1..5}; do dig google.com +stats | grep "Query time"; done
```

### 5. Verificar cache local

```bash
systemctl status systemd-resolved
```

### 6. Ver latencia de red hacia DNS

```bash
ping -c 5 8.8.8.8
```

---

## 🧯 Mitigación

Si hay latencia en DNS:

Verificar:

```bash
dig google.com +stats
ping -c 5 <dns_server>
```

Acción:

```bash
# usar otro DNS más rápido
echo "nameserver 1.1.1.1" > /etc/resolv.conf
```

Mitigación adicional:

```bash
# reiniciar cache DNS
systemctl restart systemd-resolved
```

Rollback:

```bash
# restaurar configuración previa
cp /etc/resolv.conf.bak /etc/resolv.conf
```

Casos comunes:

- DNS lento → proveedor saturado
- DNS interno mal configurado → alta latencia local
- cache DNS corrupto → respuestas inconsistentes
- red inestable → impacto indirecto en DNS

---

## ✅ Interpretación

- tiempos bajos y consistentes → DNS saludable
- tiempos altos constantes → problema estructural de DNS
- tiempos variables → inestabilidad de red o servidor
- mejora al cambiar DNS → problema externo identificado

---

## 🔗 Referencias

- [../../guides/network_dns.md](../../guides/network_dns.md)
- [../../guides/network_ping_traceroute.md](../../guides/network_ping_traceroute.md)