# kill — Guía completa

**Nivel:** 🟢 Básico
**Archivos de práctica:** Sistema en vivo
**Ver escenarios relacionados:** [`system/04-high-cpu-runaway`](../scenarios/system/04-high-cpu-runaway-process.md), [`system/08-zombie-processes`](../scenarios/system/08-zombie-processes.md), [`system/09-fork-bomb`](../scenarios/system/09-fork-bomb.md)

---

## ⚡ Quick command

`kill -15 <PID>`

---

## ⚡ Quick run

```bash
kill -15 1234    # Terminar proceso graceful
kill -9 1234     # Forzar terminación
```

---

## 📑 Índice

1. [¿Qué es kill?](#qué-es-kill)
2. [Modelo mental](#modelo-mental)
3. [Señales principales](#señales-principales)
4. [Sintaxis básica](#sintaxis-básica)
5. [kill, pkill, killall](#kill-pkill-killall)
6. [Patrones de uso](#patrones-de-uso)
7. [Uso en troubleshooting](#uso-en-troubleshooting)
8. [Combinación con otras herramientas](#combinación-con-otras-herramientas)
9. [Uno-liners imprescindibles](#uno-liners-imprescindibles)
10. [Errores comunes](#errores-comunes)
11. [Buenas prácticas](#buenas-prácticas)

---

## 🧠 ¿Qué es kill?

**kill** envía señales a procesos. Una señal es una notificación que el kernel entrega a un proceso para indicarle un evento: que termine, que se detenga, que recargue configuración, etc.

No solo mata procesos. `kill` es el sistema de mensajería entre procesos de Unix. Cada señal tiene un comportamiento distinto.

---

## 🧠 Modelo mental

Las señales son semáforos para procesos:

- `SIGTERM (15)` — "apagate ordenadamente". El proceso recibe la señal, limpia recursos y termina.
- `SIGKILL (9)` — "morí ahora". El kernel termina el proceso inmediatamente. No puede ser ignorada ni capturada.
- `SIGHUP (1)` — "recargá configuración". Muchos servicios (nginx, sshd) rereleen su configuración al recibirla.
- `SIGSTOP (19)` — "pausate". El proceso se congela hasta recibir `SIGCONT`.
- `SIGCONT (18)` — "seguí". Reanuda un proceso detenido.

Un proceso zombie no recibe señales — ya está terminado. La acción real es sobre su padre.

---

## 📝 Señales principales

| Señal | Núm | Acción por defecto | Uso típico |
|-------|-----|-------------------|------------|
| SIGHUP | 1 | Terminar | Recargar configuración de servicios |
| SIGINT | 2 | Terminar | Ctrl+C en terminal |
| SIGQUIT | 3 | Terminar + core dump | Forzar volcado de memoria |
| SIGKILL | 9 | Terminar (forzoso) | Matar proceso que no responde a SIGTERM |
| SIGTERM | 15 | Terminar (graceful) | **Siempre primero** — permite limpieza |
| SIGSTOP | 19 | Detener (pausa) | Congelar un proceso |
| SIGCONT | 18 | Continuar | Reanudar proceso detenido |

Enumerar señales: `kill -l` o `trap -l` (POSIX).

---

## 📝 Sintaxis básica

```bash
kill -<señal> <PID>
kill -<número> <PID>
```

```bash
kill -15 1234            # SIGTERM — terminación graceful
kill -9 1234             # SIGKILL — forzoso
kill -1 1234             # SIGHUP — recargar configuración
kill -0 1234             # Verificar si el proceso existe (sin enviar señal)
```

---

## kill, pkill, killall

### kill

Requiere el PID exacto. Más preciso, pero necesitás conocer el PID.

```bash
kill -15 1234
```

### pkill

Mata por nombre de proceso (o patrón parcial).

```bash
pkill -15 nginx                   # Todos los procesos nginx
pkill -9 -f "python server.py"    # Por patrón en línea de comandos
```

`pkill -f` busca en el comando completo (args incluidos). Útil para scripts.

### killall

Mata por nombre exacto de comando.

```bash
killall -15 nginx                 # Mata todos los procesos llamados "nginx"
killall -15 -v nginx              # Verbose
killall -15 -w nginx              # Esperar a que terminen
```

Diferencia clave: `killall` usa el nombre exacto del proceso; `pkill` usa regex parcial.

---

## 📋 Patrones de uso

### Matar un proceso por PID

```bash
ps aux | grep nginx
kill -15 1234
```

### Matar todos los procesos de un usuario

```bash
pkill -15 -u admin
```

### Matar por puerto (combinado con lsof o fuser)

```bash
fuser -k 80/tcp
lsof -ti :80 | xargs kill -15
```

### Enviar señal a todos los procesos de un servicio

```bash
killall -15 nginx
pkill -15 nginx
```

### Verificar si un proceso existe

```bash
kill -0 1234
echo $?     # 0 = existe, 1 = no existe
```

---

## 🔍 Uso en troubleshooting

### Proceso no responde (runaway CPU)

```bash
# 1. Identificar proceso que consume más CPU
ps aux --sort=-%cpu | head -5

# 2. Intentar terminación graceful
kill -15 <PID>

# 3. Esperar 5 segundos, verificar si sigue vivo
ps -p <PID> --no-headers

# 4. Forzar si no terminó
kill -9 <PID>
```

### Servicio no libera puerto

```bash
fuser -k 80/tcp          # Mata el proceso en puerto 80
lsof -ti :80 | xargs kill -9
```

### Procesos zombie

```bash
# No se puede matar un zombie con kill
kill -9 <PID_ZOMBIE>     # No hace nada

# La acción real es sobre el padre
kill -15 <PPID>
```

### Recargar configuración sin downtime

```bash
kill -1 <PID_NGINX>       # nginx -s reload equivalente
killall -1 nginx
```

---

## 🛠️ Combinación con otras herramientas

### ps + kill: encontrar y matar

```bash
ps aux | grep runaway | awk '{print $2}' | xargs kill -15
```

### pgrep + kill: más seguro que ps+grep

```bash
kill -15 $(pgrep -f "python server.py")
```

### fuser + kill: matar por puerto

```bash
fuser -k 80/tcp
```

### timeout: límite de ejecución

```bash
timeout 5 ping google.com    # Mata el ping tras 5 segundos
```

---

## 💡 Uno-liners imprescindibles

```bash
kill -15 $(pgrep -x nginx)              # Terminar nginx por nombre exacto
kill -9 $(lsof -ti :8080)               # Forzar cierre de proceso en puerto 8080
pkill -15 -u admin                      # Terminar todos los procesos de admin
killall -15 -w nginx                    # Esperar a que nginx termine
kill -1 $(pgrep -x nginx)               # Recargar nginx (SIGHUP)
kill -0 1234 && echo "vivo" || echo "muerto"  # Verificar si existe
timeout 10 comando_largo                # Matar comando tras 10 segundos
```

---

## ⚠️ Errores comunes

- **Usar `kill -9` de primera**. `SIGKILL` no permite al proceso cerrar archivos, liberar sockets ni limpiar estado. Preferir `kill -15` (SIGTERM) primero. Usar `-9` solo si no responde tras unos segundos.
- **Matar un zombie con `kill -9`**. No funciona — el zombie ya terminó. Hay que matar o arreglar al padre (PPID).
- **Matar PID 1**. El proceso init (systemd, OpenRC) maneja todas las señales de forma especial. Matarlo puede dejar el sistema inestable.
- **Usar `killall` sin cuidado**. `killall` mata por nombre exacto pero puede matar procesos del sistema si usás nombres genéricos.
- **Confundir `pkill` con `killall`**. `pkill` usa regex parcial; `killall` usa nombre exacto. `pkill ng` mataría nginx, nginx-proxy, etc.
- **No verificar señal por defecto**. `kill` sin señal envía SIGTERM (15). Si no estás seguro de qué señal usar, no pongas número.

---

## ✅ Buenas prácticas

- **Siempre intentar SIGTERM primero**. Dar oportunidad al proceso de hacer limpieza (cerrar archivos, liberar conexiones).
- **Esperar 3-5 segundos** entre SIGTERM y SIGKILL.
- **Usar `fuser -k` o `lsof -ti`** para matar por puerto — más preciso que ps+grep.
- **En scripts**, verificar que el PID existe antes de matar: `kill -0 <PID>`.
- **Documentar qué señal enviaste y por qué** en runbooks. No es lo mismo matar un proceso (SIGTERM) que forzarlo (SIGKILL).
- **Preferir `pkill` sobre `ps+grep+awk+kill`** en scripts. `pkill -f` busca en args completos, `pkill -x` busca nombre exacto.
- **Para recargar servicios**, usar SIGHUP (-1) cuando esté disponible. Evita downtime.

---

## 🔗 Referencias internas

- [`ps`](ps.md) — encontrar PIDs de procesos
- [`top`](top.md) — monitoreo de procesos en vivo
- [`fuser`](fuser.md) — identificar proceso por puerto
- [`lsof`](lsof.md) — identificar proceso por puerto o archivo
- [`systemd_journalctl`](systemd_journalctl.md) — logs de servicios
