
# Stateful vs Stateless — El modelo del estado en sistemas

## 🧠 ¿Qué es?

La diferencia entre **stateful** (con estado) y **stateless** (sin estado) determina cómo un sistema recuerda información entre requests o reinicios.

**Stateful**: el sistema mantiene información de sesiones anteriores. Cada interacción depende del historial.

- HTTP con cookies de sesión: el servidor recuerda quién sos
- TCP mantiene números de secuencia y ventanas de congestión
- Una base de datos que persiste datos en disco
- Un filesystem con journal
- Un servidor que acumula caché en memoria

**Stateless**: cada interacción es independiente. No hay memoria entre requests.

- HTTP sin cookies: cada request es autónomo
- UDP: cada datagrama se procesa sin contexto de los anteriores
- Un servidor REST puro (sin sesiones ni caché)
- Un worker queue que procesa jobs uno a uno sin estado compartido

La mayoría de los sistemas reales son una mezcla: la aplicación es stateless pero la base de datos es stateful.

---

## 🎯 ¿Por qué importa?

Confundir stateful con stateless causa los peores incidentes:

- **Escalar stateless** es trivial: agregás más instancias detrás de un load balancer
- **Escalar stateful** requiere particionamiento, replicación, consistencia

Un sysadmin que no entiende esta diferencia:

- agrega instancias a un servicio stateful sin consistencia → datos inconsistentes
- reinicia un servidor stateful sin drenar sesiones → usuarios pierden su sesión
- mueve un contenedor stateful a otro nodo → pierde el estado acumulado
- asume que un balanceador round-robin funciona para servicios con sesiones → la sesión se rompe a mitad de camino

---

## 📊 Comparación práctica

| Aspecto | Stateful | Stateless |
|---------|----------|-----------|
| Escalado horizontal | Difícil (particionar o replicar) | Fácil (más instancias) |
| Reinicio | Peligroso (perder estado) | Indoloro |
| Migración entre nodos | Requiere mover datos | Inmediata |
| Ejemplos | DB, filesystem, sesiones HTTP | API REST pura, workers, proxies |
| Rollback | Complejo (datos ya modificados) | Simple (cambiar binario) |

---

## 🔑 Aplicaciones prácticas

### Servicios web

```text
Stateful:  el servidor guarda la sesión del usuario en memoria → sticky sessions necesarias
Stateless: el cliente envía un JWT con cada request → cualquier servidor puede atender
```

### Contenedores

```text
Stateful:  docker run -v /data:/var/lib/mysql mysql     → el volumen persiste el estado
Stateless: docker run --rm nginx                         → desaparece sin dejar rastro
```

### Redes

```text
Stateful:  iptables con conexiones trackeadas (conntrack) → recuerda el estado de cada flujo
Stateless: iptables sin conntrack → cada paquete se evalúa individualmente
```

---

## 🧠 Modelo mental

Pensá en stateful como un **restaurante con reservas**: el restaurante sabe quién sos, qué mesa tenés y qué pediste antes. Si cerrás y reabrís, toda esa información se pierde.

Pensá en stateless como un **food truck**: cada cliente es un nuevo pedido sin historia. Podés poner 10 food trucks iguales porque ninguno depende del anterior.

Un buen sysadmin diseña la mayor cantidad posible de componentes como stateless y aísla el estado en pocos lugares bien conocidos (base de datos, volumen persistente, cola de mensajes).

---

## 🔗 Ver también

- [`concept`](idempotency.md) — operaciones repetibles sin efectos laterales
- [`concept`](blast-radius.md) — limitar el impacto de fallos en componentes stateful
- [`docker`](../guides/docker.md) — volúmenes persistentes vs contenedores efímeros
- [`storage_backup`](../guides/storage_backup.md) — backup de estado persistente
- [`iptables`](../guides/iptables.md) — firewall stateful (conntrack)
- [`scenario`](../scenarios/web/01-performance-and-error-analysis.md) — diagnóstico de cuellos de botella stateful vs stateless
