# TODO — Backlog abierto

> Este archivo es el backlog. Lo completado vive en [`CHANGELOG.md`](CHANGELOG.md) y en el historial de git (`git log -- TODO.md`).

**Estado actual:** 66 guías · 58 escenarios · 16 labs · 14 conceptos · 12 referencias · 7 subguías Dahua

---

## 🔴 Huecos de contenido (evidencia en escenarios)

Herramientas que los escenarios usan pero no tienen guía propia. La regla del repo es "guías on demand", así que cada hueco se mide por demanda real.

| Prioridad | Guía | Escenarios que la usan | Esfuerzo |
|-----------|------|------------------------|----------|
| 🟢 Media | `guides/smartctl.md` | [raid-degradation](scenarios/infrastructure/06-raid-degradation.md), [nvr-sin-disco](scenarios/dahua/02-nvr-sin-disco.md) | 2 hrs |
| 🟢 Media | `guides/certbot.md` | [tls-expired](scenarios/infrastructure/04-tls-expired.md), [cert-rotation](scenarios/infrastructure/09-cert-rotation.md) | 1-2 hrs |

---

## 🟡 Backlog abierto

| Prioridad | Ítem | Esfuerzo |
|-----------|------|----------|
| 🟢 Media | Smoke tests de labs en CI: `docker compose config --quiet` por cada archivo, sin levantar contenedores | 1 hr |
| 🟢 Media | Fase 6 — Diagramas Mermaid de los flujos principales (postergado) | 2-3 hrs |
| 🔵 Baja | PDF/EPUB con Pandoc/MkDocs (postergado) | 2 hrs |
| 🔵 Baja | Traducción al inglés de `concepts/` (postergado) | 3 hrs |

---

## 📋 Reglas de este archivo

- Solo ítems abiertos. Al cerrar uno: se registra en `CHANGELOG.md` y se elimina de acá.
- Cada ítem debe traer evidencia (archivo:línea o escenarios que lo piden).
- No se anota lo que todavía no se ve: si no hay evidencia de demanda, no entra.

---

## Comandos de validación

```bash
pnpm lint:md        # Markdown lint
pnpm lint:sh        # ShellCheck en scripts/
pnpm validate:sre   # Validación SRE (no bashismos, no grep -P)
pnpm validate       # Todo lo anterior
```
