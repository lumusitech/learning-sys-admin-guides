# 🧩 Escenario: <TÍTULO CORTO Y ACCIONABLE>

**Dominio:** networking / system / security / web / infrastructure
**Nivel:** 🟢 Básico | 🟡 Intermedio | 🔴 Avanzado
**Herramientas:** `<tool1>`, `<tool2>`, `<tool3>`
**Archivos:** `labs/<archivo1>`, `labs/<archivo2>`

---

## 🎯 Problema

Qué problema real se resuelve en este escenario (2–3 ítems).

Identificar IPs atacantes a partir de logs
Generar un reporte accionable con mitigación

---

## 🧠 Contexto (problema real)

Descripción del síntoma y el impacto.

- Servidor lento, errores, tráfico sospechoso, logs anómalos
- Impacto: degradación, riesgo, caída del servicio

---

## ✅ Datos de entrada

- **Producción:** ruta real (ej. `/var/log/auth.log`)
- **Práctica:** archivo del repo (ej. `labs/auth.log`)

---

## ⚡ Quick run

Un comando único para resolver el problema rápido.

```bash
cat labs/<archivo>.log | <pipeline>
```

---

## 🔍 Paso a paso

Explicación de cada etapa del pipeline.

1. `grep ...` → filtra
2. `awk ...` → extrae
3. `sort | uniq -c | sort -rn` → agrupa y ordena
4. `head` → top-N

---

## ✅ Salida esperada

```
IP         INTENTOS
10.0.0.5   150
```

- Si aparece X → significa Y
- Si NO aparece nada → revisar Z

---

## 🧯 Mitigación

Qué acción tomar en producción.

- Bloquear IP
- Reiniciar servicio
- Aplicar rate limit

⚠️ Incluir advertencia y **rollback**.

---

## 🛡️ Prevención

Cómo evitar que vuelva a pasar.

- Hardening
- Monitoreo
- Configuración

---

## 🧪 Variantes

Distintas formas de resolver el mismo problema.

- Tiempo real
- Por usuario
- Por ventana temporal

---

## 🧑‍🏫 Modo docente (opcional)

**Preguntas:** ¿Qué significa X? ¿Qué patrón ves?
**Ejercicio:** resolver X con pipeline.
**Evaluación:** pipeline correcto, interpretación correcta, mitigación segura.

---

## 🔗 Referencias

- [`guides/<tool>.md`](../../guides/<tool>.md)
- [`labs/README.md`](../../labs/README.md)
