# 🧪 Escenarios prácticos

Escenarios reales que combinan herramientas de las guías mediante pipes para resolver problemas concretos de administración de servidores Linux y redes.

## Estructura

```
scenarios/
├── networking/       → Problemas de red, conectividad, tráfico
├── system/           → Administración del sistema, recursos, logs
├── security/         → Amenazas, auditoría, hardening
├── web/              → Servidores web, rendimiento, errores
└── infrastructure/   → Migración, infraestructura PYME, disaster recovery
```

## Laboratorio Docker

Usa los entornos Docker en [`labs/`](../labs/) para practicar. Hay **5 compose files** según el tipo de práctica:

| Archivo | Para qué |
|---------|----------|
| `docker-compose.yml` | Servidores funcionando (SSH, web, DB, monitoreo) |
| `docker-compose.broken.yml` | Servicios rotos que debes diagnosticar |
| `docker-compose.from-scratch.yml` | Servidores desde cero (instalar todo) |
| `docker-compose.network.yml` | Problemas de red (latencia, pérdida, DNS) |
| `docker-compose.security.yml` | Servicios vulnerables para hardening |

```bash
cd labs
docker compose -f docker-compose.network.yml up -d   # Ej: escenarios de red
```

Ver [`labs/README.md`](../labs/README.md) para instrucciones detalladas de cada uno.

## Networking

| Escenario | Herramientas clave |
|-----------|-------------------|
| [Detectar SSH brute force](networking/01-detect-ssh-brute-force.md) | `grep` `awk` `sort` `uniq` `iptables` |
| [Analizar tráfico web](networking/02-analyze-web-traffic-patterns.md) | `awk` `sort` `uniq` `grep` |
| [Detectar escaneo de puertos](networking/03-port-scan-detection.md) | `grep` `awk` `sort` `uniq` `iptables` |

## System

| Escenario | Herramientas clave |
|-----------|-------------------|
| [Procesos y recursos](system/01-top-processes-and-resources.md) | `ps` `sort` `awk` `grep` |
| [Logs y errores](system/02-log-analysis-and-error-tracking.md) | `grep` `awk` `sort` `uniq` `sed` |
| [Provisionamiento inicial](system/03-new-server-provisioning.md) | `ssh` `ufw` `iptables` `fail2ban` `systemctl` |

## Security

| Escenario | Herramientas clave |
|-----------|-------------------|
| [Detectar y bloquear IPs maliciosas](security/01-detect-and-block-malicious-ips.md) | `grep` `awk` `sort` `uniq` `comm` `iptables` |
| [Auditar SUID y permisos](security/02-suid-audit-and-file-permissions.md) | `find` `xargs` `awk` `sort` `diff` |

## Infrastructure

| Escenario | Herramientas clave |
|-----------|-------------------|
| [Migrar a producción](infrastructure/01-migrate-to-production.md) | `ssh` `rsync` `nginx` `docker` `mysql` `curl` |
| [Construir PYME desde cero](infrastructure/02-build-pyme-infrastructure.md) | `vlan` `iptables` `samba` `nfs` `dnsmasq` `nginx` `restic` |
| [Disaster recovery](infrastructure/03-disaster-recovery.md) | `restic` `rsync` `nginx` `mysql` `rclone` `systemctl` |

## Web

| Escenario | Herramientas clave |
|-----------|-------------------|
| [Rendimiento y errores](web/01-performance-and-error-analysis.md) | `awk` `grep` `sort` `uniq` `bc` |

## Cómo usar

Cada escenario incluye:

1. **Problema real** descrito al inicio
2. **Pipeline completo** listo para copiar y pegar
3. **Explicación paso a paso** de qué hace cada herramienta
4. **Salida esperada** para validar el resultado
5. **Variantes** con diferentes enfoques
6. **Interpretación** de los resultados
7. **Enlaces** a las guías relevantes

```bash
# Ejecutar un escenario con datos de ejemplo
cd ../labs
bash ../scenarios/networking/01-detect-ssh-brute-force.md  # (o copiar los comandos)
```
