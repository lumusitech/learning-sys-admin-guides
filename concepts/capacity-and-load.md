
# Capacidad y carga — Cuándo y cómo escalar

## 🧠 ¿Qué es?

La **capacidad** es la cantidad máxima de trabajo que un sistema puede manejar antes de degradarse. La **carga** es la cantidad de trabajo que realmente está recibiendo.

La relación entre ambas es lo que determina el rendimiento:

```text
carga < capacidad × 0.7  → sistema holgado, margen para picos
carga > capacidad × 0.85 → sistema tensionado, riesgo de degradación
carga > capacidad        → sistema saturado, colas creciendo, latencia disparada
```

Little's Law relaciona estos conceptos matemáticamente:

```text
L = λ × W

Donde:
  L = número promedio de requests en el sistema (concurrency)
  λ = tasa de llegada de requests (throughput)
  W = tiempo promedio de procesamiento (latencia)
```

Si λ sube y W se mantiene, L crece. Si L llega al límite del sistema, W explota.

---

## 🎯 ¿Por qué importa?

Sin entender capacidad y carga, tomás decisiones de infraestructura a ciegas:

- Agregás más servidores sin saber si el cuello de botella es CPU, memoria o I/O
- No sabés cuándo hacer capacity planning (comprar más hardware / instancias)
- No podés predecir cuándo el sistema va a degradarse
- Respondés a incidentes en lugar de anticiparlos

La capacidad no es estática: varía con el tipo de carga, la hora del día, los deploys, y las configuraciones del sistema.

---

## 📊 Tipos de carga

| Tipo de carga | Ejemplo | Métrica clave |
|---------------|---------|---------------|
| CPU-bound | Procesamiento de imágenes, encriptación, compresión | %CPU, load average |
| Memory-bound | Caché grande, datos en memoria, memory leaks | %mem, swap usage, OOM |
| I/O-bound | Base de datos, logs, archivos | iowait, await, throughput |
| Network-bound | API servers, proxies, streaming | bandwidth, connections, pps |

Un sistema puede estar saturado en un recurso y holgado en otro. Agregar CPU a un sistema I/O-bound no resuelve nada.

---

## 🔑 Capacity planning

El capacity planning responde: ¿cuánto va a crecer la carga y cuándo necesito más capacidad?

### Pasos básicos

1. **Medir carga actual**: requests/s, conexiones activas, uso de CPU/memoria/disco
2. **Identificar la tendencia**: ¿crece lineal? ¿estacional? ¿picos?
3. **Encontrar el recurso limitante**: ¿qué se satura primero?
4. **Proyectar crecimiento**: ¿cuánto va a crecer en 3, 6, 12 meses?
5. **Planificar expansión**: ¿vertical (más CPU/RAM) u horizontal (más instancias)?

### Señales de que necesitás escalar YA

- CPU > 80% sostenido en horas pico
- Swap > 0 de forma persistente
- I/O await > 10ms en SSD
- Colas de requests creciendo sin límite
- Timeouts en clientes (empiezan a fallar requests)

---

## 📐 Escalado vertical vs horizontal

| Aspecto | Vertical (más grande) | Horizontal (más instancias) |
|---------|----------------------|---------------------------|
| Límite | El hardware más grande disponible | Teóricamente infinito |
| Complejidad | Baja (mismo servidor) | Alta (load balancer, consistencia) |
| Costo | Lineal hasta el tope | Lineal + overhead de coordinación |
| SPOF | Sí (un solo server) | No (si está bien diseñado) |
| Stateful | Fácil (datos locales) | Difícil (requiere particionar o replicar) |
| Stateless | Posible | Ideal |

---

## 🧠 Modelo mental

Pensá en la capacidad como **una autopista con N carriles**. La carga son los autos que entran. Mientras haya carriles libres, los autos fluyen a velocidad normal. Cuando todos los carriles están ocupados, se forma un embotellamiento y la velocidad de todos cae a cero.

Little's Law te dice exactamente cuántos autos hay en la autopista en función de cuántos entran por minuto y cuánto tardan en salir. Si querés reducir el tráfico sin agregar carriles, necesitás que los autos salgan más rápido.

---

## 🔗 Ver también

- [`concept`](backpressure.md) — qué hacer cuando la carga supera la capacidad
- [`concept`](stateful-vs-stateless.md) — implicaciones de estado en el escalado
- [`baseline-and-anomalies`](baseline-and-anomalies.md) — métricas de referencia para detectar saturación
- [`sre-fundamentals`](sre-fundamentals.md) — SLI/SLO para definir cuándo intervenir
- [`top`](../guides/top.md) — monitoreo de carga de CPU y memoria
- [`iostat`](../guides/iostat.md) — monitoreo de carga de I/O
- [`vmstat`](../guides/vmstat.md) — monitoreo integral de recursos
- [`scenario`](../scenarios/system/04-high-cpu-runaway-process.md) — saturación de CPU
- [`scenario`](../scenarios/system/07-high-io-wait.md) — saturación de I/O
