⬅️ [Volver al README principal](../README.md)

---

## 🧭 Navegación

- 🧠 [concepts/](../concepts/) — pensar como sysadmin
- 🛠️ [guides/](../guides/) — herramientas
- 🧪 [labs/](../labs/) — práctica

---

# 🧪 Escenarios prácticos

49 escenarios reales que combinan herramientas de las guías para resolver problemas concretos de administración de servidores Linux y redes.

---

## 🎯 Cuándo usar esta sección

Usá scenarios/ cuando:

- tenés un problema real para resolver
- necesitás un resultado rápido (modo SRE)
- querés practicar troubleshooting con casos reales
- querés ver cómo se combinan herramientas en contexto

👉 Esto es el mundo real, donde aplicás todo lo aprendido

---

## 🔄 Flujo recomendado

```text
concepts → guides → labs → scenarios
entender → aprender → practicar → aplicar
```

---

## 📂 Escenarios por dominio

### [📹 dahua/](dahua/) — 3 escenarios

Cámaras IP, NVR, configuración masiva.

Niveles: 🟡 Intermedio · 🔴 Avanzado

### [🖥️ system/](system/) — 14 escenarios

Procesos, memoria, disco, I/O, logs, cron, provisioning, context switches, fork bombs, zombies, Docker troubleshooting.

Niveles: 🟢 Básico · 🟡 Intermedio · 🔴 Avanzado

### [🌐 networking/](networking/) — 11 escenarios

SSH brute force, port scans, DNS, latencia, timeouts, firewalls, ARP spoofing, DHCP exhaustion, MTU fragmentation.

Niveles: 🟢 Básico · 🟡 Intermedio · 🔴 Avanzado

### [🔒 security/](security/) — 6 escenarios

IPs maliciosas, SUID/permisos, claves SSH no autorizadas, cron sospechoso, procesos anómalos, manipulación de logs.

Niveles: 🟡 Intermedio · 🔴 Avanzado

### [🌍 web/](web/) — 7 escenarios

Rendimiento, errores 5xx, slow SQL, rate limiting, 502 bad gateway, CORS, WebSocket timeout.

Niveles: 🟡 Intermedio · 🔴 Avanzado

### [🏗️ infrastructure/](infrastructure/) — 8 escenarios

Migración a producción, infraestructura PYME, disaster recovery, TLS expirado, NFS stale mount, RAID degradation, proyecto integrador, monitoreo con Prometheus y Grafana.

Niveles: 🟡 Intermedio · 🔴 Avanzado

---

## 🧪 Laboratorio Docker

Usá los entornos Docker en [`labs/`](../labs/) para practicar. Hay **14 entornos** según el tipo de práctica:

| Archivo | Para qué |
|---------|----------|
| `docker-compose.yml` | Servidores funcionando (SSH, web, DB, monitoreo) |
| `docker-compose.broken.yml` | Servicios rotos para diagnosticar |
| `docker-compose.from-scratch.yml` | Servidores desde cero (instalar todo) |
| `docker-compose.network.yml` | Problemas de red (latencia, pérdida, DNS) |
| `docker-compose.security.yml` | Servicios vulnerables para hardening |
| `docker-compose.performance.yml` | Stress de CPU, memoria, I/O, swap |
| `docker-compose.cron.yml` | Cron jobs con fallos |
| `docker-compose.tls.yml` | TLS expirado y renovación |
| `docker-compose.web-cors.yml` | CORS bloqueado (frontend + API) |
| `docker-compose.web-websocket.yml` | WebSocket timeout |
| `docker-compose.docker.yml` | Docker crash loop, OOM, resource limits |
| `docker-compose.dahua.yml` | Cámaras Dahua simuladas (API CGI, RTSP, NVR) |
| `docker-compose.integrative.yml` | Proyecto integrador (PYME completa) |
| `docker-compose.monitoring.yml` | Prometheus + node_exporter + Grafana para monitoreo |

```bash
cd labs
docker compose -f docker-compose.network.yml up -d   # Ej: escenarios de red
```

Ver [`labs/README.md`](../labs/README.md) para instrucciones detalladas de cada uno.

---

## Cómo usar

Cada escenario incluye:

1. **Problema real** descrito al inicio
2. **Quick command (SRE)** para diagnóstico inmediato
3. **Procedimiento paso a paso** con comandos listos para copiar
4. **Salida esperada** para validar el resultado
5. **Mitigación** con verificar / acción / rollback
6. **Interpretación** de los resultados
7. **Variante Alpine** si aplica
8. **Enlaces** a las guías relevantes

---

> 💡 **Variante Alpine:** Los escenarios que listan `systemctl`, `journalctl`, `ufw`, `apt` o `bc` asumen Debian/Ubuntu.
> Cada uno incluye un bloque **🐧 Variante Alpine** con los comandos equivalentes para contenedores Docker mínimos (`apk`, `rc-service`, `logread`, `iptables`).

⬅️ [Volver al README principal](../README.md)
