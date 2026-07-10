# 🧩 Escenario: Fork bomb — explosión de procesos en producción

**Dominio:** system
**Nivel:** 🔴 Avanzado
**Herramientas:** `ps`, `ulimit`, `pkill`, `exec`, `systemctl`
**Archivos:** Sistema en vivo

---

## 🎯 Problema

El sistema se vuelve extremadamente lento o inaccesible en segundos. El número de procesos crece exponencialmente hasta agotar la tabla de procesos o los PIDs disponibles. Los usuarios no pueden iniciar nuevas sesiones ni ejecutar comandos. El servidor puede necesitar un reinicio forzado si no se contiene a tiempo.

---

## ⚡ Quick command (SRE)

```bash
ps aux | wc -l && ps axo pid,ppid,stat,comm | awk '$3 ~ /R|S/' | wc -l
```

---

## ✅ Salida esperada

- número de procesos > 5.000 (o creciendo rápidamente)
- muchos procesos en estado `R` (running) o `S` (sleeping) con el mismo nombre o PPID
- `fork: retry: Resource temporarily unavailable` en consola
- `cannot allocate memory` o `cannot fork` al intentar ejecutar comandos

Interpretación:

- proceso que se replica a sí mismo (fork bomb clásica)
- cada fork crea un hijo que a su vez hace fork
- la tabla de procesos se llena en segundos
- el sistema deja de responder porque no puede crear nuevos procesos

---

## 🧠 Diagnóstico

Una fork bomb es un proceso (o script) que se llama a sí mismo recursivamente mediante `fork()`, creando una explosión exponencial de procesos hijos. El objetivo (accidental o malicioso) es agotar los recursos del sistema.

Patrones clave:

- número de procesos creciendo exponencialmente → fork bomb confirmada
- todos los procesos hijos comparten el mismo nombre o PPID → origen común
- `fork: retry: Resource temporarily unavailable` → tabla de procesos llena
- el sistema no responde a nuevos comandos → sin PIDs disponibles
- `ps` tarda mucho o no responde → sistema sobrecargado

👉 En una fork bomb, cada segundo cuenta. La prioridad es contener, no investigar.

---

## 🛠️ Procedimiento (runbook)

### 1. Verificar si el sistema aún responde

```bash
uptime
```

Si el sistema no responde, intentar una consola remota (IPMI/iDRAC) o forzar reinicio.

### 2. Contar procesos actuales

```bash
ps aux | wc -l
```

Si el número es muy alto (> 5.000) y crece rápidamente, es una fork bomb.

### 3. Identificar el proceso origen

```bash
ps axo pid,ppid,stat,comm | awk '$3 ~ /R|S/ {print $0}' | sort -k2 -n | head -20
```

El PPID más bajo de la lista es probablemente el proceso original.

### 4. Verificar los límites actuales del sistema

```bash
ulimit -u
cat /proc/sys/kernel/pid_max
```

### 5. Contener la explosión (si el sistema aún responde parcialmente)

```bash
exec bash -c "kill -STOP -1"
```

Esto envía SIGSTOP a todos los procesos del usuario actual, congelándolos temporalmente.

---

## 🧯 Mitigación

Si se confirma una fork bomb activa:

Verificar:

```bash
ps axo pid,ppid,stat,comm | awk '$3 ~ /R|S/' | wc -l
```

Acción:

```bash
# Limitar procesos por usuario (prevenir recurrencia)
ulimit -u 1000

# Matar todos los procesos del usuario que originó la bomba
pkill -STOP -u <usuario>
sleep 2
pkill -KILL -u <usuario>
```

Mitigación adicional:

```bash
# Configurar límite permanente en /etc/security/limits.conf
# <usuario> hard nproc 1000
# <usuario> soft nproc 800
```

Rollback:

```bash
# Si se congelaron procesos con SIGSTOP, reanudar los que no son parte de la bomba
kill -CONT -1
# Reiniciar servicios críticos
systemctl restart sshd
```

Casos comunes:

- script mal escrito que se llama recursivamente → fork bomb accidental
- usuario que ejecuta `:(){ :|:& };:` en bash → fork bomb intencional
- aplicación con bug que hace fork infinito → fork bomb por software
- contenedor sin límites de procesos → fork bomb aislada que afecta al host

---

## ✅ Interpretación

- la explosión se detiene tras limitar `ulimit -u` → el problema era la falta de límites de procesos
- el proceso origen se identifica por PPID → se puede corregir el script o aplicación responsable
- el sistema se recupera sin reinicio → la contención fue exitosa
- el sistema no responde tras contención → probablemente necesitó reinicio forzado
- la fork bomb reaparece tras reinicio → hay un servicio o cron job que la inicia automáticamente

---

## 🐧 Variante Alpine (OpenRC)

> Este escenario usa `systemctl` en mitigación.

### Variante A — solo systemctl

```bash
# Debian:                          # Alpine:
systemctl restart sshd              rc-service sshd restart
```

En Alpine, los límites de procesos se configuran en `/etc/conf.d/` o directamente con `ulimit` en el shell.

---

## 🧑‍🏫 Modo docente

**Preguntas:** ¿Por qué SIGSTOP es mejor que SIGKILL para contener una fork bomb? ¿Cómo evitás que vuelva a ocurrir? ¿Qué hace exactamente ulimit -u?

**Ejercicio:** Contener una fork bomb con SIGSTOP, matar los procesos de forma controlada, configurar ulimit permanente.

**Evaluación:** contención segura (SIGSTOP primero), limpieza controlada, límite permanente configurado y verificado.

---

## 🔗 Referencias

- [`ps`](../../guides/ps.md) — visualización de procesos
- [`top`](../../guides/top.md) — monitoreo en tiempo real
- [`scenarios/system/04-high-cpu-runaway-process.md`](04-high-cpu-runaway-process.md) — proceso runaway (similar pero diferente)
- [`scenarios/system/08-zombie-processes.md`](08-zombie-processes.md) — procesos zombie (diferente causa)
