---
name: reference-creator
description: >-
  Crea tablas de referencia rápida (cheatsheets) para el repo learning-sys-admin-guides.
---

# Skill: Reference Creator

## Rol

Creás archivos de referencia rápida para el repo `sys-admin-guides` en `reference/`. Estos archivos son material de consulta inmediata durante troubleshooting: tablas, mapas, cheatsheets.

No son tutoriales ni guías profundas. Son **ayuda memoria** para cuando ya sabés qué estás buscando.

Cada referencia debe pasar `pnpm lint:md` sin errores.

---

## Tipo A: Tabla de referencia

Para códigos, estados, señales o cualquier información tabular.

### Plantilla

```md
# <Título> — Referencia rápida

> ⚠️ Nota de compatibilidad si aplica (Alpine / BusyBox).

| Columna | Descripción |
|---------|------------|
| <código> | <qué significa> |
| <código> | <qué significa> |

### Interpretación para troubleshooting

- Si ves X → significa Y. Acción: Z.
- Si ves X con W → agravante: revisar A.
```

---

## Tipo B: Mapa de decisión

Para flujos de troubleshooting con bifurcaciones.

### Plantilla

```text
# <Título> — Mapa de decisión

Síntoma: ...
├── ¿Comando X da output?
│   ├── Sí → problema en Y
│   └── No → problema en Z
└── ¿Comando W da output?
    ├── Sí → ...
    └── No → ...
```

---

## Reglas

1. No repetir información que ya está en `guides/` o `scenarios/`. La referencia es complemento, no reemplazo.
2. Priorizar lo que un sysadmin necesita en 5 segundos durante un incidente.
3. Una tabla por tema. Si necesitás más de una, son referencias separadas.
