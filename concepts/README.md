
⬅️ [Volver al README principal](../README.md)

---

## 🧭 Navegación

- 🛠️ [guides/](../guides/) — herramientas
- 🧪 [labs/](../labs/) — práctica
- 🚨 [scenarios/](../scenarios/) — casos reales

---

# Concepts — Patrones de pensamiento de sysadmin

Guías conceptuales sobre cómo pensar como administrador de sistemas.

## 🎯 Cuándo usar esta sección

Usá `concepts/` cuando:

- no sabés por dónde empezar un problema
- querés entender cómo analizar logs
- querés identificar patrones normales vs anómalos
- necesitás establecer una baseline de rendimiento
- querés entender SLI, SLO y error budget
- buscás criterios de seguridad por capas

👉 Esto va ANTES de usar herramientas

---

👉 Esta sección es conceptual:

- NO incluye comandos
- NO incluye pasos
- SOLO explica cómo entender y razonar

Para ejecutar acciones, ver `guides/`

---

## 📚 Conceptos disponibles

| Concepto | Nivel | Descripción |
|----------|-------|-------------|
| [Cómo pensar como un sysadmin](how-to-think-like-sysadmin.md) | 🟢 Básico | Patrones normales vs anómalos, embudo diagnóstico OSI, proceso iterativo de troubleshooting, lectura de logs |
| [Baseline y detección de anomalías](baseline-and-anomalies.md) | 🟢 Básico | Cómo establecer una baseline, métricas de referencia (CPU, memoria, disco, red), detección de desvíos |
| [Fundamentos SRE](sre-fundamentals.md) | 🟡 Intermedio | SLI, SLO, error budget, monitoreo vs observabilidad, postmortem, modelos USE/RED |
| [Defensa en profundidad](defense-in-depth.md) | 🟡 Intermedio | Seguridad por capas, privilegio mínimo, aislamiento, hardening progresivo |

---

📌 Ver también:

- [`troubleshooting-patterns.md`](../reference/troubleshooting-patterns.md) — mapa rápido de diagnóstico

---

🔄 Flujo recomendado
concepts → guides → labs → scenarios
👉 entender → aprender → practicar → aplicar

---

## Relación con guías y escenarios

- [`guides/`](../guides/) → herramientas específicas
- [`scenarios/`](../scenarios/) → aplicación práctica
- `concepts/` → patrones de pensamiento transversales

La ruta ideal: primero conceptos, luego herramientas, luego escenarios.

⬅️ [Volver al README principal](../README.md)
