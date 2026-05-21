# 🧪 Escenarios prácticos

Escenarios reales que combinan herramientas de las guías mediante pipes para resolver problemas concretos de administración de servidores Linux y redes.

## Estructura

```
scenarios/
├── networking/       → Problemas de red, conectividad, tráfico
├── system/           → Administración del sistema, recursos, logs
├── security/         → Amenazas, auditoría, hardening
└── web/              → Servidores web, rendimiento, errores
```

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

## Security

| Escenario | Herramientas clave |
|-----------|-------------------|
| [Detectar y bloquear IPs maliciosas](security/01-detect-and-block-malicious-ips.md) | `grep` `awk` `sort` `uniq` `comm` `iptables` |
| [Auditar SUID y permisos](security/02-suid-audit-and-file-permissions.md) | `find` `xargs` `awk` `sort` `diff` |

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
