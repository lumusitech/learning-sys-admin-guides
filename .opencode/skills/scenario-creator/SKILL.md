---
name: scenario-creator
description: >-
  Crea escenarios SRE con plantilla estándar para el repo learning-sys-admin-guides.
---

# Skill: Scenario Creator

## Rol

Creás escenarios SRE para el repo `learning-sys-admin-guides` siguiendo el estándar del proyecto. Cada escenario debe pasar `pnpm lint:md` sin errores.

---

## Plantilla completa

```md
# 🧩 Escenario: <título claro y accionable>

**Dominio:** networking / system / security / web / infrastructure
**Nivel:** 🟢 Básico | 🟡 Intermedio | 🔴 Avanzado
**Herramientas:** `<tool1>`, `<tool2>`, `<tool3>`
**Archivos:** `labs/<archivo1>`, `labs/<archivo2>`

---

## 🎯 Problema

## ⚡ Quick command (SRE)

## ✅ Salida esperada

Interpretación:

## 🧠 Diagnóstico

## 🛠️ Procedimiento (runbook)

### 1. ...

### 2. ...

### 3. ...

## 🧯 Mitigación

Verificar:

Acción:

Rollback:

## ✅ Interpretación

## 🐧 Variante Alpine (OpenRC) — solo si usa systemctl/journalctl/apt/ufw/bc

## 🔗 Referencias
```

---

## Reglas

1. No usar `### Explicación paso a paso`.
2. Quick command debe ser robusto desde la primera versión, no un placeholder.
3. Los patrones clave (salida esperada, interpretación, diagnóstico) deben estar desde la primera versión.
4. Incluir variante Alpine solo si el escenario usa `systemctl`, `journalctl`, `apt`, `ufw`, `fallocate`, `bc`, `watch` o `column`.
5. Referencias en formato estándar: `` [`nombre`](ruta/nombre.md) — descripción breve ``

### Referencia de variantes Alpine

| Variante | Cuándo usarla | Comandos Alpine |
|----------|--------------|-----------------|
| A | Solo `systemctl` | `rc-service <svc> restart` |
| B | `systemctl` + `journalctl` | `rc-service` + `logread` |
| C | `apt` + `ufw` + `systemctl` | `apk add`, `iptables`, `rc-service` |
| D | `watch`, `column`, `bc` | `apk add procps util-linux bc` |
