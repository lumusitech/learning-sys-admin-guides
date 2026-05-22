# 🐧 sys-admin-guides

[![SRE Validation](https://github.com/lumusitech/learning-sys-admin-guides/actions/workflows/sre-validate.yml/badge.svg?branch=main)](https://github.com/lumusitech/learning-sys-admin-guides/actions/workflows/sre-validate.yml)

Guías de referencia + laboratorio Docker + escenarios prácticos para **administración de servidores Linux y redes**.

**Enfoque:** cada opción explicada, cada salida interpretada, uso real en troubleshooting, fallas y seguridad.

**Quality Gates (CI):** [SRE Validation](.github/workflows/sre-validate.yml) — bloquea regresiones de portabilidad (`grep -P`, `\K`, `<(`).

> ✅ *"Aprendo herramienta por herramienta, pero practico cómo se usan en conjunto."*

---

## ✅ Garantías de portabilidad

- ✅ Compatible con POSIX (sh)
- ✅ Funciona en BusyBox / Alpine Linux
- ✅ No usa flags GNU-only (grep -P, etc.)
- ✅ Sin bashismos (<(), arrays, etc.)
- ✅ Pipelines reproducibles en entornos mínimos

## 🚀 Empezar rápido

```bash
git clone https://github.com/lumusitech/learning-sys-admin-guides.git
cd learning-sys-admin-guides
```

Modos de uso:
- aprendizaje → guides → labs → scenarios
- producción → scenarios → labs → guides
- referencia → abrir guía y copiar comando

Ruta rápida:
1. problema → scenarios
2. correr quick command
3. validar con labs
4. volver a guides si hace falta

---

## 🧱 Estructura

### `guides/` — guías por herramienta

Incluye herramientas de texto/datos, redes, sistema e infraestructura.

### `labs/` — archivos de práctica + laboratorio Docker

Logs de ejemplo y 5 compose files para practicar sin riesgo.

### `scenarios/` — problemas reales que combinan herramientas

Incidentes por dominio: **networking**, **system**, **security**, **web**, **infrastructure**.

### `concepts/` — patrones de pensamiento de sysadmin

Cómo pensar como administrador de sistemas.

---

## ✅ Licencia

MIT
