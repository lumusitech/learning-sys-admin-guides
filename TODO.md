# TODO — Backlog abierto

> Este archivo es el backlog. Lo completado vive en [`CHANGELOG.md`](CHANGELOG.md) y en el historial de git (`git log -- TODO.md`).

**Estado actual:** 65 guías · 58 escenarios · 16 labs · 14 conceptos · 12 referencias · 7 subguías Dahua

---

## 🔴 Huecos de contenido (evidencia en escenarios)

Herramientas que los escenarios usan y que todavía no tienen guía propia. Cada hueco se mide por demanda real.

Sin huecos abiertos: `diff`, `sysctl`, `smartctl` y `certbot` ya tienen guía.

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
