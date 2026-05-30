# tmux — Guía completa

**Nivel:** 🟢 Básico
**Archivos de práctica:** Sistema en vivo
**Ver escenarios relacionados:** [`system/04-high-cpu-runaway-process.md`](../scenarios/system/04-high-cpu-runaway-process.md), [`infrastructure/03-new-server-provisioning.md`](../scenarios/infrastructure/03-new-server-provisioning.md)

---

## ⚡ Quick command

`tmux new -s trabajo`

> ⚠️ `tmux` no está instalado por defecto en muchas distros. Instalar con `apt install tmux` o `apk add tmux`. En servidores mínimos, puede no estar disponible.

---

## ⚡ Quick run

```bash
tmux new -s debug
```

---

## 📑 Índice

1. [¿Qué es tmux?](#qué-es-tmux)
2. [Modelo mental](#modelo-mental)
3. [Sintaxis básica](#sintaxis-básica)
4. [El prefix key](#el-prefix-key)
5. [Sesiones](#sesiones)
6. [Windows (tabs)](#windows-tabs)
7. [Panes (división de pantalla)](#panes-división-de-pantalla)
8. [Modo copia](#modo-copia)
9. [Opciones de línea de comandos](#opciones-de-línea-de-comandos)
10. [Configuración básica (~/.tmux.conf)](#configuración-básica)
11. [Uso en troubleshooting](#uso-en-troubleshooting)
12. [Combinación con otras herramientas](#combinación-con-otras-herramientas)
13. [Uno-liners imprescindibles](#uno-liners-imprescindibles)
14. [Errores comunes](#errores-comunes)
15. [Buenas prácticas](#buenas-prácticas)

---

## 🧠 ¿Qué es tmux?

`tmux` es un **terminal multiplexer**: permite múltiples terminales virtuales dentro de una sola sesión, dividir la pantalla en paneles, y —lo más importante— **mantener sesiones vivas** aunque te desconectes de SSH.

- qué hace: multiplexa terminales, gestiona sesiones persistentes, divide la pantalla
- para qué sirve: mantener procesos largos vivos (compilaciones, logs, servidores), trabajar con múltiples terminales en una sola conexión SSH
- cuándo usarlo: siempre que te conectés por SSH y necesités que algo siga corriendo al desconectarte
- cuándo NO usarlo: en scripts automatizados (usar `nohup` o `systemd`), cuando solo necesitás un comando rápido

---

## 🧠 Modelo mental

`tmux` tiene tres niveles:

```text
server (tmux)
  └── session (sesión nombrada)
        └── window (tab/ventana)
              └── pane (panel dividido)
```

- **Session**: espacio de trabajo independiente. Sobrevive a la desconexión de SSH.
- **Window**: como pestañas del navegador. Cada sesión tiene al menos una.
- **Pane**: división dentro de una ventana. Permite ver múltiples terminales a la vez.

Piensalo así:

- `tmux` = oficina virtual que no se cierra cuando te vas
- session = escritorio con nombre
- window = pestaña del escritorio
- pane = monitor dividido en esa pestaña

---

## 📝 Sintaxis básica

```bash
tmux [comando] [opciones]
```

Sin opciones abre una nueva sesión anónima.

---

## 🔑 El prefix key

Todo en tmux arranca con el **prefix key**: `Ctrl + B`

Después de presionar `Ctrl + B`, soltar, y presionar otra tecla.

Ejemplo: `Ctrl + B → d` significa: presionar Ctrl+B, soltar, luego presionar d.

---

## 📋 Sesiones

| Acción | Comando |
|--------|---------|
| Crear sesión anónima | `tmux` |
| Crear sesión con nombre | `tmux new -s nombre` |
| Listar sesiones | `tmux ls` |
| Reconectar a sesión | `tmux attach -t nombre` |
| Reconectar (atajo corto) | `tmux a -t nombre` |
| Desconectar (mantener viva) | `Ctrl + B → d` |
| Matar sesión | `tmux kill-session -t nombre` |
| Matar todas las sesiones | `tmux kill-server` |
| Cambiar de sesión | `Ctrl + B → s` |
| Renombrar sesión | `Ctrl + B → $` |

> **Desconectar vs cerrar**: `Ctrl + B → d` desconecta pero mantiene la sesión viva. `exit` cierra la sesión y sus paneles.

---

## 🪟 Windows (tabs)

| Acción | Atajo |
|--------|-------|
| Nueva ventana | `Ctrl + B → c` |
| Siguiente ventana | `Ctrl + B → n` |
| Ventana anterior | `Ctrl + B → p` |
| Ir a ventana por número | `Ctrl + B → 0-9` |
| Renombrar ventana | `Ctrl + B → ,` |
| Listar ventanas | `Ctrl + B → w` |
| Cerrar ventana | `Ctrl + B → &` |
| Mover ventana | `Ctrl + B → .` |

---

## 🪟 Panes (división de pantalla)

| Acción | Atajo |
|--------|-------|
| Dividir vertical (lado a lado) | `Ctrl + B → %` |
| Dividir horizontal (arriba/abajo) | `Ctrl + B → "` |
| Navegar entre panes | `Ctrl + B → flechas` |
| Cerrar pane actual | `Ctrl + B → x` |
| Cerrar con exit | `exit` o `Ctrl + D` |
| Cambiar tamaño de pane | `Ctrl + B → Ctrl + flechas` |
| Rotar paneles | `Ctrl + B → o` |
| Convertir pane en ventana | `Ctrl + B → !` |
| Mostrar números de pane | `Ctrl + B → q` |
| Reorganizar layouts | `Ctrl + B → espacio` |
| Zoom de pane (maximizar/restaurar) | `Ctrl + B → z` |

---

## 📋 Modo copia

| Acción | Atajo |
|--------|-------|
| Entrar al modo copia (scroll) | `Ctrl + B → [` |
| Mover cursor | flechas o `h/j/k/l` |
| Iniciar selección | `Espacio` |
| Copiar selección | `Enter` |
| Salir del modo copia | `q` |
| Pegar contenido copiado | `Ctrl + B → ]` |
| Buscar hacia adelante | `/` |
| Buscar hacia atrás | `?` |
| Siguiente resultado | `n` |
| Resultado anterior | `N` |

---

## 🎛️ Opciones de línea de comandos

| Opción | Descripción |
|--------|-------------|
| `tmux new -s nombre` | Crear sesión con nombre |
| `tmux new -s nombre -d` | Crear sesión en background (sin attach) |
| `tmux ls` | Listar sesiones |
| `tmux attach -t nombre` | Conectar a sesión existente |
| `tmux kill-session -t nombre` | Matar sesión |
| `tmux kill-server` | Matar todas las sesiones |
| `tmux switch -t nombre` | Cambiar a otra sesión |
| `tmux send-keys -t nombre 'comando' Enter` | Enviar comando a sesión específica |
| `tmux capture-pane -t nombre` | Capturar contenido de un pane |
| `tmux list-keys` | Listar todos los atajos activos |
| `tmux source-file ~/.tmux.conf` | Recargar configuración |

---

## 🔧 Configuración básica

Archivo: `~/.tmux.conf`

```bash
# Cambiar prefix a Ctrl+A (más cómodo que Ctrl+B)
set -g prefix C-a
unbind C-b
bind C-a send-prefix

# Empezar numeración de ventanas en 1 (en vez de 0)
set -g base-index 1
setw -g pane-base-index 1

# Renumerar ventanas al cerrar una
set -g renumber-windows on

# Aumentar historial de scroll
set -g history-limit 10000

# Activar mouse (para seleccionar paneles, redimensionar, etc.)
set -g mouse on

# Colores y status bar
set -g default-terminal "screen-256color"
set -g status-style bg=colour235,fg=colour136

# Dividir paneles con | y - (más intuitivo)
bind | split-window -h
bind - split-window -v

# Recargar configuración con prefix + r
bind r source-file ~/.tmux.conf \; display "Config recargada"

# Navegar entre paneles con Alt+flechas (sin prefix)
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D
```

---

## 🔍 Uso en troubleshooting

### Mantener sesión durante deploy largo

```bash
# Conectar al servidor
ssh admin@servidor

# Crear sesión nombrada
tmux new -s deploy

# Ejecutar deploy
./deploy.sh

# Si SSH se corta, la sesión sigue viva
# Reconectar:
ssh admin@servidor
tmux attach -t deploy
```

### Monitorear múltiples servicios simultáneamente

```bash
# Crear sesión
tmux new -s monitoreo

# Dividir en paneles
# Ctrl+B → %  (vertical)
# Ctrl+B → "  (horizontal)

# En cada pane ejecutar un monitor:
# Pane 1: htop
# Pane 2: tail -f /var/log/syslog
# Pane 3: watch -n 2 'ss -s'
```

### Ejecutar comando en sesión remota sin attach

```bash
# Enviar comando a sesión existente
tmux send-keys -t trabajo 'free -h' Enter

# Crear sesión en background y ejecutar comando
tmux new -s backup -d 'rsync -avz /data/ /backup/'
```

---

## 🛠️ Combinación con otras herramientas

### Con SSH (sesiones persistentes)

```bash
# Conectar y attach/create automáticamente
ssh -t servidor "tmux attach -t trabajo || tmux new -s trabajo"
```

### Con htop (monitoreo persistente)

```bash
# Crear sesión de monitoreo
tmux new -s mon -d 'htop'
# Reconectar cuando quieras
tmux attach -t mon
```

### Con tail -f (logs persistentes)

```bash
tmux new -s logs -d 'tail -f /var/log/syslog'
tmux attach -t logs
```

---

## 💡 Uno-liners imprescindibles

```bash
# Crear sesión con nombre
tmux new -s trabajo

# Listar sesiones
tmux ls

# Reconectar a sesión
tmux attach -t trabajo

# Crear sesión en background
tmux new -s backup -d

# Enviar comando a sesión sin attach
tmux send-keys -t trabajo 'ls -la' Enter

# Matar sesión específica
tmux kill-session -t trabajo

# Matar todas las sesiones
tmux kill-server

# Ver paneles activos
tmux list-panes

# Ver ventanas de una sesión
tmux list-windows -t trabajo

# Capturar contenido visible de un pane
tmux capture-pane -t trabajo -p

# Renombrar ventana actual
tmux rename-window "logs"

# Ejecutar comando en todas las sesiones
tmux list-sessions -F '#S' | xargs -I {} tmux send-keys -t {} 'uptime' Enter
```

---

## ⚠️ Errores comunes

### Confundir desconectar con cerrar

`Ctrl + B → d` **desconecta** pero mantiene la sesión viva. `exit` **cierra** el pane/ventana/sesión.

### Olvidar que tmux no guarda estado

Si el servidor se reinicia, las sesiones tmux se pierden. Para persistencia real usar `systemd` o `docker`.

### No nombrar sesiones

Sin nombre (`tmux` a secas) es difícil reconectar. Siempre usar `tmux new -s nombre`.

### Confundir pane con ventana

Ventana = tab nueva (pantalla completa). Pane = división dentro de la misma ventana.

### Prefix key incorrecto

Si cambiaste el prefix en `.tmux.conf`, usar el nuevo. El default es `Ctrl + B`.

---

## ✅ Buenas prácticas

- siempre nombrar sesiones: `tmux new -s nombre`
- usar `Ctrl + B → d` para desconectar, no `exit`
- configurar `~/.tmux.conf` con opciones útiles (mouse, base-index 1)
- usar `send-keys` para automatización remota sin attach
- combinar con SSH con `ssh -t servidor "tmux attach || tmux new -s trabajo"`
- usar paneles (`%` y `"`) para monitoreo múltiple en una ventana
- usar modo copia (`[`) para scroll y copiar texto de la terminal

---

## 🔗 Referencias internas

- [`ssh`](ssh.md) — conexión remota y sesiones persistentes (sección tmux en ssh.md)
- [`htop`](htop.md) — monitoreo de procesos interactivo
- [`watch`](watch.md) — ejecución periódica de comandos
