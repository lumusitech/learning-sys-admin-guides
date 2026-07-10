# Changelog

Todas las versiones notables de sys-admin-guides.

---

## v0.12.0 — 2026-07-10

### Sprint 4 — 8 nuevos escenarios

- `web/08-tls-handshake-failure.md` — handshake TLS roto (cipher mismatch, protocolos)
- `infrastructure/09-cert-rotation.md` — rotación de certificados Let's Encrypt
- `infrastructure/10-backup-restore-drill.md` — drill de restauración de backups
- `networking/12-asymmetric-routing.md` — ruta asimétrica, tráfico que va pero no vuelve
- `security/07-privilege-escalation-attempt.md` — detectar intento de escalación
- `system/15-config-drift.md` — detección de cambios no autorizados en config
- `web/09-load-balancer-sticky-session.md` — sesiones perdidas en load balancer
- `web/10-php-fpm-crashed.md` — 502 Bad Gateway por PHP-FPM caído

**Stats:** 59 guías · 57 escenarios · 15 conceptos · 14 labs · 6 referencias

---

## v0.11.0 — 2026-07-09

### Sprint 3 — 8 nuevas guías

- `guides/jq.md` — procesamiento JSON en CLI
- `guides/openssl.md` — diagnóstico TLS/SSL
- `guides/nc.md` — Netcat, el socket suizo
- `guides/rsync.md` — sincronización remota
- `guides/stat.md` — metadatos de archivos
- `guides/wget.md` — descargas HTTP/FTP
- `guides/tar.md` — archivado y compresión
- `guides/tr.md` — transformación de caracteres

### Sprint 2 — 8 nuevos conceptos

- `concepts/tcp-ip-model.md` — modelo TCP/IP práctico
- `concepts/idempotency.md` — idempotencia en sistemas
- `concepts/stateful-vs-stateless.md` — estado en aplicaciones
- `concepts/observability-vs-monitoring.md` — diferencia clave
- `concepts/blast-radius.md` — radio de explosión en fallas
- `concepts/capacity-and-load.md` — capacidad vs carga
- `concepts/backpressure.md` — contrapresión en sistemas
- `concepts/race-conditions.md` — condiciones de carrera

### Sprint 1 — Correcciones urgentes

- Sincronizados contadores en README.md, scenarios/README.md, AGENTS.md
- Extendido `scripts/validate_sre.sh` (3→9 patrones detectados)
- Agregado `pnpm validate:links` con lychee

---

## v0.10.0 — 2026-07-08

- `scenarios/infrastructure/08-prometheus-grafana.md` — monitoreo con Prometheus + Grafana
- `guides/kubectl.md` — diagnóstico de clusters para sysadmins
- `concepts/linux-fhs.md` — Linux FHS (/proc, /sys, /etc, /var/log)
- `concepts/post-mortem-blameless.md` — post-mortem sin culpa
- Auditoría completa del repo registrada en TODO.md (5 sprints priorizados)

---

## v0.9.0 — 2026-07-06

- Migración de `.skills/` a `.opencode/skills/`
- Inicio de integración con opencode skills

---

## v0.8.0 — 2026-07-04

- `guides/cron.md` — guía dedicada a cron
- Modo docente en todos los escenarios existentes (48 escenarios)
- CI: lychee link checker en workflow

---

## v0.7.0 — 2026-07-02

- Corrección masiva de links rotos (35 referencias `../` → `./`)
- `guides/kill.md` — nueva guía
- `guides/fuser.md` — nueva guía
- `guides/tmux.md` — nuevas guía

---

## v0.6.0 — 2026-06-30

- Infraestructura Dahua completa (cámaras IP, NVR)
- `labs/docker-compose.dahua.yml` — laboratorio Dahua
- `scenarios/dahua/` — 3 escenarios Dahua

---

## v0.5.0 — 2026-06-25

- Proyecto integrador: `scenarios/infrastructure/07-integrative-project.md`
- `labs/docker-compose.integrative.yml` — 7 servicios

---

## v0.4.0 — 2026-06-20

- `labs/docker-compose.web-cors.yml` — laboratorio CORS
- `labs/docker-compose.web-websocket.yml` — laboratorio WebSocket
- `labs/docker-compose.docker.yml` — laboratorio Docker troubleshooting
- `labs/docker-compose.tls.yml` — laboratorio TLS
- `labs/docker-compose.monitoring.yml` — Prometheus + Grafana

---

## v0.3.0 — 2026-06-15

- Laboratorios base: broken, performance, network, security, cron, from-scratch
- `concepts/`: how-to-think-like-sysadmin, baseline-and-anomalies
- `reference/`: http-status-codes, troubleshooting-patterns

---

## v0.2.0 — 2026-06-10

- Primeros 30+ escenarios prácticos en system, networking, security, web
- Primeras 20+ guías de herramientas
- Plantilla de escenario (`scenarios/_TEMPLATE.md`)
- CI: validación SRE básica

---

## v0.1.0 — 2026-06-05

- Estructura inicial del repositorio
- Guías iniciales: awk, grep, sed, curl, ps, ss, ip, df, du, free, top, lsof, journalctl, systemctl
- Escenarios iniciales: system (01-05), networking (01-04), security (01-03), web (01-04)
- `labs/docker-compose.yml` — Docker Compose base
- `scripts/validate_sre.sh` — validación de portabilidad POSIX
- CI: GitHub Actions con markdownlint y shellcheck

---

## v0.0.1 — 2026-06-01

- Initial commit: proyecto inicial con estructura de directorios
