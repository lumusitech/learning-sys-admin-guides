
 Escenario: Procesos zombie (defunct) en Linux

---

## 🎯 Problema

El sistema muestra procesos en estado `Z` o `<defunct>` y, con el tiempo, podrían acumularse hasta agotar entradas de la tabla de procesos o PIDs disponibles. Es necesario identificar los procesos zombie, encontrar su proceso padre y corregir la causa real. [1](https://oneuptime.com/blog/post/2026-01-24-fix-zombie-process-issues/view)[2](https://linuxvox.com/blog/zombie-process-linux/)[3](https://en.wikipedia.org/wiki/Zombie_process)

---

## ⚡ Quick command (SRE)

```bash
ps axo stat,ppid,pid,comm | awk '$1 ~ /^Z/'
```

---

## ✅ Salida esperada

- procesos con estado Z
- PID del proceso zombie
- PPID (proceso padre) asociado
- comando o binario relacionado

Interpretación:

- Z → el proceso ya terminó, pero no fue recolectado por su padre (wait() / waitpid())
- el PID del zombie no es accionable: el problema real es el PPID (proceso padre)
- muchos zombies → riesgo de agotar entradas de la tabla de procesos o PIDs disponibles
- no se puede matar un proceso zombie → ya está terminado

---

## 🧠 Diagnóstico

Un proceso zombie es un proceso que ya terminó, pero sigue teniendo una entrada en la tabla de procesos porque el padre todavía no leyó su estado de salida mediante `wait()` o `waitpid()`.

Patrones clave:

- Z o <defunct> en ps → proceso zombie confirmado
- zombie aislado → normalmente no es crítico por sí solo, pero indica que el padre no está recolectando bien a sus hijos
- muchos zombies → pueden agotar PIDs / tabla de procesos y bloquear creación de procesos nuevos
- matar el zombie directamente no sirve → la acción real está sobre el padre o el servicio que lo origina

👉 Un zombie es un síntoma: el problema real casi siempre es el proceso padre que no lo reap.

---

## 🛠️ Procedimiento (runbook)

### 1. Detectar procesos zombie y su padre

```bash
ps axo stat,ppid,pid,comm | grep -w Z
```

### 2. Inspeccionar el proceso padre

```bash
ps -p <PPID> -o pid,ppid,cmd,comm,stat
```

### 3. Ver la relación padre-hijo

```bash
pstree -p <PPID>
```

### 4. Ver si se acumulan con el tiempo

```bash
ps -eo stat | awk '$1 ~ /^Z/ {count++} END {print count}'
```

### 5. Revisar logs del servicio o proceso padre

```bash
journalctl -u <servicio> --no-pager | tail -20
```

### 6. Confirmar si el padre está gestionado por systemd

```bash
systemctl status <servicio>
```

---

## 🧯 Mitigación

Si se detectan procesos zombie:

Verificar:

```bash
ps axo stat,ppid,pid,comm | grep -w Z
ps -p <PPID> -o pid,ppid,cmd,comm,stat
```

Acción:

```bash
# opción preferida: reiniciar el servicio padre
# los zombies desaparecen cuando el padre hace wait() o termina
systemctl restart <servicio>
```

Mitigación adicional:

```bash
# si no hay servicio y el padre sigue vivo, terminar al padre como último recurso
kill -TERM <PPID>
```

Último recurso:

```bash
kill -9 <PPID>
```

Rollback:

```bash
# si el padre era un servicio gestionado
systemctl restart <servicio>
```

Casos comunes:

- proceso padre con bug → no ejecuta wait() / waitpid() correctamente
- demonio o servicio colgado → deja zombies acumulándose
- contenedor o app con mala gestión de hijos → proliferación de zombies y presión sobre PIDs

---

## ✅ Interpretación

- el zombie desaparece tras reiniciar el padre → el problema estaba en el proceso padre/servicio
- el zombie persiste → revisar si el padre sigue vivo o si el servicio vuelve a crear hijos zombies por un bug
- el número de zombies crece → riesgo operativo real por agotamiento de PID/tabla de procesos

---

## 🔗 Referencias

- [systemd_journalctl.md](../../guides/systemd_journalctl.md)
- [grep.md](../../guides/grep.md)
- [awk.md](../../guides/awk.md)
