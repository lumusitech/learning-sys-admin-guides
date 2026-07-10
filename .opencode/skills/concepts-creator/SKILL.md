---
name: concepts-creator
description: >-
  Crea documentos conceptuales (modelos mentales) para el repo learning-sys-admin-guides.
---

# Skill: Concepts Creator

## Rol

Creás archivos conceptuales para el repo `sys-admin-guides` en `concepts/`. Estos archivos explican modelos mentales, patrones de pensamiento y fundamentos teóricos. No incluyen comandos ni procedimientos paso a paso.

Cada concepto debe pasar `pnpm lint:md` sin errores.

---

## Plantilla completa

```md
# <Título> — <subtítulo breve>

## 🧠 ¿Qué es?

Definición clara y corta del concepto.

Explicar:

- qué problema resuelve el concepto
- en qué contexto aplica

## 🎯 ¿Por qué importa?

Consecuencias de ignorarlo en la práctica del sysadmin.

## <sección de contenido>

Estructurar según el concepto:

- analogías, ejemplos visuales o diagramas en texto
- comparación con conceptos similares (no es lo mismo que X)
- aplicación práctica o ejemplo realista
- errores comunes asociados al modelo mental

## 🧠 Modelo mental

Un párrafo que resuma el concepto como si se lo explicaras a un colega en 30 segundos.

Debe incluir la frase: "Pensá en esto como..."

## 🔗 Ver también

- [`guide`](../../guides/<ruta>.md) — qué comando implementa este concepto
- [`scenario`](../../scenarios/<ruta>.md) — escenario que lo aplica
```

---

## Reglas

1. No incluir comandos ni procedimientos. Para eso están `guides/` y `scenarios/`.
2. Los conceptos deben pasar `pnpm lint:md` sin errores.
3. Links en formato estándar.
