
# Observabilidad vs monitoreo — Ver vs entender

## 🧠 ¿Qué es?

El **monitoreo** te dice **qué está pasando**. La **observabilidad** te permite entender **por qué está pasando** lo que no esperabas.

Son complementarios, no opuestos:

| Monitoreo | Observabilidad |
|-----------|----------------|
| Métricas predefinidas (CPU, memoria, requests/s) | Capacidad de hacer preguntas nuevas sin deployar código |
| Dashboards y alertas | Logs estructurados, traces distribuidos, métricas de alta cardinalidad |
| "¿El sistema está sano?" | "¿Por qué este usuario específico recibe 500?" |
| Conocido: sabés qué medir | Desconocido: el sistema te muestra lo que no sabías que necesitabas |
| Reactivo: alerta → respondés | Investigativo: explorás para entender |

Un sistema **monitoreado** te avisa cuando algo se sale de lo normal. Un sistema **observable** te permite rastrear una request desde el frontend hasta la base de datos y ver dónde falló.

---

## 🎯 ¿Por qué importa?

La mayoría de los incidentes graves ocurren por condiciones que **nunca fueron monitoreadas** porque nadie anticipó que podían fallar. La observabilidad cubre ese vacío.

Sin observabilidad:

- un 500 error es una caja negra — no sabés si fue el load balancer, la API o la base de datos
- diagnosticar requiere SSH a 5 servidores a mano
- solo detectás lo que ya conocés (known unknowns)
- cada nuevo síntoma requiere un nuevo dashboard

Con observabilidad:

- seguís una request completa con un trace ID
- correlacionás logs, métricas y traces en un solo lugar
- descubrís patrones inesperados (unknown unknowns)
- reducís el tiempo de diagnóstico de horas a minutos

---

## 🔍 Los tres pilares

### 1. Métricas (monitoreo clásico)

Datos numéricos agregados en el tiempo:

- `http_requests_total`, `node_cpu_seconds_total`
- Bajo costo de almacenamiento, altamente agregables
- Responden: ¿está subiendo la latencia? ¿cuántas requests hay?

### 2. Logs

Registros de eventos con timestamp y contexto:

- `{"timestamp": "...", "level": "error", "trace_id": "abc123", "msg": "db timeout"}`
- Alto costo de almacenamiento, difíciles de agregar
- Responden: ¿qué pasó exactamente en este request?

### 3. Traces distribuidos

Seguimiento de una request a través de múltiples servicios:

- Un trace_id viaja con la request: frontend → API → worker → database
- Cada salto (span) registra duración, errores, metadata
- Responden: ¿dónde pasó el cuello de botella? ¿qué servicio introdujo la latencia?

### Los tres juntos

```text
Métrica alerta: "latencia p99 > 2 segundos"
Trace muestra:    "el span de database duró 1.8 segundos"
Log confirma:     "connection pool exhausted, 50 active connections"
```

---

## 📊 Dónde aplica cada uno

| Señal | Costo | Cuándo usarla |
|-------|-------|---------------|
| Métricas | Bajo | Health checks, dashboards, alertas, SLIs |
| Logs | Alto | Debugging post-mortem, auditoría, cumplimiento |
| Traces | Medio | Diagnóstico de latencia, dependencias entre servicios |

---

## 🧠 Modelo mental

Pensá en el monitoreo como el **tablero del auto** (velocidad, temperatura, combustible). Te dice que algo está mal (temperatura subiendo) pero no por qué.

Pensá en la observabilidad como el **manual de mecánico + scanner OBD2** que te deja ver el código de error, el historial de sensores y el registro de eventos para diagnosticar la causa raíz.

El monitoreo te despierta. La observabilidad te da las respuestas.

---

## 🔗 Ver también

- [`concept`](sre-fundamentals.md) — SLI, SLO, error budget
- [`concept`](baseline-and-anomalies.md) — establecer baselines con métricas
- [`scenario`](../scenarios/infrastructure/08-prometheus-grafana.md) — monitoreo con Prometheus y Grafana
- [`scenario`](../scenarios/web/01-performance-and-error-analysis.md) — análisis de rendimiento
- [`scenario`](../scenarios/system/02-log-analysis-and-error-tracking.md) — análisis de logs
- [`systemd_journalctl`](../guides/systemd_journalctl.md) — logs del sistema
