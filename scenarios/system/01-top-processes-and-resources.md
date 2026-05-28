⬅️ [Volver a scenarios](../README.md)

# 🧩 Escenario: Identificar procesos que consumen más recursos

**Dominio:** system
**Nivel:** 🟢 Básico
**Herramientas:** `ps`, `sort`, `awk`, `grep`, `watch`, `column`
**Datos:** Sistema en vivo (`ps aux`), logs (`labs/syslog.log`)

---

## 🎯 Problema

El sistema presenta alto consumo de recursos o degradación de rendimiento, lo que puede afectar la disponibilidad de servicios. Es necesario analizar los procesos en ejecución para:

- identificar procesos que más CPU, memoria y disco consumen
- detectar anomalías: procesos zombie, memory leaks, threads excesivos
- proponer acciones de mitigación (matar procesos, reiniciar servicios, escalar)

---

## ⚡ Quick command (SRE)

`ps aux | sort -k3 -rn | head -11`

---

## ✅ Salida esperada

```
USUARIO  CPU%  MEM%  COMANDO
root     85.2   2.3  /usr/bin/python3 /app/worker.py
admin     5.1  12.4  /usr/lib/mysql/mysqld
admin     2.0   0.1  nginx: worker process
...
```

Interpretación:

- \>80% sostenido en un proceso → posible bucle infinito o proceso intensivo
- uso alto pero variable → carga legítima
- varios procesos 10–50% → carga normal
- <5% → sistema en reposo

---

## 🧠 Diagnóstico

El uso de CPU y memoria debe interpretarse en contexto, no como valores absolutos.

Patrones relevantes:

- CPU alta sostenida en un proceso → posible bucle infinito o problema en aplicación
- CPU alta pero variable → carga legítima
- procesos en estado `D` → cuello de botella en disco
- procesos zombie acumulados → problema en manejo de procesos

👉 No toda CPU alta es un problema: lo importante es el patrón y la persistencia.

---

## 🛠️ Validación extendida

### Top por uso de memoria

```bash
ps aux \
  | sort -k4 -rn \
  | head -11 \
  | awk 'NR==1{printf "%-8s %-5s %-6s %-5s %s\n","USUARIO","PID","MEM%","RSS","COMANDO"}
         NR>1{printf "%-8s %-5s %-6s %-5s %s\n",$1,$2,$4,$6,$11}'
```

### Memoria total usada por usuario

```bash
ps aux \
  | awk 'NR>1 { mem[$1] += $4; cpu[$1] += $3 }
         END {
           print "USUARIO    CPU%    MEM%"
           for (u in mem) printf "%-10s %-6.1f %-6.1f\n", u, cpu[u], mem[u]
         }' \
  | sort -k3 -rn
```

### Detectar procesos zombie

```bash
# Los procesos con estado Z no consumen CPU pero llenan la tabla de procesos
ps aux \
  | awk '$8 ~ /Z/ { print $2, $8, $11, "-> ZOMBIE!" }'
```

### Contar procesos por estado

```bash
ps aux \
  | awk 'NR>1 { estados[substr($8,1,1)]++ }
         END {
           for (e in estados) {
             if (e=="R") desc="Running"
             if (e=="S") desc="Sleeping"
             if (e=="D") desc="Disk sleep (I/O)"
             if (e=="Z") desc="Zombie"
             if (e=="T") desc="Stopped"
             print e, desc, estados[e]
           }
         }' \
  | sort -k3 -rn
```

### Procesos con más hilos

```bash
ps aux \
  | awk 'NR>1 { print $2, $11 }' \
  | while read pid cmd; do
      threads=$(ls /proc/$pid/task 2>/dev/null | wc -l)
      [ -n "$threads" ] && echo "$threads $pid $cmd"
    done \
  | sort -rn \
  | head -10 \
  | column -t
```

### Memoria en formato humano (MB)

```bash
ps aux \
  | sort -k4 -rn \
  | head -10 \
  | awk '{ rss_mb = $6 / 1024; printf "%-20s %6.1f MB %s\n", $11, rss_mb, $2 }'
```

### Detectar memory leak (watch cada 5 segundos)

```bash
watch -n 5 '
  ps aux \
    | grep "mi_proceso" \
    | grep -v grep \
    | awk "{print \$3, \$4, \$11}"
'
```

> Si la columna %MEM sube sin bajar, hay memory leak.

### Archivos abiertos por proceso (top 10)

```bash
for pid in $(ps aux --sort=-%mem | awk 'NR>1{print $2}' | head -10); do
  cmd=$(ps -p $pid -o comm= 2>/dev/null)
  fds=$(ls /proc/$pid/fd 2>/dev/null | wc -l)
  [ -n "$fds" ] && echo "$fds $pid $cmd"
done | sort -rn | column -t
```

---

## 🧯 Mitigación (acciones seguras)

### 1. Matar un proceso que consume demasiado

```bash
# Primero identificar el PID del pipeline de CPU
# Luego enviar señal gradual:

kill -15 <PID>      # SIGTERM (cierre limpio)
sleep 5
kill -9 <PID>       # SIGKILL (forzado, solo si no respondió)
```

### 2. Gestionar procesos zombie

```bash
# Los zombies no se pueden matar. Hay que matar al PADRE:
ps -o pid,ppid,state,cmd -p <PID_ZOMBIE>
kill -15 <PPID>     # Si el padre es un proceso de app
# Si el padre es init (PID 1), el zombie se limpia solo al reboot
```

### 3. Liberar memoria (último recurso)

```bash
# Forzar limpieza de cache (NO mata procesos, solo cache del kernel)
sync && echo 3 > /proc/sys/vm/drop_caches
```

### 4. Rollback por servicio

```bash
# Si mataste un servicio crítico, reiniciarlo:
systemctl restart <servicio>
# O volver a levantar el proceso manualmente:
/path/al/comando &
```

---

## 🛡️ Prevención (hardening / buenas prácticas)

- [ ] Monitorear con `nagios`/`netdata` o al menos `cron` + `ps` alertas
- [ ] Limitar recursos por servicio con systemd (`MemoryMax`, `CPUQuota`)
- [ ] Usar `monit` para auto-reinicio de procesos caídos
- [ ] Configurar logrotate para evitar que logs crezcan sin control
- [ ] Tener `swap` suficiente para picos de memoria
- [ ] Revisar periódicamente con `ps aux --sort=-%mem | head -20`

---

## 🧪 Variantes

### OOM killer (qué proceso mató el sistema)

```bash
journalctl -k | grep -i "oom_kill" | tail -5
```

### Tiempo de actividad del proceso más longevo

```bash
ps -eo pid,etime,cmd --sort=-etime | head -10
```

### Procesos sin terminal (daemons)

```bash
ps aux | awk '$7 == "?" { print $11, $2 }'
```

---

## 🧑‍🏫 Modo docente

### Ejercicio 1

1. Ejecutá el quick run y reportá el top 3 por CPU.
2. Identificá si algún proceso tiene >80% y explicá qué harías.
3. Verificá si hay procesos zombie.

### Ejercicio 2

1. ¿Cuántos procesos hay en estado `D`? ¿Qué indica?
2. ¿Algún usuario tiene procesos acumulados inusuales?
3. Simulá un memory leak con `stress --vm 1 --vm-bytes 256M` y detectalo.

### Criterios de evaluación

- usa correctamente `ps aux` y sus columnas
- sabe diferenciar memoria RSS vs %MEM
- identifica estados de proceso (R, S, D, Z, T)
- propone mitigación gradual (SIGTERM antes que SIGKILL)

---

## 🧪 Cómo practicarlo en el lab

```bash
# 1. Iniciar el contenedor que quema CPU
cd labs && docker compose -f docker-compose.broken.yml up -d cpu-hog loopback-down

# 2. Entrar al contenedor y ver el proceso que consume CPU
docker exec -it cpu-hog sh
ps aux | sort -k3 -rn | head -5
```

También podés probar los pipelines contra `labs/syslog.log` para practicar filtros sin afectar el sistema.

[Ver laboratorio completo →](../../labs/README.md)

---

## 🐧 Variante Alpine (OpenRC + herramientas)

Este escenario asume systemd (Debian/Ubuntu). En Alpine Linux (contenedor Docker mínimo) se usa OpenRC y algunas herramientas requieren instalación adicional.

### Gestión de servicios

```bash
# Debian (systemd):                # Alpine (OpenRC):
systemctl restart <svc>             rc-service <svc> restart
systemctl status <svc>              rc-service <svc> status
systemctl enable --now <svc>        rc-update add <svc> default && rc-service <svc> start
systemctl stop <svc>                rc-service <svc> stop
systemctl start <svc>               rc-service <svc> start
```

### Logs del sistema

```bash
# Debian:                          # Alpine:
journalctl -k | grep oom_kill       dmesg | grep oom_kill
journalctl -u <svc> -n 20           logread | grep <svc>
```

### Herramientas adicionales

`watch`, `column` y `bc` no vienen en BusyBox (shell mínima de Alpine):

```bash
apk add procps     # watch
apk add util-linux # column
apk add bc         # bc
```

Alternativas sin instalar nada:

```bash
# Con paquete:                    # Sin instalar:
watch -n 5 '<comando>'             while true; do clear; <comando>; sleep 5; done
echo "2+2" | bc                    awk 'BEGIN {print 2+2}'
column -t archivo                  awk '{ printf "%-20s %-10s\n", $1, $2 }' archivo
```

---

## 🔗 Referencias (guías del repo)

- [`awk`](../../guides/awk.md) — arrays asociativos y formateo
- [`sort`](../../guides/sort.md) — ordenamiento numérico por campo
- [`grep`](../../guides/grep.md) — filtrado de procesos
- [`xargs`](../../guides/xargs.md) — actuar sobre procesos encontrados
- [`production_server`](../../guides/production_server.md) — systemd resource control, monitoreo
- [`apk`](../../guides/apk.md) — Alpine Linux: gestor de paquetes
- [`openrc`](../../guides/openrc.md) — Alpine Linux: servicios (rc-service, rc-update)
- [`busybox`](../../guides/busybox.md) — Alpine Linux: toolchain mínima (logread, dmesg)
