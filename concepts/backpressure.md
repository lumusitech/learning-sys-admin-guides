
# Backpressure — Cuando el productor va más rápido que el consumidor

## 🧠 ¿Qué es?

El **backpressure** (contrapresión) es el mecanismo por el cual un sistema le dice a quien le envía datos: "pará, no puedo procesar más, esperá". Es el control de flujo entre un productor rápido y un consumidor lento.

Si no hay backpressure, el productor sigue enviando datos que el consumidor no puede procesar. Resultado: buffers que crecen sin control, memoria agotada, OOM, pérdida de datos.

Ejemplos cotidianos:

| Sistema | Productor rápido | Consumidor lento | Backpressure |
|---------|-----------------|------------------|--------------|
| TCP | Servidor enviando datos | Cliente con poca banda | TCP window size: el receptor anuncia cuánto puede recibir |
| API HTTP | Clientes enviando requests | API procesando | HTTP 429 Too Many Requests (rate limiting) |
| Logs | Aplicación generando logs | Disco escribiendo | Buffer de syslog, drop si se llena |
| Cola de mensajes | Producers publicando | Consumers procesando | RabbitMQ/Kafka limitan producers si la cola se llena |
| Pipe en shell | `cat archivo_grande` | `grep patron` lento | El pipe tiene un buffer del kernel; si se llena, `cat` se bloquea |

---

## 🎯 ¿Por qué importa?

Sin backpressure, un sistema sobrecargado no se degrada gradualmente — **colapsa**. Es la diferencia entre "servicio lento pero funcionando" y "OOM killer mató el proceso".

Ejemplo real:

- Una API procesa 100 req/s normalmente
- Un deploy incorrecto hace que el endpoint tarde 10x más
- Ahora procesa 10 req/s pero siguen llegando 100
- La cola de requests crece → la memoria se llena → OOM
- Sin rate limiting (backpressure), la API muere completamente
- Con rate limiting, devuelve HTTP 429 y el sistema se mantiene vivo

---

## 🔑 Tipos de backpressure

### 1. Rate limiting (HTTP)

El servidor rechaza requests cuando se supera un límite:

```text
HTTP/1.1 429 Too Many Requests
Retry-After: 30
```

Patrones:

- Token bucket: permitís N requests por ventana de tiempo
- Leaky bucket: procesás a tasa constante, el exceso se descarta
- Sliding window: ventana móvil, más preciso que fixed window

### 2. TCP flow control

TCP tiene backpressure nativo: el receptor anuncia su `window size` (cuántos bytes puede recibir). Si el receptor está lento, la ventana se achica y el emisor se frena.

### 3. Backpressure en colas

| Sistema | Mecanismo |
|---------|-----------|
| RabbitMQ | QoS prefetch: el consumer dice cuántos mensajes puede procesar en paralelo |
| Kafka | El consumer hace pull, no le empujan datos |
| Redis streams | `XREADGROUP` con `COUNT` limita cuántos mensajes lee por iteración |
| Linux pipes | Buffer de 64KB en kernel; si se llena, el writer se bloquea |

### 4. Backpressure en logs

Si los logs se generan más rápido de lo que se pueden escribir:

- syslog puede droppear mensajes si el buffer está lleno
- journald tiene `RateLimitIntervalSec` y `RateLimitBurst` para limitar tasa
- Docker log driver puede configurarse con `max-size` y `max-file` para rotar

---

## ⚠️ Errores comunes

- **No implementar rate limiting** → la API muere con un pico de tráfico
- **Usar colas sin límite** → la memoria se agota si el consumer se cae
- **No monitorear la profundidad de las colas** → no sabés que hay backpressure hasta que es tarde
- **Ignorar TCP retransmisiones** → son la forma en que TCP aplica backpressure cuando hay pérdida
- **Asumir que escalar horizontalmente resuelve backpressure** → si el downstream (base de datos) es el cuello de botella, más frontends solo empeoran la presión

---

## 🧠 Modelo mental

Pensá en el backpressure como el **semáforo en la entrada de una autopista congestionada**. Si dejás entrar todos los autos sin control, la autopista colapsa y nadie avanza. El semáforo regula la entrada para que el flujo sea sostenible.

En sistemas, el backpressure es ese semáforo: rechazá temprano, fallá rápido, y mantené el sistema vivo. Un `429 Too Many Requests` es un éxito: estás protegiendo el sistema. Un OOM kill es un fracaso: no implementaste backpressure a tiempo.

---

## 🔗 Ver también

- [`concept`](capacity-and-load.md) — relación carga vs capacidad
- [`concept`](observability-vs-monitoring.md) — detectar backpressure con métricas y traces
- [`sre-fundamentals`](sre-fundamentals.md) — SLI/SLO para definir límites antes de la saturación
- [`nginx`](../guides/nginx.md) — rate limiting con `limit_req_zone`
- [`scenario`](../scenarios/web/04-api-rate-limit.md) — implementación de rate limiting
- [`scenario`](../scenarios/system/10-swap-exhaustion.md) — backpressure de memoria con swap
