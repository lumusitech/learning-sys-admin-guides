# Señales de Linux — Referencia rápida

Señales esenciales para la administración de procesos en Linux.

---

## 📊 Tabla de señales

| Señal | N° | Acción por defecto | Qué hace |
|-------|----|--------------------| ---------|
| SIGHUP | 1 | Terminar | Colgar. Recargar config en muchos servicios (nginx, sshd, syslog) |
| SIGINT | 2 | Terminar | Interrupción desde teclado (Ctrl+C) |
| SIGQUIT | 3 | Terminar + core dump | Salida con volcado de memoria para debug |
| SIGKILL | 9 | Terminar | Mata el proceso inmediatamente. No puede ser ignorada ni capturada |
| SIGTERM | 15 | Terminar | Terminación ordenada. Permite limpieza antes de salir |
| SIGUSR1 | 10 | Terminar | Definida por el usuario. Usada por muchos servicios para recargar logs |
| SIGUSR2 | 12 | Terminar | Definida por el usuario. Usos variados según el servicio |
| SIGCHLD | 17 | Ignorar | Proceso hijo terminó. Útil para reap en procesos padre |
| SIGSTOP | 19 | Detener | Pausa el proceso. No puede ser ignorada ni capturada |
| SIGCONT | 18 | Continuar | Reanuda un proceso detenido |
| SIGTSTP | 20 | Detener | Pausa desde teclado (Ctrl+Z) |
| SIGPIPE | 13 | Terminar | Escritura en un pipe roto (extremo lector cerró) |
| SIGALRM | 14 | Terminar | Timer expirado (alarma del sistema) |

---

## 🎯 Cómo se usan en administración

| Acción | Comando |
|--------|---------|
| Terminar proceso ordenadamente | `kill -TERM <PID>` |
| Forzar terminación | `kill -KILL <PID>` o `kill -9 <PID>` |
| Recargar configuración | `kill -HUP <PID>` |
| Rotar logs (muchos servicios) | `kill -USR1 <PID>` |
| Pausar un proceso | `kill -STOP <PID>` |
| Reanudar un proceso pausado | `kill -CONT <PID>` |
| Matar todos los procesos por nombre | `pkill -TERM <nombre>` |
| Enviar señal por nombre | `pkill -HUP <nombre>` |

---

## 🧠 Reglas prácticas

- **SIGTERM (15) es la primera opción** — da tiempo al proceso para hacer limpieza
- **SIGKILL (9) es el último recurso** — el proceso muere sin cerrar archivos ni liberar recursos
- **SIGHUP (1) para recargar config** sin reiniciar el servicio
- **SIGUSR1 (10)** es el estándar de facto para rotación de logs (nginx, Apache, syslog-ng)
- **SIGSTOP/SIGCONT** útiles para congelar procesos temporalmente sin matarlos
- Si envías SIGTERM y el proceso no termina, primero verificá si está en estado D (uninterruptible sleep)

---

## 🚨 Señales en logs y troubleshooting

```bash
# Ver si un proceso murió por señal
dmesg | grep -i "killed process"
journalctl -k | grep -i "killed"

# Proceso terminado por OOM killer → SIGKILL
dmesg | grep -i oom

# Ver señal de salida de un proceso
# 137 = 128 + 9 (SIGKILL)
# 143 = 128 + 15 (SIGTERM)
# La convención es: código de salida = 128 + número de señal

# Ejemplo en scripts
wait $PID
echo "Exit code: $?"  # 137 = SIGKILL, 143 = SIGTERM
```

---

## 📋 Resumen rápido de señales por caso

| Situación | Señal |
|-----------|-------|
| El servicio no responde pero necesita cerrar archivos | SIGTERM |
| El servicio no responde ni a SIGTERM | SIGKILL |
| Cambiaste la config y querés que recargue | SIGHUP |
| Querés rotar logs sin reiniciar | SIGUSR1 |
| Un proceso está consumiendo CPU y querés pausarlo | SIGSTOP |
| Querés reanudar un proceso pausado | SIGCONT |
| Ctrl+C no funciona y querés un core dump | SIGQUIT |

---

## 🔍 Cómo usarlo en diagnóstico

```bash
# Ver señales enviadas a un proceso
kill -l

# Enviar señal y verificar resultado
kill -TERM <PID>
ps -p <PID> -o stat,pid,cmd

# Verificar si un proceso fue matado por OOM
dmesg | grep -i "killed process"

# Código de salida: 128 + número de señal
# 137 = 128 + 9 (SIGKILL)
# 143 = 128 + 15 (SIGTERM)
```

---

## 🔗 Ver también

- [`top`](../guides/top.md) — visualización y envío de señales desde top/htop
- [`ps`](../guides/ps.md) — localizar PIDs para kill
- [`scenarios/system/04-high-cpu-runaway-process.md`](../scenarios/system/04-high-cpu-runaway-process.md) — uso de kill en procesos runaway
