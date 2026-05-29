# Skill: Reference Creator

## Rol

Creás archivos de referencia rápida para el repo `sys-admin-guides` en `reference/`. Estos archivos son material de consulta inmediata durante troubleshooting: tablas, mapas, cheatsheets.

No son tutoriales ni guías profundas. Son **ayuda memoria** para cuando ya sabés qué estás buscando.

Cada referencia debe pasar `pnpm lint:md` sin errores.

---

## Tipo A: Tabla de referencia

Para códigos, estados, señales o cualquier información tabular.

### Plantilla

``````md
# <Título> — Referencia rápida

<contexto de una línea: qué contiene y para qué sirve>

---

## 📊 Tabla principal

| Columna 1 | Columna 2 | Columna 3 |
|-----------|-----------|-----------|
| valor     | descripción | significado en troubleshooting |
| valor     | descripción | significado en troubleshooting |

---

## 🚨 Casos problema

| Señal | ¿Es problema? | Acción |
|-------|--------------|--------|
| síntoma | Sí / No / Depende | qué hacer |

---

## 🔍 Cómo usarlo en diagnóstico

```bash
comandos prácticos para aplicar la referencia
```

---

## 🔗 Ver también

- [`herramienta`](../guides/herramienta.md) — descripción breve
- [`scenario`](../scenarios/dominio/NN-nombre.md) — descripción breve
``````

---

## Tipo B: Mapa / Cheatsheet

Para tablas problema→herramienta, síntoma→causa, o resúmenes cross-categoría.

### Plantilla

``````md
# <Título> — <subtítulo>

<contexto de una línea>

---

## 🔥 <Categoría 1> (elegir emoji según tema)

Emojis disponibles por categoría:

- `🔤` genérico | `🔥` CPU | `💾` memoria | `💽` disco | `🌐` red | `🔒` seguridad | `👁️` logs | `🔁` servicios

| Síntoma / Problema | Qué puede ser | Comando / Acción |
|--------------------|--------------|------------------|
| síntoma            | causa posible | comando |

---

## <Categoría 2> (mismo emoji que la categoría anterior)

---

## 🔗 Ver también

- [`herramienta`](../guides/herramienta.md) — descripción breve
- [`otra-referencia`](otra-referencia.md) — descripción breve
``````

---

## Naming

```txt
reference/kebab-name.md
```

Ejemplos:

```txt
reference/troubleshooting-patterns.md
reference/http-status-codes.md
reference/tcp-connection-states.md
reference/signals-table.md
reference/symptom-to-tool.md
```

Usar kebab-case. Sin números. Sin emojis en el filename.

---

## Reglas de contenido

### Lo que SÍ va en reference/

- tablas de código/estado/señal con interpretación
- mapas problema→herramienta y síntoma→herramienta
- cheatsheets de diagnóstico rápido
- resúmenes de información que se consulta en incidentes
- comandos prácticos para aplicar la referencia

### Lo que NO va en reference/

- explicaciones extensas de modelos mentales (van en `concepts/`)
- procedimientos paso a paso (van en `scenarios/`)
- guías completas de herramientas (van en `guides/`)
- logs de ejemplo o datos de práctica (van en `labs/`)

---

## Formato de referencias

```md
- [`nombre`](../../ruta/al/archivo.md) — descripción breve
```

Ejemplos:

```md
- [`curl`](../guides/curl.md) — cómo inspeccionar respuestas HTTP
- [`troubleshooting-patterns`](troubleshooting-patterns.md) — problema → herramienta
- [`scenarios/web/02-nginx-5xx-errors.md`](../scenarios/web/02-nginx-5xx-errors.md) — troubleshooting de errores 5xx
```

---

## Checklist antes de commit

```txt
[ ] título con # y descripción de una línea
[ ] tabla principal clara con columnas bien definidas
[ ] contexto de troubleshooting (¿cuándo usar esto?)
[ ] comandos prácticos de aplicación
[ ] casos problema destacados si aplica
[ ] referencias en formato: [`name`](../../path/name.md) — descripción
[ ] sin links vacíos
[ ] headers con emoji estándar: 📊, 🚨, 🔍, 🔗 (Tipo A) o según categoría (Tipo B)
[ ] pnpm lint:md → 0 errores
```

---

## Relación con el resto del repo

```txt
reference/  → consulta rápida durante incidentes (¿qué era esto?)
guides/     → estudio de herramientas (¿cómo funciona?)
concepts/   → modelos mentales (¿cómo pensar?)
scenarios/  → práctica guiada (¿cómo se resuelve?)
```
