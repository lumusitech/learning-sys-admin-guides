
# Blast radius — Limitá el daño de cada cambio

## 🧠 ¿Qué es?

El **blast radius** (radio de explosión) es el alcance máximo del daño que puede causar un cambio, una falla o un error humano. Cuanto más pequeño es el blast radius, más seguro es operar.

Todo sysadmin debería diseñar sistemas para que cuando algo falle, **falle en el menor alcance posible**. Si un solo comando puede tirar abajo todo el datacenter, el blast radius es todo el datacenter. Si solo afecta a un pod, el blast radius es un pod.

El **change management** es la disciplina que controla cómo, cuándo y con qué alcance se aplican los cambios, justamente para minimizar el blast radius.

---

## 🎯 ¿Por qué importa?

El 80% de los incidentes graves en producción son causados por cambios humanos (deploy, config, migración). Si cada cambio afecta a todo el sistema, cada cambio es un riesgo existencial.

Sin control de blast radius:

- `rm -rf /` borra todo el sistema porque no hay namespace o container
- Un deploy de base de datos afecta a todos los tenants porque no hay particionamiento
- Una regla de iptables incorrecta bloquea todo el tráfico porque se aplica globalmente
- Un script de mantenimiento consume toda la CPU porque no tiene cgroups

Con control de blast radius:

- Borrás un archivo en un container → solo afecta ese container
- Deploy de feature flag → solo afecta al 1% de usuarios
- Regla de iptables por namespace → afecta un solo segmento
- Script con CPU limit → no puede saturar el host

---

## 🛡️ Técnicas para reducir el blast radius

### 1. Aislamiento

| Técnica | Alcance limitado a |
|---------|-------------------|
| Contenedores (Docker, containerd) | Un proceso y su filesystem |
| Namespaces de red (netns) | Una interfaz y tabla de rutas |
| cgroups v2 | Un grupo de procesos (CPU, memoria, I/O) |
| VMs | Un sistema operativo completo |
| VLANs | Un segmento de red |
| Tenants en base de datos | Un schema por cliente |

### 2. Deploy progresivo

| Técnica | Cómo reduce el blast radius |
|---------|---------------------------|
| Canary deploy | 1% del tráfico primero, luego 10%, luego 100% |
| Blue-green deploy | Entorno alternativo, switch instantáneo con rollback |
| Feature flags | Activar para usuarios específicos |
| Rolling update | Un nodo a la vez, nunca todos juntos |

### 3. Validación pre-cambio

| Técnica | Previene |
|---------|----------|
| `--dry-run` | Ejecución real (simular sin aplicar) |
| `terraform plan` | Cambios no deseados en infraestructura |
| `nginx -t` | Syntax error en config antes de reload |
| CI/CD pipeline | Deploy de código roto |
| Code review | Error humano no detectado |

### 4. Rollback rápido

Todo cambio debe tener un camino de vuelta conocido y probado:

- Deploy: `git revert` + pipeline automático
- Config: backup del archivo original antes de editar (`cp nginx.conf nginx.conf.bak`)
- Base de datos: transacción con `BEGIN` / `ROLLBACK`
- Infraestructura: `terraform destroy` + `terraform apply` del estado anterior

---

## 📋 Change management mínimo para un sysadmin

Para cualquier cambio en producción:

1. **Anunciar**: comunicar al equipo qué vas a cambiar y cuándo
2. **Planificar el rollback**: si no sabés cómo deshacerlo, no lo hagas
3. **Hacer en staging/ dev primero**: mismo cambio, mismo dato, mismo resultado
4. **Validar**: después del cambio, verificar que funcionó (no asumir)
5. **Monitorear**: los 5 minutos post-cambio son críticos, mirá dashboards y logs
6. **Documentar**: registrar en el runbook qué cambió y por qué

---

## 🧠 Modelo mental

Pensá en el blast radius como el **compartimiento estanco de un submarino**: si un compartimiento se inunda, los demás permanecen secos porque están aislados por puertas herméticas.

Cada capa de aislamiento (container, VLAN, cgroup, namespace, partición de base de datos) es una puerta estanca. Cuando diseñás un sistema, preguntate: "si esto falla, ¿hasta dónde llega el agua?"

---

## 🔗 Ver también

- [`concept`](idempotency.md) — operaciones repetibles que no agravan el daño
- [`concept`](stateful-vs-stateless.md) — minimizar estado reduce blast radius
- [`docker`](../guides/docker.md) — aislamiento con contenedores
- [`iptables`](../guides/iptables.md) — reglas por interfaz o por IP para limitar alcance
- [`production_server`](../guides/production_server.md) — hardening y límites de recursos
- [`scenario`](../scenarios/infrastructure/01-migrate-to-production.md) — migración con validación post-cambio
- [`scenario`](../scenarios/infrastructure/03-disaster-recovery.md) — rollback desde backup
