# sysctl — Guía completa

**Nivel:** 🟡 Intermedio
**Archivos de práctica:** `labs/docker-compose.network.yml`, `labs/docker-compose.performance.yml`
**Ver escenarios relacionados:** [`swap-exhaustion`](../scenarios/system/10-swap-exhaustion.md), [`context-switches`](../scenarios/system/13-high-context-switches.md), [`mtu`](../scenarios/networking/11-mtu-fragmentation.md), [`asymmetric-routing`](../scenarios/networking/12-asymmetric-routing.md)

---

## ⚡ Quick command

`sysctl net.ipv4.ip_forward`

> ⚠️ Cambiar en caliente no sobrevive un reinicio. Para persistir, escribí en `/etc/sysctl.d/` y aplicá con `sysctl --system`.

---

## ⚡ Quick run

```bash
# 1. Leer el valor actual
sysctl vm.swappiness

# 2. Cambiarlo en caliente
sysctl -w vm.swappiness=10

# 3. Verificar
sysctl -n vm.swappiness

# 4. Volver al valor anterior
sysctl -w vm.swappiness=60
```

---

## 📑 Índice

1. [¿Qué es sysctl?](#qué-es-sysctl)
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

## 🧠 ¿Qué es sysctl?

`sysctl` es la interfaz de línea de comandos para leer y escribir los **parámetros del kernel** en tiempo de ejecución. Cada parámetro es un archivo en `/proc/sys/`:

```text
net.ipv4.ip_forward  ↔  /proc/sys/net/ipv4/ip_forward
vm.swappiness        ↔  /proc/sys/vm/swappiness
```

Escribir en ese archivo cambia el comportamiento del kernel de inmediato. `sysctl` hace lo mismo con validación de nombre y formato, y además sabe aplicar archivos de configuración completos al arrancar.

No es un comando de diagnóstico: es un comando de **configuración del kernel**. Se usa para ajustar red, memoria, límites de archivos y comportamiento de seguridad.

---

## 🧠 Modelo mental

El kernel es un proceso con cientos de perillas. Hay dos estados distintos y confundirlos es el error más común:

| Estado | Dónde vive | ¿Sobrevive un reinicio? |
|--------|------------|--------------------------|
| **Runtime** (valor activo) | `/proc/sys/...` | No |
| **Persistente** (valor deseado) | `/etc/sysctl.d/*.conf`, `/etc/sysctl.conf` | Sí, si algo lo aplica al arrancar |

```text
archivo .conf  ──(sysctl --system)──▶  /proc/sys  ──▶  kernel
     ▲                                      │
     └──────── sysctl -w escribe acá ───────┘
```

Consecuencias prácticas:

- `sysctl -w` cambia el kernel **ahora**, pero el próximo boot vuelve al valor del archivo.
- Editar el `.conf` no cambia nada hasta que se aplica (`sysctl --system`, `sysctl -p` o reinicio).
- Si el runtime y el archivo no coinciden, el archivo es la intención y el runtime es la realidad. Esa diferencia es un drift que conviene detectar.

---

## 📝 Sintaxis básica

```text
sysctl [opciones] [variable[=valor] ...]
```

| Forma | Qué hace |
|-------|----------|
| `sysctl variable` | Lee una variable |
| `sysctl variable=valor` | Escribe (equivalente a `-w`) |
| `sysctl -a` | Lista todas las variables |
| `sysctl -p [archivo]` | Aplica un archivo (`/etc/sysctl.conf` por defecto) |
| `sysctl --system` | Aplica todos los archivos de configuración del sistema |
| `sysctl -n variable` | Imprime solo el valor (sin `nombre =`) |

Ejemplos:

```bash
sysctl net.ipv4.ip_forward vm.swappiness      # varias a la vez
sysctl -w net.ipv4.ip_forward=1               # escritura en caliente
sysctl -w "net.ipv4.ip_local_port_range=1024 65535"   # valores con espacios: comillas
sysctl -p /etc/sysctl.d/99-network.conf       # aplicar un archivo puntual
sysctl --system                               # aplicar todo, en orden
```

> ⚠️ El nombre con puntos y el nombre con barras son el mismo parámetro: `net.ipv4.ip_forward` = `/proc/sys/net/ipv4/ip_forward`. `sysctl` acepta ambas formas.

---

## 🔑 Salida clave

Lectura:

```text
$ sysctl net.ipv4.ip_forward
net.ipv4.ip_forward = 0
```

Escritura:

```text
$ sysctl -w vm.swappiness=10
vm.swappiness = 10
```

Con `-q` no imprime nada si tuvo éxito:

```text
$ sysctl -q -w vm.swappiness=10
$ echo $?
0
```

Aplicación de archivos:

```text
$ sysctl --system
* Applying /usr/lib/sysctl.d/10-apparmor.conf ...
* Applying /etc/sysctl.d/99-network.conf ...
* Applying /etc/sysctl.conf ...
```

Errores frecuentes:

| Mensaje | Significado |
|---------|-------------|
| `sysctl: permission denied on key "..."` | Falta root (o `CAP_NET_ADMIN` en el namespace) |
| `sysctl: cannot stat /proc/sys/...` | El nombre no existe en este kernel (módulo no cargado o parámetro eliminado) |
| `sysctl: setting key "...": Invalid argument` | Valor fuera de rango o formato incorrecto |
| `sysctl: unknown key "..."` | Nombre mal escrito |

> `--system` sigue aplicando el resto aunque una clave falle. El exit code final puede ser distinto de cero: no lo uses como único indicador de éxito en un script.

---

## 🎛️ Opciones principales

| Opción | Qué hace | Cuándo usarla |
|--------|----------|---------------|
| `-a` | Lista todas las variables | Inventario inicial, baseline |
| `-w` | Escribe un valor | Cambio en caliente |
| `-p [archivo]` | Aplica un archivo | Recargar tras editar |
| `--system` | Aplica todos los archivos del sistema | Tras cambiar `.conf`, antes de reiniciar |
| `-n` | Solo el valor | Scripts, comparaciones |
| `-N` | Solo los nombres | Listar claves sin valores |
| `-e` | Ignora claves desconocidas | Configs portables entre kernels |
| `-q` | Silencioso | Scripts |
| `-r patrón` | Filtra por expresión regular | Buscar parámetros por tema |
| `--dry-run` | Muestra sin escribir | Revisar un archivo antes de aplicarlo |
| `--deprecated` | Incluye parámetros obsoletos | Inventario completo |

> ⚠️ **Compatibilidad**: en Alpine/BusyBox están disponibles `-a`, `-w`, `-p`, `-n`, `-e` y `-q`. `--system`, `-r`, `--dry-run`, `-N` y `--deprecated` son de `procps-ng` (Debian/Ubuntu/RHEL) y no existen en BusyBox. Verificá con `busybox sysctl --help`.

### Orden de carga de los archivos

**systemd** (`sysctl --system`):

1. Se recogen los archivos de `/etc/sysctl.d/`, `/run/sysctl.d/`, `/usr/lib/sysctl.d/` y `/usr/local/lib/sysctl.d/`.
2. Se ordenan **lexicográficamente por nombre de archivo**, sin importar el directorio.
3. Si dos archivos tienen el mismo nombre, gana el de mayor prioridad: `/etc` > `/run` > `/usr/lib` > `/usr/local/lib`.
4. Al final se aplica `/etc/sysctl.conf`.

**Alpine/OpenRC** (`rc-service sysctl start`):

1. `/lib/sysctl.d/*.conf` y `/usr/lib/sysctl.d/*.conf` (se omiten si existe el mismo nombre en `/etc/sysctl.d/` o `/run/sysctl.d/`).
2. `/etc/sysctl.d/*.conf`.
3. `/etc/sysctl.conf`.
4. `/run/sysctl.d/*.conf`.

Consecuencia: el nombre del archivo es la prioridad. `99-tuning.conf` gana sobre `50-default.conf` porque se aplica después. Un archivo sin número puede quedar en cualquier posición.

---

## 📋 Patrones de uso

### 1. Leer y guardar una baseline

```bash
sysctl -a > /var/lib/baseline/sysctl-$(date +%F).txt 2>/dev/null
```

Comparar contra otra máquina o contra el mismo host después de un cambio:

```bash
diff -u /var/lib/baseline/sysctl-2026-11-20.txt /var/lib/baseline/sysctl-2026-11-26.txt
```

### 2. Cambiar en caliente y verificar

```bash
sysctl -w net.core.somaxconn=4096
sysctl -n net.core.somaxconn
```

Cambiar un parámetro de red afecta a los **sockets nuevos**: las conexiones ya establecidas conservan el comportamiento anterior. Para que el cambio aplique a todo, hay que reiniciar el servicio o la máquina.

### 3. Persistir con un archivo propio

```bash
cat > /etc/sysctl.d/99-web.conf <<'EOF'
net.core.somaxconn = 4096
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_syncookies = 1
EOF

sysctl --system
```

En Alpine:

```bash
cat > /etc/sysctl.d/99-web.conf <<'EOF'
net.core.somaxconn = 4096
EOF

rc-service sysctl start
```

### 4. Aplicar sin reiniciar y sin tocar el resto

```bash
sysctl -p /etc/sysctl.d/99-web.conf
```

Útil cuando no querés re-aplicar toda la configuración del sistema.

### 5. Revertir un cambio

```bash
# Antes de cambiar, guardar el valor
sysctl -n vm.swappiness > /tmp/swappiness.old

# Cambiar
sysctl -w vm.swappiness=10

# Revertir
sysctl -w vm.swappiness="$(cat /tmp/swappiness.old)"
```

Si el valor vino de un archivo, revertí el archivo y volvé a aplicarlo. Nunca dejes el cambio solo en runtime sin documentar el valor original.

### 6. Detectar drift entre runtime y configuración

```bash
# Valores activos
sysctl -a 2>/dev/null | sort > /tmp/runtime.txt

# Valores que los archivos declaran (sin aplicar)
sysctl --system --dry-run 2>/dev/null | sort > /tmp/config.txt

diff -u /tmp/config.txt /tmp/runtime.txt
```

> `--dry-run` es de `procps-ng`. En BusyBox, comparar contra un `sysctl -a` guardado después de aplicar la configuración.

### 7. Tuning típico de red

```bash
cat > /etc/sysctl.d/99-network.conf <<'EOF'
# Backlog de conexiones en espera
net.core.somaxconn = 4096
net.ipv4.tcp_max_syn_backlog = 8192

# Protección contra SYN flood
net.ipv4.tcp_syncookies = 1

# Rango de puertos efímeros
net.ipv4.ip_local_port_range = 1024 65535

# Reutilizar sockets en TIME_WAIT
net.ipv4.tcp_tw_reuse = 1

# Buffers de socket
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
EOF
```

### 8. Tuning de memoria

```bash
cat > /etc/sysctl.d/99-memory.conf <<'EOF'
# Menos swap agresivo en servidores con RAM suficiente
vm.swappiness = 10

# Cuánta memoria sucia se acumula antes de escribir a disco
vm.dirty_background_ratio = 5
vm.dirty_ratio = 15
EOF
```

> `vm.swappiness` no desactiva el swap: lo hace menos probable. Para desactivarlo del todo se usa `swapoff`, no sysctl.

### 9. Límites de archivos y procesos

```bash
sysctl fs.file-max                 # máximo de FDs abiertos en todo el sistema
sysctl kernel.pid_max              # máximo de PIDs
sysctl fs.inotify.max_user_watches # límite de inotify (watchers, IDEs, sincronización)
```

`fs.file-max` es global; el límite por proceso se controla con `ulimit -n`. Subir uno no sube el otro.

### 10. sysctl en contenedores y namespaces

Los parámetros `net.*` son **por network namespace**: cambiarlos dentro de un contenedor afecta solo a ese contenedor. El resto de los parámetros (`vm.*`, `kernel.*`, `fs.*`) son globales y requieren permisos sobre el host.

```bash
# Dentro del contenedor
sysctl net.ipv4.ip_local_port_range

# Desde el host: el valor del contenedor no es el del host
docker exec <contenedor> sysctl -n net.ipv4.ip_local_port_range
```

---

## 🔍 Uso en troubleshooting

### SYN flood o conexiones que se rechazan

Síntomas: `ss -s` muestra muchos sockets en `SYN-RECV`, el servicio no acepta conexiones nuevas.

```bash
sysctl net.ipv4.tcp_syncookies
sysctl net.ipv4.tcp_max_syn_backlog
sysctl net.core.somaxconn
```

`tcp_syncookies=1` permite responder sin guardar estado por cada SYN. `somaxconn` limita la cola de `listen()`.

### Tabla de conntrack llena

Síntoma: `dmesg` con `nf_conntrack: table full, dropping packet`.

```bash
sysctl net.netfilter.nf_conntrack_max
sysctl net.netfilter.nf_conntrack_count
```

Si el módulo no está cargado, `cannot stat` es esperable. Subir el máximo solo pospone el problema: la causa suele ser demasiadas conexiones cortas o timeouts largos.

### Agotamiento de puertos efímeros

Síntoma: `cannot assign requested address` al conectar hacia afuera, con muchos sockets en `TIME_WAIT`.

```bash
sysctl net.ipv4.ip_local_port_range
ss -tan state time-wait | wc -l
```

Ampliar el rango y habilitar `tcp_tw_reuse` ayuda; la solución de fondo es reutilizar conexiones (keep-alive, pool).

### Thrashing de swap

Síntoma: `vmstat` con `si`/`so` altos y `free` con swap lleno.

```bash
sysctl vm.swappiness
```

Bajar `swappiness` reduce la tendencia a swapear, pero no corrige la falta de RAM. Es un paliativo, no una solución.

### Tráfico asimétrico descartado por rp_filter

Síntoma: paquetes que llegan pero no vuelven, con rutas asimétricas.

```bash
sysctl net.ipv4.conf.all.rp_filter
sysctl net.ipv4.conf.eth0.rp_filter
```

`rp_filter=1` descarta paquetes cuya interfaz de entrada no coincide con la ruta de retorno. En escenarios con múltiples caminos puede ser necesario `2` (modo loose) o `0` en interfaces específicas.

### MTU y PMTU blackhole

Síntoma: conexiones que se cuelgan en el handshake o transferencias grandes que fallan.

```bash
sysctl net.ipv4.ip_no_pmtu_disc
ip route get 8.8.8.8
```

`ip_no_pmtu_disc=0` permite el descubrimiento de PMTU. Si está en `1`, el kernel ignora los ICMP "fragmentation needed".

### Servicios que no arrancan por límites

Síntoma: `Too many open files` o `fork: Cannot allocate memory`.

```bash
sysctl fs.file-max
sysctl kernel.pid_max
ulimit -n
```

Comparar el límite global con el del proceso y con el del servicio (systemd `LimitNOFILE`).

---

## 🛠️ Combinación con otras herramientas

| Combinación | Para qué |
|-------------|----------|
| `sysctl` + `diff` | Comparar baseline de parámetros entre hosts o fechas |
| `sysctl` + `ss` | Correlacionar tuning de red con el estado real de sockets |
| `sysctl` + `dmesg` | Confirmar que el kernel aplicó el cambio (o descartó paquetes) |
| `sysctl` + `ip` | Verificar rutas, interfaces y rp_filter por interfaz |
| `sysctl` + `ulimit` | Distinguir límite global de límite por proceso |
| `sysctl` + `docker` | Leer parámetros por namespace de red |

Ejemplo: verificar que el cambio de backlog llegó al servicio.

```bash
sysctl -n net.core.somaxconn
ss -ltn | grep :80
```

---

## 💡 Uno-liners imprescindibles

```bash
# Leer un valor limpio (sin "nombre =")
sysctl -n net.ipv4.ip_forward

# Cambiar en caliente
sysctl -w net.ipv4.ip_forward=1

# Aplicar toda la configuración sin reiniciar
sysctl --system

# Aplicar un archivo puntual
sysctl -p /etc/sysctl.d/99-web.conf

# Buscar parámetros por tema
sysctl -a 2>/dev/null | grep -i conntrack

# Baseline para comparar después
sysctl -a 2>/dev/null | sort > /tmp/sysctl-antes.txt

# Guardar valor antes de cambiar
sysctl -n vm.swappiness > /tmp/swappiness.old

# Inventario solo de nombres
sysctl -N 2>/dev/null | grep '^net.ipv4.tcp'
```

---

## ⚠️ Errores comunes

### 1. Cambiar en caliente y creer que quedó persistente

```bash
sysctl -w vm.swappiness=10
# tras el reinicio: vuelve a 60
```

Siempre escribí el valor en `/etc/sysctl.d/` si querés que sobreviva.

### 2. Nombres de archivo sin orden

`tuning.conf` y `zz-tuning.conf` se aplican en orden distinto. Usá prefijo numérico (`99-`) para controlar la prioridad.

### 3. Valores con espacios sin comillas

```bash
sysctl -w net.ipv4.ip_local_port_range=1024 65535   # error: 65535 se interpreta como variable
sysctl -w "net.ipv4.ip_local_port_range=1024 65535" # correcto
```

### 4. Confundir `sysctl -p` con `--system`

`sysctl -p` aplica solo `/etc/sysctl.conf` (o el archivo indicado). `--system` recorre todos los directorios. En Alpine, `--system` no existe: usá el servicio o `-p` por archivo.

### 5. Esperar que el cambio aplique a conexiones existentes

`somaxconn`, buffers y algoritmos de congestión afectan a sockets nuevos. Las conexiones ya abiertas mantienen el comportamiento anterior.

### 6. Usar `fs.file-max` para arreglar un servicio

`fs.file-max` es un techo global. El servicio sigue limitado por `ulimit -n` / `LimitNOFILE`. Hay que ajustar los dos.

### 7. Cambiar `rp_filter` sin entender el ruteo

Poner `rp_filter=0` en `all` desactiva una protección anti-spoofing. Preferí `2` (loose) o ajustar solo la interfaz afectada.

### 8. Aplicar tuning de otro servidor sin medir

Un valor copiado de un host con 64 GB de RAM puede empeorar uno con 2 GB. `vm.dirty_ratio` alto en poco disco = picos de I/O. Medí antes y después.

### 9. Ignorar el error de `--system`

Un `cannot stat` en una clave obsoleta no detiene la aplicación del resto. Revisá la salida completa; el exit code puede ser 0 aunque haya fallos.

---

## ✅ Buenas prácticas

- **Un archivo por tema**, con prefijo numérico: `99-network.conf`, `99-memory.conf`, `99-security.conf`.
- **Documentá el motivo** en un comentario dentro del archivo: qué problema resuelve y qué valor había antes.
- **Cambiá en caliente para probar, persistí después de medir.** No al revés.
- **Guardá el valor original** antes de tocar cualquier parámetro.
- **Aplicá con `sysctl -p <archivo>`** cuando probás un archivo nuevo, y `--system` cuando ya está en su lugar.
- **Usá `-e`** en configs que deben funcionar en kernels distintos (parámetros que pueden no existir).
- **Compará con baseline** antes y después: `sysctl -a | sort` + `diff`.
- **No toques `vm.overcommit_memory`, `kernel.panic` ni `rp_filter` global** sin una razón concreta y un plan de rollback.
- **Verificá el efecto real** con la herramienta del dominio: `ss` para red, `vmstat` para memoria, `dmesg` para descartes.

---

## 🔗 Referencias internas

- [`production_server`](production_server.md) — tuning de kernel en servidores de producción
- [`network_segmentation`](network_segmentation.md) — `ip_forward` y forwarding entre interfaces
- [`nginx`](nginx.md) — `somaxconn` y backlog en el contexto de un reverse proxy
- [`ip_ss`](ip_ss.md) — estado real de sockets tras el tuning
- [`dmesg`](dmesg.md) — confirmar descartes del kernel
- [`diff`](diff.md) — comparar baselines de parámetros
- [`production_server`](production_server.md) — límites por proceso (`ulimit`) frente a `fs.file-max`
- [`scenario`](../scenarios/system/10-swap-exhaustion.md) — swap lleno y `vm.swappiness`
- [`scenario`](../scenarios/system/13-high-context-switches.md) — context switches y tuning
- [`scenario`](../scenarios/networking/12-asymmetric-routing.md) — `rp_filter` con rutas asimétricas
- [`scenario`](../scenarios/infrastructure/01-migrate-to-production.md) — sysctl al migrar a producción
