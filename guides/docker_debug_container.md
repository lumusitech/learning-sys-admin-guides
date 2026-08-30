# Contenedores efímeros de diagnóstico — Guía completa

**Nivel:** 🟢 Básico
**Archivos de práctica:** Docker instalado en el host
**Ver escenarios relacionados:** [`system/14-docker-troubleshooting`](../scenarios/system/14-docker-troubleshooting.md)

---

## ⚡ Quick command

`docker run --rm -it --net=host --pid=host nicolaka/netshoot`

---

## ⚡ Quick run

```bash
docker run --rm -it --net=host --pid=host nicolaka/netshoot
```

---

## 📑 Índice

1. [¿Qué es?](#qué-es)
2. [Modelo mental](#modelo-mental)
3. [Sintaxis básica](#sintaxis-básica)
4. [Qué se puede testear](#qué-se-puede-testear)
5. [Qué NO funciona en el contenedor](#qué-no-funciona-en-el-contenedor)
6. [Seguridad](#seguridad)
7. [Uno-liners imprescindibles](#uno-liners-imprescindibles)
8. [Errores comunes](#errores-comunes)
9. [Buenas prácticas](#buenas-prácticas)
10. [Referencias internas](#referencias-internas)

---

## 🧠 ¿Qué es?

Un **contenedor efímero de diagnóstico** es un contenedor desechable que se crea solo para ejecutar herramientas de troubleshooting y desaparece al salir. Su objetivo: **no ensuciar el host** — no se instala ningún paquete, no quedan archivos, no se modifican configuraciones.

Tres imágenes útiles:

| Imagen | Contiene | Cuándo usarla |
|--------|----------|---------------|
| `nicolaka/netshoot` | Toolkit completo: curl, dig, nslookup, tcpdump, mtr, ss, lsof, nc, jq, iperf, nsenter y más | Diagnóstico de red y sistema en general |
| `alpine` | Lo mínimo (BusyBox): sh, ps, cat, grep, ss básico | Espejo liviano del sistema para jugar sin riesgo |
| `busybox` | Aún más mínimo que alpine | Último recurso, sin repositorio propio |

Con los flags correctos, el contenedor puede **ver el sistema real del host** (procesos, red, archivos) sin poder modificarlo.

---

## 🧠 Modelo mental

Docker aísla por *namespaces*. Cada flag que pasás al `docker run` decide qué namespace **comparte** el contenedor con el host y cuál queda aislado:

```text
sin flags          → el contenedor vive en una burbuja (no ve nada del host)
--net=host         → comparte la red: ve interfaces, sockets y tráfico reales
--pid=host         → comparte los procesos: ve /proc y PIDs del host
-v /:/host:ro      → comparte el filesystem en modo lectura
--privileged       → comparte TODO y con permisos de root (peligroso)
```

- Lo que se comparte, se **ve**.
- Lo que no se comparte, no existe dentro del contenedor.
- `--rm` garantiza que al salir no queda ningún rastro.

> Pensá en el contenedor como un pasante con credencial de visita: puede mirar todos los paneles del host (`--net=host --pid=host`) pero sin credencial de mantenimiento (`--privileged`) no puede tocar nada.

---

## 📝 Sintaxis básica

```bash
docker run [flags] <imagen> [comando]
```

### Flags clave

| Flag | Qué hace | Qué podés ver/hacer |
|------|----------|---------------------|
| `--rm` | Elimina el contenedor al salir | Nunca quedan restos |
| `-it` | Interactivo + terminal | Podés escribir comandos adentro |
| `--net=host` | Comparte el namespace de red del host | `ss -tuln` muestra los puertos reales, `tcpdump` captura el tráfico real, `curl localhost:8080` alcanza servicios del host |
| `--pid=host` | Comparte el namespace de procesos | `ps aux` muestra los procesos del host, podés leer `/proc/<PID>/` real |
| `--uts=host` | Comparte hostname y NIS domain | `hostname` coincide con el del host |
| `--ipc=host` | Comparte la memoria IPC (System V, POSIX) | Podés ver colas de mensajes y semáforos del host |
| `-v /:/host:ro` | Monta el filesystem raíz del host en `/host` en modo lectura | Leés configs y logs sin riesgo de modificar nada |
| `--cap-add=NET_RAW` | Agrega la capability de captura de paquetes | `tcpdump` funciona sin `--privileged` |

### El "espejo del sistema"

```bash
docker run --rm -it --net=host --pid=host alpine sh
```

Este es el patrón estrella: un shell Alpine liviano que **ve la red y los procesos del host como si fuera el host**, pero corre aislado. Podés explorar, probar comandos y equivocarte sin romper nada afuera.

Para un espejo casi completo (red + procesos + filesystem de solo lectura):

```bash
docker run --rm -it --net=host --pid=host -v /:/host:ro alpine sh
```

---

## Qué se puede testear

### Red (con `--net=host`)

```bash
ss -tuln                        # puertos en escucha reales del host
ss -tnp | head                  # conexiones establecidas con proceso dueño
tcpdump -i any -n port 443      # capturar tráfico real del host
dig google.com                  # resolución DNS real
curl -v http://localhost:8080   # probar un servicio local sin instalarlo
mtr 8.8.8.8                     # traceroute continuo
nc -vz 10.0.0.5 22              # probar conectividad TCP
```

Ideal para: verificar puertos, sniffear conexiones, probar endpoints internos, diagnosticar latencia — **sin instalar nada en el host**.

### Procesos (con `--pid=host`)

```bash
ps aux | sort -k3 -rn | head    # procesos ordenados por CPU
cat /proc/<PID>/cmdline         # línea de comando de un proceso real
cat /proc/<PID>/environ         # variables de entorno
ls -la /proc/<PID>/fd/          # archivos abiertos
```

Ideal para: inspeccionar procesos del host, ver con qué argumentos corren, qué archivos tienen abiertos.

### Filesystem (con `-v /:/host:ro`)

```bash
cat /host/etc/nginx/nginx.conf      # leer config del host
tail -f /host/var/log/syslog        # seguir logs en vivo
ls /host/etc/apk/repositories       # ver repos del host (Alpine)
```

Ideal para: leer configs y logs sin riesgo de modificación.

### Entrar al namespace de un proceso (`nsenter`)

`nsenter` permite meterse en los namespaces de un proceso en ejecución: ver la red, el filesystem o el hostname **desde adentro** de ese proceso. Es el equivalente a "teletransportarse" al contexto del proceso.

**Requisito:** `nsenter` necesita `CAP_SYS_ADMIN` (con `--pid=host` solo se ve el proceso, no se entra a sus namespaces):

```bash
docker run --rm -it --net=host --pid=host --cap-add=SYS_ADMIN nicolaka/netshoot
```

**Walkthrough contra un servicio real** (nginx del lab `docker-compose.broken.yml`):

```bash
# 1. Levantar el servicio y obtener su PID real (visto desde el host)
docker compose -f labs/docker-compose.broken.yml up -d nginx-broken
docker inspect --format '{{.State.Pid}}' nginx-broken

# 2. Desde un contenedor de diagnóstico con --pid=host --cap-add=SYS_ADMIN:
ps aux | grep "nginx: master"        # confirmar el PID también acá
nsenter -t <PID> -n ip addr          # interfaces DENTRO del netns del proceso
nsenter -t <PID> -n ss -tuln         # puertos en escucha dentro de su red
nsenter -t <PID> -m ls /etc/nginx    # ver su filesystem (mount namespace)
nsenter -t <PID> -u hostname         # ver su hostname (UTS namespace)
```

Salida clave de `nsenter -t <PID> -n ip addr` contra el contenedor nginx:

```text
inet 127.0.0.1/8 scope host lo
inet 172.17.0.2/16 brd 172.17.255.255 scope global eth0
```

Interpretación:

- Ves la **red del proceso**, no la del host: `eth0` con `172.17.0.2` es la IP del contenedor, invisible desde `--net=host`.
- `nsenter -t <PID> -n ss -tuln` muestra `0.0.0.0:80` escuchando: es el nginx del contenedor, aunque el debug container esté en la red del host.
- Útil para: diagnosticar por qué un proceso "no ve" un servicio (están en netns distintos), ver su IP real, o capturar solo su tráfico con `tcpdump` dentro de su red.

| Flag | Namespace que entra |
|------|---------------------|
| `-n` | Red (interfaces, rutas, sockets) |
| `-m` | Mount (filesystem) |
| `-u` | UTS (hostname) |
| `-i` | IPC (memoria compartida) |
| `-p` | PID (procesos visibles) |

Sin `--cap-add=SYS_ADMIN` (o `--privileged`) falla con `nsenter: reassociate to namespaces failed: Operation not permitted`.

---

## Qué NO funciona en el contenedor

Aunque compartas namespaces, el contenedor **no es el host**. Cosas que solo funcionan en el sistema nativo:

| Herramienta | Por qué no funciona en contenedor |
|-------------|----------------------------------|
| `systemctl` / `journalctl` | No hay systemd corriendo dentro; el journal del host no está accesible |
| `sysctl -w` | `/proc/sys` es de solo lectura sin `--privileged` |
| `modprobe` / cargar módulos del kernel | Requiere `--privileged` y los módulos del host |
| Acceso a dispositivos raw (`/dev/sda`, smartctl) | `/dev` está filtrado; requiere `--device` o `--privileged` |
| Cambios persistentes de red o firewall | Aunque `--net=host` comparte la red, la configuración real vive en el host |
| `dmesg` completo | El ring buffer del kernel suele estar restringido |
| Reboot, firmware, power management | Imposible desde un contenedor |

Regla práctica: **todo lo que toca el kernel, el hardware o el init system es del host**; el contenedor solo mira.

---

## Seguridad

| Escenario | Riesgo |
|-----------|--------|
| Sin flags especiales | El contenedor está aislado: no puede romper el host |
| `--net=host` | Ve el tráfico de red del host: no lo uses sin necesidad en hosts con tráfico sensible |
| `--pid=host` | Con la capability `CAP_KILL` (presente por defecto) puede **enviar señales a procesos del host**: un `kill -9` accidental es real |
| `-v /:/host:rw` | Montar el filesystem en modo escritura = podés romper el host. Usar siempre `:ro` |
| `--privileged` | Acceso casi total al host: montajes, `/dev`, kernel. Nunca en producción sin entender el riesgo |

Recomendaciones:

- Preferir capabilities puntuales (`--cap-add=NET_RAW`) antes que `--privileged`.
- Para solo lectura: `--net=host --pid=host -v /:/host:ro` sin `--privileged`.
- En hosts de producción, limitar `--pid=host` (señales) y `--net=host` (sniffing) al mínimo necesario.
- `--rm` siempre: evita contenedores huérfanos con esos privilegios.

---

## 💡 Uno-liners imprescindibles

```bash
docker run --rm -it --net=host --pid=host nicolaka/netshoot     # diagnóstico completo
docker run --rm -it --net=host nicolaka/netshoot ss -tuln        # puertos del host
docker run --rm -it --net=host nicolaka/netshoot tcpdump -i any  # capturar tráfico real
docker run --rm -it --pid=host alpine ps aux                     # procesos del host
docker run --rm -it -v /:/host:ro alpine sh                      # espejo read-only del FS
docker run --rm -it --net=host --pid=host alpine sh              # espejo del sistema
```

---

## ⚠️ Errores comunes

| Error | Causa | Acción |
|-------|-------|--------|
| `tcpdump: socket: Operation not permitted` | Falta la capability de captura | `--cap-add=NET_RAW` (o `--privileged`) |
| `ss` no muestra los puertos del host | No usaste `--net=host` | Agregar `--net=host` |
| `ps` no muestra los procesos del host | No usaste `--pid=host` | Agregar `--pid=host` |
| `journalctl: No journal files` | No hay systemd en el contenedor | Diagnóstico de logs en el host; o `--pid=host -v /var/log/...` |
| `nsenter: reassociate to namespaces failed: Operation not permitted` | Falta `CAP_SYS_ADMIN` | `--cap-add=SYS_ADMIN` (o `--privileged`) |
| `docker: host network requested but not available` | Docker Desktop / WSL2 sin soporte de `--net=host` | Usar `-p` con puertos o ejecutar en una VM/Linux nativo |
| El contenedor sale al instante | El comando terminó (ej. sin `sh` interactivo) | `-it` + `sh` al final |

---

## ✅ Buenas prácticas

- Usar `--rm` siempre: contenedor de diagnóstico = desechable.
- Preferir `--cap-add` puntuales a `--privileged`.
- Montar el filesystem del host solo en `:ro` salvo necesidad explícita.
- `netshoot` para red, `alpine` para espejo mínimo, `busybox` solo si no hay más.
- Documentar el diagnóstico en el escenario correspondiente: no dejar contenedores corriendo.
- En producción, evaluar si `--pid=host` y `--net=host` son necesarios antes de usarlos.

---

## 🔗 Referencias internas

- [`docker`](docker.md) — diagnóstico de contenedores Docker
- [`apt`](apt.md) — alternativa a instalar paquetes en el host
- [`kubectl`](kubectl.md) — pod de diagnóstico `netshoot` dentro de Kubernetes
- [`scenario`](../scenarios/system/14-docker-troubleshooting.md) — troubleshooting de contenedores
