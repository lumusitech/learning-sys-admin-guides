# docker — Guía completa

**Nivel:** 🟡 Intermedio
**Archivos de práctica:** `labs/docker-compose.broken.yml`, `labs/docker-compose.docker.yml`
**Ver escenarios relacionados:** [`system/14-docker-troubleshooting`](../scenarios/system/14-docker-troubleshooting.md)

---

## ⚡ Quick command

`docker ps`

> ⚠️ Requiere Docker instalado y permisos de root o grupo `docker`.

---

## ⚡ Quick run

```bash
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

---

## 📑 Índice

1. [¿Qué es Docker?](#qué-es-docker)
2. [Modelo mental](#modelo-mental)
3. [Sintaxis básica](#sintaxis-básica)
4. [Salida clave](#salida-clave)
5. [Opciones principales](#opciones-principales)
6. [Patrones de uso](#patrones-de-uso)
7. [Uso en troubleshooting](#uso-en-troubleshooting)
8. [Combinación con otras herramientas](#combinación-con-otras-herramientas)
9. [Uno-liners imprescindibles](#uno-liners-imprescindibles)
10. [Errores comunes](#errores-comunes)
11. [Buenas prácticas](#buenas-prácticas)
12. [Referencias internas](#referencias-internas)

---

## 🧠 ¿Qué es Docker?

Docker es una plataforma de **contenedores** que permite ejecutar aplicaciones en entornos aislados llamados **contenedores**. A diferencia de las máquinas virtuales, los contenedores comparten el kernel del host pero tienen su propio sistema de archivos, red y procesos aislados.

### ¿Para qué sirve?

- **Aislamiento**: cada contenedor tiene su propio entorno (libs, deps, config)
- **Portabilidad**: "funciona en mi máquina" → funciona en cualquier lugar con Docker
- **Eficiencia**: más liviano que VMs (comparte kernel, arranca en segundos)
- **Reproducibilidad**: mismo contenedor = mismo comportamiento

### ¿Cuándo usarlo?

- Desplegar aplicaciones web, APIs, bases de datos
- Entornos de desarrollo consistentes
- Microservicios y arquitecturas distribuidas
- CI/CD y testing automatizado
- Laboratorios de práctica (como los de este repo)

### ¿Cuándo NO usarlo?

- Aplicaciones que requieren acceso directo al hardware (drivers, GPUs)
- Sistemas operativos completos (para eso, VMs)
- Cuando el aislamiento de kernel no es suficiente (seguridad crítica → VMs)

---

## 🧠 Modelo mental

Docker es un **gestor de procesos en entornos aislados**.

Piensa en Docker como `systemd` pero para procesos aislados:

- **Contenedor** = proceso ejecutándose en un entorno aislado
- **Imagen** = plantilla de solo lectura (como un binario)
- **Volumen** = disco persistente (como `/var/lib/data`)
- **Red** = interfaz de red virtual (como `eth0` pero aislada)
- **Compose** = orquestador de múltiples contenedores (como `systemd` con múltiples servicios)

### Ciclo de vida de un contenedor

```text
Imagen → Contenedor → Ejecutando → Detenido → Eliminado
         (create)      (running)    (exited)     (rm)
```

### Estados de un contenedor

| Estado | Significado |
|--------|-------------|
| `created` | Contenedor creado pero no iniciado |
| `running` | Contenedor ejecutándose |
| `paused` | Contenedor pausado (procesos suspendidos) |
| `restarting` | Contenedor reiniciándose |
| `removing` | Contenedor en proceso de eliminación |
| `exited` | Contenedor detenido (código de salida disponible) |
| `dead` | Contenedor en estado inconsistente (requiere limpieza) |

---

## 📝 Sintaxis básica

```bash
docker <comando> [opciones] [argumentos]
```

**Comandos principales:**

```bash
# Gestión de contenedores
docker run      # Crear y ejecutar contenedor
docker ps       # Listar contenedores en ejecución
docker ps -a    # Listar todos (incluyendo detenidos)
docker stop     # Detener contenedor
docker start    # Iniciar contenedor detenido
docker restart  # Reiniciar contenedor
docker rm       # Eliminar contenedor
docker logs     # Ver logs
docker exec     # Ejecutar comando en contenedor
docker inspect  # Información detallada

# Gestión de imágenes
docker images   # Listar imágenes
docker pull     # Descargar imagen
docker build    # Construir imagen desde Dockerfile
docker rmi      # Eliminar imagen

# Gestión de volúmenes
docker volume ls    # Listar volúmenes
docker volume create # Crear volumen
docker volume rm    # Eliminar volumen

# Gestión de redes
docker network ls    # Listar redes
docker network create # Crear red
docker network rm    # Eliminar red
```

---

## 🔑 Salida clave

### `docker ps`

```text
CONTAINER ID   IMAGE          COMMAND                  CREATED        STATUS        PORTS                    NAMES
a1b2c3d4e5f6   nginx:latest   "/docker-entrypoint.…"   2 hours ago    Up 2 hours    0.0.0.0:80->80/tcp       web-server
```

**Campos importantes:**

- `CONTAINER ID` → identificador único (primeros 12 caracteres)
- `IMAGE` → imagen base usada
- `COMMAND` → comando que se ejecuta al iniciar
- `CREATED` → cuándo se creó
- `STATUS` → estado actual (`Up X minutes`, `Exited (1) X minutes ago`)
- `PORTS` → mapeo de puertos (host:container)
- `NAMES` → nombre del contenedor (auto-generado o especificado)

### `docker ps -a` (todos los contenedores)

Muestra también contenedores detenidos:

```text
CONTAINER ID   IMAGE          STATUS                     NAMES
b2c3d4e5f6g7   mysql:8.0      Exited (1) 5 minutes ago   db-broken
```

**Interpretación del estado:**

- `Exited (0)` → terminó normalmente (exit code 0)
- `Exited (1)` → terminó con error (exit code 1)
- `Exited (137)` → fue matado (SIGKILL, posible OOM)
- `Exited (143)` → fue terminado (SIGTERM, shutdown graceful)

### `docker logs`

```text
2024-01-15T10:23:45.123Z  INFO  Starting application...
2024-01-15T10:23:46.456Z  ERROR Database connection failed
2024-01-15T10:23:47.789Z  FATAL Exiting with code 1
```

**Interpretación:**

- Timestamps en formato ISO 8601
- Niveles de log: `INFO`, `WARN`, `ERROR`, `FATAL`
- Buscar patrones de error para diagnosticar fallos

### `docker stats`

```text
CONTAINER ID   NAME         CPU %     MEM USAGE / LIMIT     MEM %     NET I/O           BLOCK I/O
a1b2c3d4e5f6   web-server   2.34%     128MiB / 512MiB       25.00%    1.2kB / 600B      0B / 0B
```

**Campos importantes:**

- `CPU %` → uso de CPU (si es alto, posible cuello de botella)
- `MEM USAGE / LIMIT` → memoria usada vs límite (si接近 límite, posible OOM)
- `MEM %` → porcentaje de memoria usada
- `NET I/O` → tráfico de red (entrada/salida)
- `BLOCK I/O` → I/O de disco (lectura/escritura)

---

## 🎛️ Opciones principales

### `docker ps`

| Opción | Descripción |
|--------|-------------|
| `-a`, `--all` | Mostrar todos (incluyendo detenidos) |
| `-q`, `--quiet` | Solo IDs (útil para scripts) |
| `--format` | Formatear salida (Go template) |
| `-f`, `--filter` | Filtrar por estado, nombre, etc. |
| `-n`, `--last` | Mostrar últimos N contenedores |
| `-s`, `--size` | Mostrar tamaño de contenedores |

### `docker run`

| Opción | Descripción |
|--------|-------------|
| `-d`, `--detach` | Ejecutar en background |
| `-it`, `--interactive --tty` | Modo interactivo con terminal |
| `-p`, `--publish` | Mapear puertos (host:container) |
| `-v`, `--volume` | Montar volumen (host:container) |
| `--name` | Nombrar contenedor |
| `--rm` | Eliminar al terminar |
| `-e`, `--env` | Variable de entorno |
| `--network` | Conectar a red específica |
| `--restart` | Política de reinicio (`always`, `on-failure`, `no`) |
| `--memory` | Límite de memoria |
| `--cpus` | Límite de CPUs |

### `docker logs`

| Opción | Descripción |
|--------|-------------|
| `-f`, `--follow` | Seguir logs en tiempo real |
| `--tail` | Mostrar últimas N líneas |
| `--since` | Logs desde timestamp (ej: `--since 1h`) |
| `--until` | Logs hasta timestamp |
| `-t`, `--timestamps` | Mostrar timestamps |

### `docker exec`

| Opción | Descripción |
|--------|-------------|
| `-it`, `--interactive --tty` | Modo interactivo |
| `-u`, `--user` | Ejecutar como usuario específico |
| `-w`, `--workdir` | Directorio de trabajo |
| `-e`, `--env` | Variable de entorno |

---

## 📋 Patrones de uso

### 1. Desplegar aplicación web

```bash
# Ejecutar nginx con puerto expuesto
docker run -d --name web-server -p 8080:80 nginx:latest

# Verificar que está corriendo
docker ps | grep web-server

# Probar acceso
curl http://localhost:8080
```

### 2. Base de datos con volumen persistente

```bash
# Crear volumen para datos
docker volume create mysql-data

# Ejecutar MySQL con volumen
docker run -d --name db \
  -v mysql-data:/var/lib/mysql \
  -e MYSQL_ROOT_PASSWORD=secret \
  mysql:8.0

# Verificar que los datos persisten
docker stop db
docker rm db
docker run -d --name db-new \
  -v mysql-data:/var/lib/mysql \
  -e MYSQL_ROOT_PASSWORD=secret \
  mysql:8.0
# Los datos siguen ahí
```

### 3. Ejecutar comando en contenedor

```bash
# Entrar al contenedor (shell interactivo)
docker exec -it web-server /bin/bash

# Ejecutar comando único
docker exec web-server cat /etc/nginx/nginx.conf

# Ver procesos dentro del contenedor
docker exec web-server ps aux
```

### 4. Monitoreo de recursos

```bash
# Stats en tiempo real
docker stats

# Stats de un contenedor específico
docker stats web-server

# Inspeccionar detalles
docker inspect web-server | grep -A 5 "Memory"
```

### 5. Limpieza de recursos

```bash
# Eliminar contenedores detenidos
docker container prune -f

# Eliminar imágenes no usadas
docker image prune -f

# Eliminar volúmenes no usados
docker volume prune -f

# Limpieza completa (contenedores, imágenes, redes, volúmenes)
docker system prune -a --volumes -f
```

---

## 🔍 Uso en troubleshooting

### 1. Contenedor no arranca

```bash
# Ver estado
docker ps -a | grep <nombre>

# Ver logs
docker logs <nombre>

# Ver eventos recientes
docker events --filter container=<nombre> --since 1h
```

**Patrones comunes:**

- `Exited (1)` → error en aplicación (ver logs)
- `Exited (137)` → OOM killed (aumentar `--memory`)
- `Exited (127)` → comando no encontrado (verificar `CMD` en Dockerfile)
- `Restarting` → crash loop (ver logs, verificar dependencias)

### 2. Contenedor consume mucha CPU/memoria

```bash
# Ver stats
docker stats <nombre>

# Ver procesos dentro del contenedor
docker exec <nombre> top -b -n 1

# Ver límites configurados
docker inspect <nombre> | grep -E "Memory|Cpu"
```

**Soluciones:**

- Aumentar límites: `--memory 1g --cpus 2`
- Optimizar aplicación
- Escalar horizontalmente (más contenedores)

### 3. Problemas de red

```bash
# Ver redes del contenedor
docker inspect <nombre> | grep -A 10 "Networks"

# Ver puertos expuestos
docker port <nombre>

# Probar conectividad desde el contenedor
docker exec <nombre> ping google.com

# Ver logs de red
docker exec <nombre> cat /var/log/syslog | grep -i network
```

### 4. Problemas de volúmenes

```bash
# Ver volúmenes montados
docker inspect <nombre> | grep -A 5 "Mounts"

# Ver espacio en disco
docker exec <nombre> df -h

# Ver permisos
docker exec <nombre> ls -la /data
```

---

## 🛠️ Combinación con otras herramientas

### docker + grep/awk (análisis de logs)

```bash
# Contar errores en logs
docker logs <nombre> 2>&1 | grep -c "ERROR"

# Extraer IPs de logs
docker logs <nombre> 2>&1 | grep -oP '\d+\.\d+\.\d+\.\d+' | sort -u

# Ver logs de las últimas 2 horas
docker logs --since 2h <nombre> 2>&1 | grep "ERROR"
```

### docker + ps/top (monitoreo de procesos)

```bash
# Ver procesos del host que pertenecen a Docker
ps aux | grep docker

# Ver contenedores ordenados por uso de CPU
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}" | sort -k2 -rn

# Ver contenedores ordenados por uso de memoria
docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}" | sort -k2 -rn
```

### docker + df/du (análisis de disco)

```bash
# Ver espacio usado por Docker
docker system df

# Ver espacio por imagen
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"

# Ver espacio por volumen
docker volume ls -q | xargs docker volume inspect --format '{{.Name}} {{.Mountpoint}}' | \
  awk '{print $1, system("du -sh " $2 " 2>/dev/null")}'
```

---

## 💡 Uno-liners imprescindibles

```bash
# Ver todos los contenedores (incluyendo detenidos)
docker ps -a

# Ver solo IDs de contenedores en ejecución
docker ps -q

# Ver logs en tiempo real
docker logs -f <nombre>

# Entrar al contenedor
docker exec -it <nombre> /bin/bash

# Ver stats de todos los contenedores
docker stats --no-stream

# Detener todos los contenedores
docker stop $(docker ps -q)

# Eliminar todos los contenedores detenidos
docker rm $(docker ps -aq -f status=exited)

# Ver uso de disco de Docker
docker system df

# Limpieza completa
docker system prune -a --volumes -f

# Ver inspección completa de un contenedor
docker inspect <nombre>

# Ver puertos mapeados
docker port <nombre>

# Ver redes de un contenedor
docker inspect <nombre> | grep -A 10 "Networks"

# Copiar archivo desde/hacia contenedor
docker cp <nombre>:/path/inside /path/host
docker cp /path/host <nombre>:/path/inside

# Ver eventos de Docker en tiempo real
docker events --filter type=container
```

---

## ⚠️ Errores comunes

### 1. Olvidar `-d` (detach)

```bash
# ❌ Se queda en foreground
docker run nginx

# ✅ Ejecuta en background
docker run -d nginx
```

### 2. No exponer puertos

```bash
# ❌ No accesible desde el host
docker run -d nginx

# ✅ Expone puerto 80 del contenedor al 8080 del host
docker run -d -p 8080:80 nginx
```

### 3. No usar volúmenes para datos persistentes

```bash
# ❌ Datos se pierden al eliminar contenedor
docker run -d mysql:8.0

# ✅ Datos persisten en volumen
docker run -d -v mysql-data:/var/lib/mysql mysql:8.0
```

### 4. Confundir `docker exec` con `docker run`

```bash
# ❌ Crea nuevo contenedor
docker run -it nginx /bin/bash

# ✅ Ejecuta en contenedor existente
docker exec -it <nombre> /bin/bash
```

### 5. No limpiar recursos

```bash
# ❌ Acumula contenedores/imágenes detenidos
# (sin limpieza periódica)

# ✅ Limpia regularmente
docker system prune -f
```

### 6. Usar `latest` en producción

```bash
# ❌ Impredecible (puede cambiar en cualquier momento)
docker pull nginx:latest

# ✅ Versión específica
docker pull nginx:1.25.3
```

---

## ✅ Buenas prácticas

### 1. Usar nombres descriptivos

```bash
# ❌ Nombre auto-generado (difícil de recordar)
docker run -d nginx

# ✅ Nombre descriptivo
docker run -d --name web-server nginx
```

### 2. Especificar versiones de imágenes

```bash
# ❌ Impredecible
docker pull mysql

# ✅ Versión específica
docker pull mysql:8.0.35
```

### 3. Usar Docker Compose para múltiples contenedores

```bash
# ❌ Múltiples comandos docker run (difícil de mantener)
docker run -d --name web nginx
docker run -d --name db mysql
docker run -d --name cache redis

# ✅ Archivo docker-compose.yml (versionable, reproducible)
docker compose up -d
```

### 4. Limitar recursos

```bash
# ❌ Sin límites (puede consumir todo el host)
docker run -d nginx

# ✅ Con límites
docker run -d --memory 512m --cpus 1.0 nginx
```

### 5. Usar healthchecks

```bash
# ❌ No sabe si la app está sana
docker run -d nginx

# ✅ Con healthcheck
docker run -d --health-cmd "curl -f http://localhost/ || exit 1" nginx
```

### 6. No ejecutar como root

```bash
# ❌ Ejecuta como root (riesgo de seguridad)
docker run -d myapp

# ✅ Especificar usuario no-root
docker run -d --user 1000:1000 myapp
```

### 7. Usar `.dockerignore`

```bash
# ❌ Copia todo (incluyendo node_modules, .git, etc.)
COPY . /app

# ✅ Usa .dockerignore para excluir
# .dockerignore:
# node_modules
# .git
# *.log
```

---

## 🔗 Referencias internas

- [`scenarios/system/14-docker-troubleshooting`](../scenarios/system/14-docker-troubleshooting.md) — troubleshooting de contenedores
- [`labs/docker-compose.broken.yml`](../labs/docker-compose.broken.yml) — laboratorio de servicios rotos
- [`labs/docker-compose.docker.yml`](../labs/docker-compose.docker.yml) — laboratorio de Docker troubleshooting
- [`guides/systemd_journalctl`](systemd_journalctl.md) — gestión de servicios (analogía con Docker)
- [`guides/production_server`](production_server.md) — Docker en producción
