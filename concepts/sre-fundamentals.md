
# Fundamentos SRE — Guía conceptual

## 🧠 ¿Qué es SRE?

Site Reliability Engineering (SRE) es una disciplina que aplica principios de ingeniería de software a la operación de sistemas de producción. El objetivo es mantener servicios confiables de forma escalable, sin depender de intervención manual constante.

No se trata de "operar servidores", sino de **diseñar sistemas que se operen solos**.

---

## 🎯 ¿Por qué importa?

- permite tomar decisiones basadas en datos, no en intuición
- define claramente cuándo un servicio está "roto" vs "degradado"
- el error budget da margen para innovar sin comprometer la confiabilidad
- separa monitoreo (qué pasa) de observabilidad (por qué pasa)

---

## 📊 Conceptos clave

### SLI (Service Level Indicator)

Métrica cuantitativa que mide un aspecto del nivel de servicio.

Ejemplos:

| SLI | Qué mide | Cómo se calcula |
|-----|----------|-----------------|
| Latencia | Tiempo de respuesta | Percentil 99 de requests exitosos |
| Disponibilidad | % de tiempo servidor respondiendo | Requests exitosos / requests totales |
| Tasa de errores | % de requests fallidos | HTTP 5xx / requests totales |
| Throughput | Requests por segundo | Requests / segundo |

Un SLI debe ser:

- medible objetivamente
- relevante para la experiencia del usuario
- estable en el tiempo

### SLO (Service Level Objective)

Valor objetivo para un SLI. Es el límite que define si el servicio está funcionando aceptablemente.

Ejemplos:

| SLI | SLO |
|-----|-----|
| Latencia P99 | < 200ms |
| Disponibilidad | > 99.9% |
| Tasa de errores | < 0.1% |
| Throughput mínimo | > 1.000 req/s |

El SLO no es "lo ideal", es **el mínimo aceptable**. Por debajo de eso hay que actuar.

### Error Budget

Es el margen de error permitido antes de incumplir el SLO. Se calcula como `100% - SLO`.

Ejemplo: si el SLO es 99.9%, el error budget es 0.1% del tiempo (≈ 8.7 horas al año).

El error budget se puede "gastar":

- en deploys riesgosos
- en experimentos
- en cambios de infraestructura

Cuando el error budget se agota, se congela todo cambio hasta recuperar margen.

> El error budget no es una excusa para tener outages. Es una herramienta para decidir cuándo arriesgar y cuándo ser conservador.

---

## 📊 Pirámide de monitoreo (USE / RED)

Dos modelos complementarios para elegir qué medir:

### USE (Utilization, Saturation, Errors)

Para recursos del sistema (CPU, memoria, disco, red):

| Métrica | Pregunta |
|---------|----------|
| Utilization | ¿Qué % del recurso está ocupado? |
| Saturation | ¿Hay trabajo esperando? (colas) |
| Errors | ¿Hay errores en el recurso? |

Se aplica a: CPU (`%util`, `load`, errores de machine check), memoria (`%used`, `swap`, OOM), disco (`%util`, `avgqu-sz`, `I/O errors`), red (`%util`, `drop`, `collisions`).

### RED (Rate, Errors, Duration)

Para servicios (microservicios, APIs, bases de datos):

| Métrica | Pregunta |
|---------|----------|
| Rate | ¿Cuántos requests por segundo? |
| Errors | ¿Cuántos fallan? |
| Duration | ¿Cuánto tardan? |

Se aplica a: cualquier servicio que reciba requests (nginx, PostgreSQL, Redis, API propia).

> USE mide la salud de la máquina. RED mide la salud del servicio.

---

## 👁️ Monitoreo vs Observabilidad

| | Monitoreo | Observabilidad |
|--|-----------|----------------|
| Qué es | Conocer el estado del sistema con métricas predefinidas | Poder hacer preguntas nuevas sin instrumentación nueva |
| Enfoque | Paneles, alertas, dashboards | Trazas, logs estructurados, métricas explorables |
| Pregunta | ¿Está funcionando? | ¿Por qué no está funcionando? |
| Herramientas típicas | Prometheus, Nagios, Grafana | OpenTelemetry, Jaeger, Honeycomb |

El monitoreo dice **qué** está mal. La observabilidad permite entender **por qué**.

Un sistema observable permite:

- correlacionar un error con el request exacto
- seguir una traza a través de múltiples servicios
- explorar datos sin tener que escribir código nuevo

---

## 🔄 Incident Management

### Postmortem sin blame

Después de un incidente, el objetivo no es encontrar un culpable, sino entender qué falló en el sistema para evitar que vuelva a ocurrir.

Un buen postmortem incluye:

1. **Resumen**: qué pasó y qué impacto tuvo
2. **Línea de tiempo**: cada acción y observación, con timestamp
3. **Causa raíz**: la falla técnica que inició el incidente
4. **Contribuyentes**: condiciones que agravaron el impacto
5. **Acciones**: qué se va a cambiar para prevenir recurrencia
6. **Métrica de éxito**: cómo saber si la acción funcionó

> Si un postmortem termina con "fulano cometió un error", no servirá para mejorar el sistema.

### Severidad de incidentes

| Nivel | Impacto | Ejemplo |
|-------|---------|---------|
| SEV-1 | Servicio caído, múltiples usuarios afectados | DB primaria inaccesible |
| SEV-2 | Servicio degradado, experiencia afectada | Latencia 10x de lo normal |
| SEV-3 | Problema menor, sin impacto visible | Error 500 en endpoint poco usado |
| SEV-4 | Cosmético o interno | Logs ruidosos, alerta mal configurada |

---

## 🧠 Modelo mental

SRE no es un rol, es una forma de pensar:

- todo sistema tiene un límite — conocelo antes de que te lo muestre
- la perfección no existe — el error budget te permite decidir cuándo está bien "suficientemente bueno"
- automatizá lo repetitivo — si lo hiciste dos veces, la tercera debe ser un script
- el sistema siempre falla — preparate para la falla, no para evitarla

---

## 🔗 Ver también

- [`how-to-think-like-sysadmin.md`](how-to-think-like-sysadmin.md) — patrones de diagnóstico
- [`baseline-and-anomalies.md`](baseline-and-anomalies.md) — cómo establecer una baseline
- [`troubleshooting-patterns`](../reference/troubleshooting-patterns.md) — mapa rápido de diagnóstico
