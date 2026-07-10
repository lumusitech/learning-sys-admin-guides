# 🐧 sys-admin-guides

[![SRE Validation](https://github.com/lumusitech/learning-sys-admin-guides/actions/workflows/sre-validate.yml/badge.svg?branch=main)](https://github.com/lumusitech/learning-sys-admin-guides/actions/workflows/sre-validate.yml)

Sistema de aprendizaje para **administración de servidores Linux y redes**: guías de referencia, laboratorio Docker y escenarios prácticos.

**Enfoque:** cada opción explicada, cada salida interpretada, uso real en troubleshooting, fallas y seguridad.

---

## 📊 En números

| Categoría | Cantidad |
|-----------|:--------:|
| 🛠️ [Guías](guides/) | 59 |
| 🚨 [Escenarios](scenarios/) | 57 |
| 🧪 [Entornos Docker](labs/) | 14 |
| 🧠 [Conceptos](concepts/) | 14 |
| 📚 [Referencias rápidas](reference/) | 12 |
| 🎯 [Proyecto integrador](scenarios/infrastructure/07-integrative-project.md) | 1 |

---

## ✅ Garantías de portabilidad

- ✅ Compatible con POSIX (sh)
- ✅ Funciona en BusyBox / Alpine Linux
- ✅ No usa flags GNU-only (grep -P, etc.)
- ✅ Sin bashismos (<(), arrays, etc.)
- ✅ CI valida cada PR automáticamente

---

## 📋 Prerrequisitos

- Terminal Linux / macOS / WSL2
- `docker --version` y `docker compose version`
- `git clone git@github.com:lumusitech/learning-sys-admin-guides.git`

---

## 🗺️ Roadmap de aprendizaje

### Fase 0 — Conceptos (30 min)

Leer [`concepts/`](concepts/):

1. `how-to-think-like-sysadmin.md` — modelo mental de troubleshooting
2. `baseline-and-anomalies.md` — cómo detectar desvíos

### Fase 1 — Base (2-3 días)

Elegí un escenario 🟢 Básico, ejecutá los comandos. Cuando veas una herramienta que no conocés, abrí su guía en [`guides/`](guides/).

> Regla: **guías on demand, no por catálogo.**

Guías para leer completas antes de arrancar:

- [`awk.md`](guides/awk.md)
- [`grep.md`](guides/grep.md)
- [`curl.md`](guides/curl.md)

### Fase 2 — Labs de calentamiento (1 día)

Levantá estos entornos en [`labs/`](labs/) en este orden:

| Lab | Aprendés |
|-----|----------|
| [`docker-compose.broken.yml`](labs/docker-compose.broken.yml) | Diagnóstico básico (nginx, DNS, disco, zombie, CPU) |
| [`docker-compose.performance.yml`](labs/docker-compose.performance.yml) | Stress y resource limits |
| [`docker-compose.network.yml`](labs/docker-compose.network.yml) | Latencia, pérdida, DNS roto |

### Fase 3 — Escenarios en espiral (el resto)

No los hagas lineales. Hacé espirales de complejidad:

1. Un escenario 🟢 Básico de cada dominio en [`scenarios/`](scenarios/)
2. Escenarios 🟡 Intermedio del dominio que más te guste
3. Escenarios 🔴 Avanzado + labs especializados (TLS, CORS, WebSocket, Docker)

### Fase 4 — Proyecto integrador (4-6 hs)

Poné todo en práctica: construí una PYME con segmentación de red, desplegá una app con Docker + nginx reverse proxy, implementá backup y monitoreo, y resolvé un incidente simulado.

👉 [`scenarios/infrastructure/07-integrative-project.md`](scenarios/infrastructure/07-integrative-project.md)

---

## 🔗 Enlaces rápidos

| Sección | Contenido |
|---------|-----------|
| [🧠 concepts/](concepts/) | Cómo pensar como sysadmin |
| [📚 reference/](reference/) | Mapas rápidos para troubleshooting |
| [🛠️ guides/](guides/) | Todas las herramientas explicadas |
| [🧪 labs/](labs/) | Entornos Docker para practicar |
| [🚨 scenarios/](scenarios/) | 57 problemas reales resueltos |
| [🎯 Proyecto integrador](scenarios/infrastructure/07-integrative-project.md) | Capstone: 5 fases, 4-6 hs |

---

## 🧰 Herramientas esenciales

Algunas herramientas no aparecen en escenarios pero son imprescindibles en el día a día:

- [`tmux`](guides/tmux.md) — multiplexor de terminales. Sesiones persistentes, división de pantalla, trabajo remoto sin perder estado al desconectarte de SSH.

---

## 🔄 Flujo de trabajo

```bash
problema → scenarios → quick command → labs → reference → guides
```

---

## ✅ Licencia

MIT
