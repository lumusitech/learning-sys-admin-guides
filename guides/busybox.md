# BusyBox — Guía completa

**Nivel:** 🟢 Básico
**Archivos de práctica:** Sistema en vivo (Alpine Linux)
**Ver escenarios relacionados:** Todos los escenarios con Variante Alpine en [`scenarios/`](../scenarios/)

---

## ⚡ Quick command

`busybox --list`

---

## ⚡ Quick run

```bash
busybox | head -20
```

---

## 📑 Índice

1. [¿Qué es BusyBox?](#qué-es-busybox)
2. [Modelo mental](#modelo-mental)
3. [Sintaxis básica](#sintaxis-básica)
4. [Comandos integrados](#comandos-integrados)
5. [Comandos core del sistema](#comandos-core-del-sistema)
6. [Herramientas que no están en BusyBox](#herramientas-que-no-están-en-busybox)
7. [Alternativas desde procps / util-linux](#alternativas-desde-procps--util-linux)
8. [Logs y syslog](#logs-y-syslog)
9. [Uno-liners imprescindibles](#uno-liners-imprescindibles)
10. [Errores comunes](#errores-comunes)
11. [Buenas prácticas](#buenas-prácticas)

---

## 🧠 ¿Qué es BusyBox?

**BusyBox** es un único binario que implementa cientos de comandos Unix (grep, awk, sed, ps, top, df, du, etc.) en un solo ejecutable de menos de 1 MB. Es el corazón de Alpine Linux y de contenedores Docker mínimos.

Cada comando es un **applet** dentro del binario. Cuando se invoca como `grep`, BusyBox detecta que lo llamaron con ese nombre y ejecuta el applet grep.

No todas las herramientas de BusyBox tienen las mismas opciones que sus versiones completas (GNU coreutils, procps-ng, util-linux). Por eso algunos comandos que funcionan en Ubuntu/Debian fallan en Alpine.

---

## 🧠 Modelo mental

BusyBox es como una navaja suiza: tiene casi todo lo que necesitás, pero cada herramienta es una versión minimalista. Si en Debian usás `ps aux --sort=-%cpu`, en BusyBox tenés que usar `ps aux | sort -k3 -rn`.

La regla: **los comandos POSIX básicos funcionan idéntico; las opciones GNU-only no están.**

---

## 📝 Sintaxis básica

```bash
busybox <applet> [argumentos]
```

```bash
busybox --list                   # Listar todos los applets disponibles
busybox --list-full              # Listar con paths completos
busybox | head -20               # Versión y lista compacta
busybox sh                       # Shell integrado (ash)
busybox grep "patrón" archivo    # Llamar explícitamente un applet
```

Cada applet también puede llamarse directamente como comando separado (porque Alpine crea symlinks):

```bash
grep --help          # Muestra la ayuda del applet grep de BusyBox
# vs
grep -P              # ERROR: -P no existe en BusyBox
```

---

## Comandos integrados

### Texto y procesamiento

| Comando | Disponible | Limitaciones vs GNU |
|---------|-----------|---------------------|
| `grep` | ✅ | Sin `-P` (PCRE), sin `--color=auto` por defecto |
| `awk` | ✅ | Sin `--non-decimal-data`, sin `strftime` completo |
| `sed` | ✅ | Sin `-z` (null-separated), sin `--follow-symlinks` |
| `cut` | ✅ | Limitaciones en delimitadores complejos |
| `sort` | ✅ | Sin `-V` (version sort) |
| `uniq` | ✅ | Completo |
| `wc` | ✅ | Completo |
| `head` | ✅ | Completo |
| `tail` | ✅ | Sin `--follow=name` |
| `tr` | ✅ | Completo |
| `xargs` | ✅ | Sin `-o`, `-P` limitado |

### Sistema y procesos

| Comando | Disponible | Limitaciones |
|---------|-----------|--------------|
| `ps` | ✅ | Sin `--sort`, sin `axo` (usar `ps aux`, `ps -eo`) |
| `top` | ✅ | Sin `-u`, sin `-b -n` (modo batch); solo interactivo |
| `free` | ✅ | Sin `-h` (formato humano), sin `--si` |
| `df` | ✅ | Sin `--output`, sin `-T` por defecto |
| `du` | ✅ | Sin `--max-depth` (usar `-d`) |
| `kill` | ✅ | Completo |
| `pidof` | ✅ | Sin opciones avanzadas |
| `mount` | ✅ | Completo |
| `watch` | ❌ | No incluido |

### Red

| Comando | Disponible |
|---------|-----------|
| `ping` | ✅ |
| `nc` | ✅ (netcat minimalista) |
| `nslookup` | ✅ (básico) |
| `ip` | ❌ (no es applet, es iproute2, disponible en Alpine como paquete) |

---

## Herramientas que no están en BusyBox

Estas herramientas no vienen en el binario BusyBox. Para usarlas en Alpine, instalalas con `apk add`:

| Herramienta | Paquete | Instalación |
|------------|---------|-------------|
| `watch` | procps (o watch) | `apk add procps` |
| `column` | util-linux | `apk add util-linux` |
| `bc` | bc | `apk add bc` |
| `lsof` | lsof | `apk add lsof` |
| `ip` | iproute2 | `apk add iproute2` |
| `ss` | iproute2 | `apk add iproute2` |
| `iostat` | sysstat | `apk add sysstat` |
| `vmstat` | procps | `apk add procps` |
| `iotop` | iotop | `apk add iotop` |
| `htop` | htop | `apk add htop` |
| `strace` | strace | `apk add strace` |
| `tcpdump` | tcpdump | `apk add tcpdump` |
| `dig` | bind-tools | `apk add bind-tools` |
| `nslookup` (full) | bind-tools | `apk add bind-tools` |
| `rsync` | rsync | `apk add rsync` |
| `mtr` | mtr | `apk add mtr` |

---

## Logs y syslog

BusyBox incluye su propio sistema de logs minimalista, manejado por `logread`.

```bash
logread                     # Leer logs del ring buffer del kernel
logread -f                  # Seguir logs en tiempo real (tail -f)
logread | grep error        # Filtrar por error
dmesg                       # Mensajes del kernel (compatible con GNU)
```

A diferencia de `journalctl`, `logread` no filtra por servicio, no tiene `--since`/`--until`, y el buffer es circular (se pierden los mensajes más viejos cuando se llena).

Para logs persistentes en Alpine, instalar:

```bash
apk add rsyslog                     # logs persistentes en /var/log/messages
rc-update add rsyslog default
rc-service rsyslog start
```

---

## 💡 Uno-liners imprescindibles

```bash
busybox --list                                   # Qué applets hay
busybox | head -5                                # Versión de BusyBox
busybox --help                                   # Ayuda general
logread | tail -20                               # Últimos logs del sistema
dmesg | tail -20                                 # Últimos mensajes del kernel
watch -n 2 'ps aux | sort -k3 -rn | head -10'   # Top CPU (con procps instalado)
```

---

## ⚠️ Errores comunes

- **Usar `ps aux --sort=-%cpu`**. En BusyBox, `--sort` no existe. Alternativa: `ps aux | sort -k3 -rn`.
- **Usar `top -b -n 1`**. En BusyBox, `top` solo es interactivo, no tiene modo batch. Alternativa: `ps aux | sort -k3 -rn | head -10`.
- **Usar `grep -P` (PCRE)**. En BusyBox, no existe. Usar `grep -E` para ERE.
- **Usar `free -h`**. En BusyBox puede no estar disponible el `-h`. Usar `free` (KB) o `awk` para formatear.
- **Asumir que `watch` existe**. No está en BusyBox. Instalar con `apk add procps` o usar `while true; do clear; comando; sleep 2; done`.
- **Asumir que `column` existe**. No está en BusyBox. Usar `printf` con `awk` o instalar `apk add util-linux`.
- **Asumir que `bc` existe**. No está en BusyBox. Para cuentas simples, usar `awk 'BEGIN {print ...}'`.

---

## ✅ Buenas prácticas

- Antes de escribir un script con opciones GNU, verificar si va a correr en Alpine. Usar alternativas POSIX.
- Para scripts portables, usar `ps -eo` en vez de `ps aux` con `--sort`.
- Para formateo de columnas, usar `awk '{ printf "%-20s %-10s\n", $1, $2 }'` en vez de `column -t`.
- Para watch, instalar `procps` o crear un loop shell.
- Para filtrar logs, usar `logread | grep` en vez de `journalctl`.
- Verificar siempre: `busybox --list | grep <comando>` para saber si está disponible.

---

## 🔗 Referencias internas

- [`apk`](../apk.md) — gestor de paquetes de Alpine Linux
- [`openrc`](../openrc.md) — gestión de servicios en Alpine
- [`systemd_journalctl`](../systemd_journalctl.md) — sistema de init alternativo (Debian/Ubuntu)
