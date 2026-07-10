
# Idempotencia — Operaciones seguras y repetibles

## 🧠 ¿Qué es?

Una operación es **idempotente** si ejecutarla una vez o cien veces produce el mismo resultado. La segunda ejecución no debería causar un cambio adicional ni un error.

Pensá en prender una luz con un interruptor de palanca: si ya está prendida, volver a accionarlo la apaga — **no es idempotente**. Pero si usás un interruptor con dos botones (ON fijo, OFF fijo), presionar ON cuando ya está prendida no hace nada — **es idempotente**.

En sistemas, los ejemplos clásicos:

| Operación idempotente | Operación no idempotente |
|-----------------------|--------------------------|
| `mkdir -p /opt/app` (no falla si existe) | `mkdir /opt/app` (falla si existe) |
| `DELETE /api/users/42` (si no existe, 404 OK) | `POST /api/users` (crea uno nuevo cada vez) |
| `systemctl restart nginx` (idéntico cada vez) | `kill -9 <PID>` (el PID puede cambiar) |
| Scripts con ansible/puppet (declarativo) | Scripts de bash puro (ejecutivos) |

---

## 🎯 ¿Por qué importa?

La idempotencia es la diferencia entre un script de deploy que podés ejecutar 10 veces sin miedo y uno que rompe todo en la segunda ejecución.

Sin idempotencia:

- un retry automático puede duplicar registros en la base de datos
- un script de provisionamiento falla si el servidor está parcialmente configurado
- una migración de datos crea conflictos si se ejecuta dos veces
- es imposible automatizar deploys porque cada paso asume "estado limpio"

Con idempotencia:

- podés reintentar operaciones sin miedo
- la infraestructura como código converge al estado deseado desde cualquier punto de partida
- las migraciones son seguras
- el rollback es trivial: volvés a ejecutar el estado anterior

---

## 🛠️ Cómo lograr idempotencia

### Patrones para scripts de shell

```text
# NO idempotente
echo "127.0.0.1 myapp.local" >> /etc/hosts

# IDEMPOTENTE
grep -q "myapp.local" /etc/hosts || echo "127.0.0.1 myapp.local" >> /etc/hosts
```

### Patrones para APIs REST

| Método | ¿Idempotente? | Por qué |
|--------|:------------:|---------|
| GET | Sí | Solo lee, no modifica |
| PUT | Sí | Reemplazo completo, mismo resultado |
| DELETE | Sí | Si ya no existe, 404 OK |
| POST | No | Cada POST crea un nuevo recurso |
| PATCH | Depende | Si el patch es absoluto, sí; si es relativo, no |

### En infraestructura como código

La idempotencia es el fundamento de herramientas como Ansible, Terraform y Puppet: declarás el estado deseado y la herramienta calcula la diferencia entre el estado actual y el deseado, aplicando solo los cambios necesarios.

---

## ⚠️ Lo que NO es idempotente

- Operaciones con timestamps (`date >> log` — cada ejecución agrega una línea diferente)
- Comandos que dependen de estado externo (`mail -s "alerta" admin@empresa.com` — envía un mail cada vez)
- `/dev/random` operations (producen salida diferente cada vez)
- `docker build` sin caché (puede producir imágenes diferentes si cambian las dependencias upstream)

---

## 🧠 Modelo mental

Pensá en la idempotencia como un **interruptor de luz con dos botones separados** (ON fijo, OFF fijo), no como una palanca que invierte el estado.

Cada operación que diseñás deberías poder ejecutarla 100 veces y que el sistema termine exactamente en el mismo estado que si la hubieras ejecutado una sola vez. Si no podés garantizar eso, no podés automatizar con confianza.

---

## 🔗 Ver también

- [`concept`](stateful-vs-stateless.md) — estado en memoria vs estado en base de datos
- [`concept`](blast-radius.md) — cómo limitar el impacto de una operación no idempotente
- [`ssh`](../guides/ssh.md) — automatización segura con SSH
- [`cron`](../guides/cron.md) — tareas programadas (deben ser idempotentes para retries seguros)
- [`scenario`](../scenarios/infrastructure/01-migrate-to-production.md) — migración idempotente a producción
