# 🧩 Escenario: <TÍTULO CORTO Y ACCIONABLE>

**Dominio:** <networking | system | security | web | infrastructure>
**Nivel:** 🟢 Básico | 🟡 Intermedio | 🔴 Avanzado
**Herramientas:** `<tool1>`, `<tool2>`, `<tool3>`
**Archivos de práctica:** `labs/<archivo1>`, `labs/<archivo2>`
**Salida:** reporte, comando de mitigación, checklist, etc.

---

## 🎯 Objetivo

Qué vas a poder hacer al terminar (en 1–3 bullets).

- Identificar IPs atacantes a partir de logs
- Generar un reporte reproducible y una acción de mitigación segura

---

## 🧠 Contexto (problema real)

Describe el síntoma + el impacto.

- Síntoma: CPU alta / timeouts / conexiones fallidas / errores 5xx
- Impacto: degradación / riesgo / caída del servicio

---

## ✅ Datos de entrada

- **Producción**: rutas reales (ej. `/var/log/auth.log`)
- **Práctica**: archivos del repo (ej. `labs/auth.log`)

---

## ⚡ Quick run (modo "copiar y pegar")

> Un pipeline único para obtener "lo mínimo útil" rápido.

```bash
# (ejemplo)
cat labs/<archivo>.log | <pipeline>
```

---

## 🔍 Paso a paso (explicación del pipeline)

Explica cada etapa del pipe (1–2 líneas por etapa):

1. `grep ...` → qué filtra
2. `awk ...` → qué extrae/calcula
3. `sort | uniq -c | sort -rn` → cómo agrega y ordena
4. `head` → top-N

---

## ✅ Salida esperada (cómo validar que salió bien)

Incluye ejemplos y criterios:

- "Si ves X, significa Y"
- "Si NO aparece nada, revisá Z"

---

## 🧯 Mitigación (acción segura)

Qué harías en producción, con advertencias:

- bloquear IP temporalmente
- rate limit
- fail2ban (si aplica)
- checklist mínimo para no romper servicios

⚠️ Incluí siempre un paso de **rollback**.

---

## 🛡️ Prevención (hardening / mejoras)

Qué se cambia para evitar que se repita.

- configuración
- políticas
- monitoreo
- alertas

---

## 🧪 Variantes

Variantes útiles para distintos enfoques:

- por usuario
- por ventana de tiempo
- por geografía / ASN (si aplica)
- en tiempo real (`tail -f`)

---

## 🧑‍🏫 (Opcional) Modo docente

### Preguntas guía

- ¿Qué indica un aumento de X?
- ¿Qué falsos positivos existen?

### Ejercicio

- "Encontrá las top 3 IPs y justificá si bloqueás o no"

### Criterios de evaluación (rúbrica)

- pipeline correcto
- interpretación correcta
- mitigación segura

---

## 🔗 Referencias

- **Guías relacionadas**: `guides/<tool>.md`
- **Escenarios relacionados**: `scenarios/<...>.md`
