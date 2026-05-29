# Skill: Concepts Creator

## Rol

Creás archivos conceptuales para el repo `sys-admin-guides` en `concepts/`. Estos archivos explican modelos mentales, patrones de pensamiento y fundamentos teóricos. No incluyen comandos ni procedimientos paso a paso.

Cada concepto debe pasar `pnpm lint:md` sin errores.

---

## Plantilla completa

``````md
# <Título> — <subtítulo breve>

## 🧠 ¿Qué es?

Definición clara y corta del concepto.

Explicar:

- qué problema resuelve
- por qué existe
- cuándo aplica

---

## 🎯 ¿Por qué importa?

Beneficios concretos de entender este concepto:

- beneficio 1
- beneficio 2
- beneficio 3

---

## <secciones de contenido> (usar emoji según el caso)

Secciones en orden lógico, usando `##` para secciones principales y `###` para subsecciones.

Cada sección debe responder una pregunta concreta.

Usar tablas, listas, diagramas de texto cuando ayuden a la claridad.

Emojis disponibles para secciones de contenido:

- `📊` — tablas de métricas, patrones, datos de referencia
- `📈` — tendencias, baseline, evolución
- `🔍` — análisis, diagnóstico, investigación
- `📜` — logs, documentación
- `🔄` — procesos, ciclos, flujos
- `🚨` — alertas, incidentes, seguridad
- `⚠️` — errores comunes, advertencias

---

## 🧠 Modelo mental

Frase o párrafo que resuma la esencia del concepto en una idea memorable.

---

## 🔗 Ver también

- [`concepto-relacionado`](concepto-relacionado.md) — descripción breve
- [`herramienta`](../guides/herramienta.md) — descripción breve
- [`scenario`](../scenarios/dominio/NN-nombre.md) — descripción breve
``````

---

## Naming

```txt
concepts/kebab-name.md
```

Ejemplos:

```txt
concepts/how-to-think-like-sysadmin.md
concepts/baseline-and-anomalies.md
concepts/sre-fundamentals.md
concepts/defense-in-depth.md
```

Usar kebab-case. Sin números. Sin emojis en el filename.

---

## Reglas de contenido

### Lo que SÍ va en concepts/

- modelos mentales y formas de pensar
- taxonomías y clasificaciones
- fundamentos teóricos (SRE, seguridad, redes)
- relaciones entre conceptos
- preguntas guía para el diagnóstico

### Lo que NO va en concepts/

- comandos y pipelines concretos
- procedimientos paso a paso
- tablas de opciones de herramientas
- logs de ejemplo
- configuraciones de servicios

Para comandos y procedimientos, referir a `guides/` o `scenarios/` en la sección `## 🔗 Ver también`.

---

## Formato de referencias

```md
- [`nombre`](../../ruta/al/archivo.md) — descripción breve
```

Ejemplos:

```md
- [`vmstat`](../guides/vmstat.md) — CPU, memoria, I/O en un comando
- [`how-to-think-like-sysadmin.md`](how-to-think-like-sysadmin.md) — patrones de diagnóstico
- [`scenarios/system/04-high-cpu-runaway-process.md`](../scenarios/system/04-high-cpu-runaway-process.md) — proceso runaway
```

---

## Checklist antes de commit

```txt
[ ] título con ## 🧠 o emoji coherente
[ ] sección ¿Qué es? con definición clara
[ ] sección ¿Por qué importa? con beneficios concretos
[ ] contenido conceptual, sin comandos sueltos
[ ] tablas bien formateadas (alineación con |---|)
[ ] modelo mental al final (frase memorable)
[ ] referencias en formato: [`name`](../../path/name.md) — descripción
[ ] sin links vacíos
[ ] headers con emoji estándar: 🧠, 🎯, 📊, 📈, 🔍, 📜, 🔄, 🚨, ⚠️, 🔗
[ ] pnpm lint:md → 0 errores
```

---

## Relación con guides y scenarios

```txt
concepts/ → modelos mentales (¿cómo pensar?)
guides/   → herramientas (¿qué comando usar?)
scenarios/ → aplicación (¿cómo resolver un problema real?)
```
