# TODO — Plan de mejoras

Plan basado en la revisión externa del repositorio. Organizado en fases atómicas, priorizadas por impacto y esfuerzo.

---

## Fase 0 — Links rotos y correcciones urgentes

> Esfuerzo: ~30 min | Prioridad: 🔴 Crítica

### 0.1 — Links con `../` incorrecto en guías hermanas

35 links en 10 guías usan `../filename.md` para referenciar guías en el mismo directorio (`guides/`). El `../` resuelve a la raíz del repo, no a `guides/`. Corregir a `./filename.md` o simplemente `filename.md`.

| Archivo | Links rotos |
|---------|-------------|
| `guides/apk.md` | `../busybox.md`, `../openrc.md`, `../production_server.md` |
| `guides/busybox.md` | `../apk.md`, `../openrc.md`, `../systemd_journalctl.md` |
| `guides/df.md` | `../du.md`, `../find.md`, `../storage_backup.md` |
| `guides/du.md` | `../df.md`, `../find.md`, `../storage_backup.md` |
| `guides/free.md` | `../ps.md`, `../systemd_journalctl.md`, `../top.md`, `../vmstat.md` |
| `guides/iostat.md` | `../production_server.md`, `../ps.md`, `../top.md`, `../vmstat.md` |
| `guides/lsof.md` | `../fuser.md`, `../ip_ss.md`, `../ps.md` |
| `guides/openrc.md` | `../apk.md`, `../busybox.md`, `../systemd_journalctl.md` |
| `guides/ps.md` | `../awk.md`, `../grep.md`, `../kill.md`, `../sort.md`, `../systemd_journalctl.md`, `../top.md` |
| `guides/vmstat.md` | `../free.md`, `../iostat.md`, `../ps.md`, `../top.md` |

### 0.2 — Links a archivos inexistentes

| Archivo | Link roto | Reemplazo |
|---------|-----------|-----------|
| `guides/lsof.md` | `../fuser.md` | Eliminar o crear `fuser.md` |
| `guides/ps.md` | `../kill.md` | Eliminar o crear `kill.md` |
| `guides/tmux.md` | `../scenarios/infrastructure/03-new-server-provisioning.md` | Corregir a `01-migrate-to-production.md` |

### 0.3 — `guides/README.md` desactualizado

- Dice "37 guías" pero hay 39 (sin contar README).
- Faltan `tmux.md` y `redirections.md` en las tablas de índice.

---

## Fase 1 — Quick wins en guías existentes

> Esfuerzo: ~2 hrs | Prioridad: 🟡 Alta

### 1.1 — `guides/awk.md`

- Añadir sección sobre `gawk --sandbox` para entornos restringidos.
- Añadir ejemplo de `PROCINFO` para detectar la implementación (gawk vs mawk vs nawk) en runtime.

### 1.2 — `guides/grep.md`

- Añadir opción `-T` (tab alignment con `--with-filename`).
- Reforzar énfasis en `LANG=C` para acelerar búsquedas (ya se menciona en rendimiento, subir de perfil).
- Añadir ejemplo de `--exclude-dir=node_modules` en uno-liners.

### 1.3 — `guides/tcpdump.md`

- Añadir opción `-z` (compresión de archivos rotados con gzip).
- Añadir ejemplo de filtro BPF por VLAN: `vlan 100`.
- Añadir referencia a `tshark` para decodificación de protocolos compleja.

### 1.4 — `guides/nmap.md`

- Añadir `-sV --version-intensity <0-9>` para controlar agresividad en detección de versiones.
- Añadir ejemplo combinado estándar de auditoría: `nmap -sV -sC -O <target>`.
- Añadir nota sobre `--reason` (por qué nmap clasificó un puerto en ese estado).
- Añadir ejemplos de output parsing con `grep`/`awk` sobre salida `-oG` (grepable).

### 1.5 — `guides/iptables.md`

- Añadir `iptables-apply` para aplicar reglas con rollback automático.
- Añadir nota sobre `ipset` para manejar listas grandes de IPs.

---

## Fase 2 — Mejoras en scenarios y concepts

> Esfuerzo: ~2 hrs | Prioridad: 🟡 Alta

### 2.1 — `scenarios/networking/01-detect-ssh-brute-force.md`

- Añadir alternativa con `awk` puro para monitoreo en tiempo real (reemplazar `sort | uniq -c` que requiere datos agrupados).
- Añadir ejemplo con `fail2ban` como mitigación real (no solo `iptables` directo).

### 2.2 — `scenarios/web/01-performance-and-error-analysis.md`

- Añadir ejemplo de correlación temporal: "los 5xx aumentaron cuando se desplegó X".

### 2.3 — `concepts/how-to-think-like-sysadmin.md`

- Añadir nota: "Los umbrales son referenciales y dependen del hardware; ajustar según baseline del sistema."
- Añadir caso de estudio narrado paso a paso (síntoma → diagnóstico → resolución) aplicando el modelo mental del documento.

---

## Fase 3 — Nueva guía: `guides/nftables.md` ✅ COMPLETADA

> Esfuerzo: ~3 hrs | Prioridad: 🟡 Alta | **PR: #50**

- Guía completa de `nftables` siguiendo la plantilla del skill `sysadmin-guides-skill.md`.
- Tabla de migración `iptables` → `nftables` por tipo de regla.
- Ejemplos prácticos: firewall básico, NAT, rate limiting, persistencia.
- Cubrir diferencias: `nft` vs `iptables` (tablas vs cadenas, familias de protocolo, sets named).
- Portabilidad: disponible en Debian 12+, Ubuntu 22.04+, RHEL 9+, Alpine (kernel).
- Conectar con `scenarios/` existentes que usan `iptables`.

---

## Fase 4 — Nueva guía: `guides/docker.md` ✅ COMPLETADA

> Esfuerzo: ~3 hrs | Prioridad: 🟡 Alta | **PR: #51**

- Guía de Docker para sysadmin (no desarrollo).
- Enfoque: diagnóstico de contenedores, no construcción de imágenes.
- Quick command: `docker ps -a`, `docker logs`, `docker stats`.
- Cubrir: crash loops, OOM, resource limits, networking, volúmenes.
- Modelo mental: Docker como gestor de procesos en entorno aislado.
- Conectar con `scenarios/system/14-docker-troubleshooting.md` y labs existentes.
- Portabilidad: comandos esenciales que funcionan en cualquier instalación Docker.

---

## Fase 5 — Nueva guía: `guides/systemd.md` ✅ COMPLETADA

> Esfuerzo: ~2 hrs | Prioridad: 🟢 Media | **PR: #52**

**Decisión tomada**: Crear `guides/systemd.md` nuevo en vez de expandir `systemd_journalctl.md`.

**Razón**: `systemd_journalctl.md` está enfocado en gestión de logs con journalctl. Systemd como init system merece su propia guía completa.

**Contenido de `guides/systemd.md`**:

- Unidades: service, socket, device, mount, automount, timer, path, slice
- Comandos: systemctl (start, stop, restart, enable, disable, status)
- Estados de unidades: active, inactive, failed, activating
- Targets: multi-user.target, graphical.target, rescue.target
- Timers: reemplazo moderno de cron
- Resource control: CPUQuota, MemoryMax, IOWeight
- Dependencias entre unidades: Requires, Wants, After, Before
- Override de configuración: systemctl edit, drop-in files
- Análisis de arranque: systemd-analyze, blame
- Journalctl integrado: logs por unidad

---

## Fase 6 — Diagramas Mermaid (postergado)

> Esfuerzo: ~1 hr | Prioridad: 🔵 Baja

- Convertir diagramas ASCII art (ej: flujo de iptables en `guides/iptables.md`) a Mermaid.
- **Razón para postergar**: ASCII art funciona en terminal y visores de texto plano. Mermaid solo renderiza en GitHub. Si se hace, mantener ambos formatos.
- **ROI**: Bajo. El diagrama ASCII actual ya es claro.

---

## Dependencias entre fases

```text
Fase 0 (links rotos) → sin dependencias, ejecutar primero
Fase 1 (quick wins) → sin dependencias, paralelizable con Fase 0, 2
Fase 2 (scenarios) → sin dependencias
Fase 3 (nftables) → ideal después de Fase 1.5 (iptables mejorada)
Fase 4 (docker) → sin dependencias
Fase 5 (systemd) → sin dependencias, archivo nuevo
Fase 6 (postergado) → sin fecha
```

## Comandos de validación

```bash
pnpm lint:md        # Markdown lint
pnpm lint:sh        # ShellCheck en scripts/
pnpm validate:sre   # Validación SRE (no bashismos, no grep -P)
pnpm validate       # Todo lo anterior
```
