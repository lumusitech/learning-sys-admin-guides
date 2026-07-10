# 🧩 Escenario: Docker troubleshooting — crash loops, OOM y resource limits

**Dominio:** system
**Nivel:** 🟡 Intermedio
**Herramientas:** `docker`, `docker compose`, `docker logs`, `docker inspect`, `docker stats`
**Archivos:** `labs/docker-compose.docker.yml`

---

## 🎯 Problema

Un contenedor Docker se reinicia constantemente (crash loop), o es eliminado por el OOM killer del kernel. En producción esto significa downtime del servicio. Los desarrolladores reportan "funciona en mi máquina" pero en el servidor el contenedor no se mantiene vivo. Es necesario diagnosticar si el problema es un error en la aplicación, un límite de memoria muy bajo, o un recurso del host agotado.

---

## ⚡ Quick command (SRE)

```bash
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.State}}"
```

---

## ✅ Salida esperada

- contenedor en estado `Restarting` con contador de reinicios alto → crash loop
- contenedor en estado `Exited (137)` → OOM killer (señal 9)
- contenedor en estado `Exited (1)` → error de aplicación
- contenedor en estado `Created` pero nunca arrancó → falta de dependencia o config rota
- contenedor en `Up` pero con `Restart Count > 0` en `docker inspect` → se recuperó de crash

Interpretación:

- `Restarting` + `Exit Code 137` → OOM: el contenedor excedió su límite de memoria
- `Restarting` + `Exit Code 1` → error de aplicación: revisar logs
- `Restarting` + `Exit Code 0` → el proceso termina inmediatamente: entrypoint roto
- `Restart Count` alto pero ahora `Up` → el contenedor se recuperó tras varios intentos

---

## 🧠 Diagnóstico

Docker tiene dos mecanismos principales para lidiar con contenedores problemáticos: la política de restart (`restart: always` o `unless-stopped`) que reintenta automáticamente, y los resource limits (`mem_limit`, `cpus`) que imponen restricciones del kernel. Cuando un contenedor entra en crash loop, Docker lo reintenta indefinidamente, saturando logs y consumiendo recursos del host.

Patrones clave:

- contenedor con `Restarting` y `Exit Code 137` → OOM: aumentar `mem_limit` o optimizar la app
- contenedor con `Restarting` y `Exit Code 1` → error de app: `docker logs` para ver el traceback
- contenedor con `Restarting` y `Exit Code 0` → entrypoint termina: revisar CMD/entrypoint
- `docker stats` muestra `MEM USAGE` cerca del `LIMIT` → contenedor a punto de OOM
- `OOMKilled: true` en `docker inspect` → confirmación de OOM

👉 Si un contenedor se reinicia más de 5 veces en 1 minuto, es un crash loop. No esperes a que se "arregle solo".

---

## 🛠️ Procedimiento (runbook)

### 1. Identificar contenedores con problemas

```bash
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.State}}\t{{.Ports}}"
```

### 2. Ver logs del contenedor para entender el error

```bash
docker logs --tail 50 <container>
docker logs -f <container>
```

### 3. Verificar si es OOM (memoria agotada)

```bash
docker inspect <container> | grep -i "oom\|exitcode\|restart"
docker stats --no-stream <container>
```

### 4. Verificar resource limits del contenedor

```bash
docker inspect <container> | grep -i "memory\|cpu\|nano"
```

### 5. Ver el historial de reinicios

```bash
docker inspect <container> | grep -i "restartcount"
```

### 6. Verificar recursos del host

```bash
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
```

---

## 🧯 Mitigación

Si se confirma un crash loop:

Verificar:

```bash
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.State}}"
docker logs --tail 20 <container>
```

Acción:

```bash
# Si es OOM: aumentar el límite de memoria en docker-compose.yml
# mem_limit: 256m → mem_limit: 512m
# O eliminar el límite temporalmente para confirmar

# Si es error de app: revisar y corregir el código o la config
# docker exec -it <container> sh  # si el contenedor está corriendo

# Si es entrypoint roto: verificar CMD/ENTRYPOINT en Dockerfile
# docker inspect <container> | grep -i "cmd\|entrypoint"

# Reiniciar el contenedor con los cambios
docker compose -f docker-compose.docker.yml up -d <service>
```

Mitigación adicional:

```bash
# Para evitar crash loops infinitos, usar restart policy con backoff
# restart: on-failure:5  (máximo 5 reintentos)

# Monitorear logs en tiempo real
docker logs -f --tail 100 <container>
```

Rollback:

```bash
# Volver a la versión anterior de la imagen
docker compose -f docker-compose.docker.yml down
docker compose -f docker-compose.docker.yml up -d
```

Casos comunes:

- app en Node.js con `--max-old-space-size=4096` en contenedor de 256MB → OOM garantizado
- app en Python con memory leak que crece hasta el límite → OOM tras horas
- entrypoint que termina inmediatamente (ej: `echo "done"` en vez de `exec app`) → crash loop
- dependencia de servicio externo no disponible → app falla al arrancar

---

## ✅ Interpretación

- el contenedor se mantiene `Up` tras aumentar `mem_limit` → era OOM
- el contenedor muestra traceback en logs y se reinicia → error de app, no de Docker
- el contenedor termina inmediatamente con `Exit Code 0` → entrypoint roto
- `OOMKilled: true` en inspect → confirmación de OOM del kernel
- `Restart Count` se resetea tras `docker compose down/up` → se reinicia el contador

---

## 🐧 Variante Alpine (OpenRC)

> Este escenario no usa `systemctl`, `journalctl`, `apt` ni `ufw`. No requiere variante Alpine.

---

## 🧑‍🏫 Modo docente

**Preguntas:** ¿Qué significa exit code 137 en Docker? ¿Cómo verificás si un contenedor fue matado por OOM? ¿Qué comando usás para ver logs de un contenedor que ya no corre?

**Ejercicio:** Diagnosticar un contenedor en crash loop: ver logs con docker logs, revisar exit code, ajustar memory limits si es OOM.

**Evaluación:** interpretación correcta de exit codes, uso de docker logs e inspect, ajuste de resource limits.

---

## 🔗 Referencias

- [`systemd_journalctl`](../../guides/systemd_journalctl.md) — logs del sistema (para diagnóstico fuera del contenedor)
- [`top`](../../guides/top.md) — monitoreo de recursos del host
- [`free`](../../guides/free.md) — memoria del host
- [`scenarios/system/05-system-memory-issues-oom.md`](05-system-memory-issues-oom.md) — OOM en general (no Docker)
- [`scenarios/system/09-fork-bomb.md`](09-fork-bomb.md) — consumo extremo de recursos
