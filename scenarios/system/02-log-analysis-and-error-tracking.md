⬅️ [Volver a scenarios](../README.md)

# 🧩 Escenario: Análisis de logs del sistema y tracking de errores

**Dominio:** system
**Nivel:** 🟢 Básico
**Herramientas:** `grep`, `awk`, `sort`, `uniq`, `sed`, `journalctl`, `tail`
**Archivos:** `labs/syslog.log`

---

## 🎯 Problema

El sistema genera errores en distintos servicios que pueden afectar la estabilidad o disponibilidad. Es necesario analizar los logs para:

- identificar los servicios que más errores generan
- detectar patrones de error cíclicos y problemas de recursos (OOM, disco)
- generar reportes de errores por hora y por servicio

---

## ⚡ Quick command (SRE)

`grep -iE 'error|fail|critical' labs/syslog.log | awk '{c[$5]++} END{for(s in c) print c[s], s}' | sort -rn | head -10`

---

## ✅ Salida esperada

```
150 sshd
 89 kernel
 45 mysqld
```

Interpretación:

- `kernel` con muchos errores → posible fallo de hardware (disco, memoria)
- `sshd` con muchos errores → posible ataque de fuerza bruta
- servicio de aplicación con errores → bug o fuga de recursos

---

## 🧠 Diagnóstico

Los logs deben analizarse buscando patrones, no eventos aislados.

Patrones relevantes:

- muchos errores del mismo servicio → posible falla interna o bug
- errores distribuidos en varios servicios → problema del sistema (red, disco, recursos)
- errores repetitivos con mismo mensaje → problema cíclico
- picos de errores en una ventana de tiempo → incidente activo

👉 Un solo error no indica problema: la repetición y concentración son la señal real.

---

## 🛠️ Validación extendida

### Errores por hora

```bash
grep -i "error\|fail\|critical" labs/syslog.log | awk '{ split($3,t,":"); h=t[1]; e[h]++ } END { for(h in e) printf "%02d:00 %d\n", h, e[h] }' | sort
```

### Últimos 20 errores con contexto

```bash
grep -n "error\|fail\|critical" labs/syslog.log | tail -20 | while IFS=: read -r n l; do echo "--- Línea $n ---"; echo "$l"; echo ""; done
```

### Detectar patrones repetitivos (problema cíclico)

```bash
awk '{ msg=$0; gsub(/^[^ ]+ [^ ]+ [^ ]+ [^ ]+ [^ ]+ /,"",msg); msgs[msg]++ }
END { for(m in msgs) if(msgs[m]>3) print msgs[m], substr(m,1,80) }' labs/syslog.log | sort -rn | head -15
```

### Monitoreo de OOM (Out of Memory)

```bash
grep -i "oom\|killed\|out of memory" labs/syslog.log
```

### Watch en tiempo real

```bash
tail -f /var/log/syslog | grep --line-buffered -i "error\|fail\|critical"
```

### Reporte diario completo

```bash
echo "=== Reporte $(date +%Y-%m-%d) ==="
echo "--- Por servicio ---"
grep -i "error\|fail\|critical" labs/syslog.log | awk '{ print $5 }' | sort | uniq -c | sort -rn \
| awk '{ printf "%-20s %d\n", $2, $1 }'
echo "--- Por hora ---"
grep -i "error\|fail\|critical" labs/syslog.log | awk '{ split($3,t,":"); h[t[1]]++ } END { for(i in h) printf "%02d:00 %d\n", i, h[i] }' | sort
echo "--- Últimos críticos ---"
grep -i "critical" labs/syslog.log | tail -5
```

---

## 🧯 Mitigación

Ejemplo: error OOM

```bash
systemctl restart <servicio>
```

Verificar:

```bash
journalctl -u <servicio> -n 20
```

Rollback:

```bash
systemctl stop <servicio> && systemctl start <servicio>
```

👉 No aplicar mitigaciones sin validar primero el patrón de error.

---

## 🛡️ Prevención

- [ ] logrotate configurado para todos los servicios
- [ ] Alertas de disco >80% (cron + mail)
- [ ] Monitorear OOM con `dmesg`
- [ ] Logs centralizados (rsyslog remoto, ELK)
- [ ] Watch periódico de errores críticos

---

## 🧪 Variantes

### Líneas en rango de tiempo

```bash
sed -n '/14:30:00/,/15:00:00/p' labs/syslog.log | grep -i "error"
```

### Correlacionar journalctl con syslog

```bash
journalctl -u sshd -b --no-pager | grep -i "fail\|error\|invalid"
```

---

## 🧑‍🏫 Modo docente

**Preguntas:** ¿Qué indica un `segfault` repetido? ¿Cómo diferenciar un error de red de un error de aplicación?
**Ejercicio:** Encontrar los top 3 servicios con errores y proponer una causa para cada uno.
**Evaluación:** identificación correcta de patrones, clasificación de severidad, propuesta de mitigación realista.

---

## 🧪 Cómo practicarlo en el lab

```bash
cd labs && docker compose up -d # Usar el monitoring container
docker exec -it monitoring bash
# Simular errores
logger "error: prueba de syslog"
dmesg | tail -5
# Aplicar pipelines sobre /var/log/syslog dentro del contenedor
```

[Ver laboratorio completo →](../../labs/README.md)

---

## 🐧 Variante Alpine (OpenRC + logs)

Este escenario asume systemd (Debian/Ubuntu). En Alpine Linux (contenedor Docker mínimo) se usa OpenRC.

### Gestión de servicios

```bash
# Debian (systemd):                # Alpine (OpenRC):
systemctl restart <svc>             rc-service <svc> restart
systemctl status <svc>              rc-service <svc> status
systemctl stop <svc>                rc-service <svc> stop
systemctl start <svc>               rc-service <svc> start
```

### Logs del sistema

```bash
# Debian:                          # Alpine:
journalctl -u sshd -b               logread | grep sshd
journalctl -u <svc> -n 20           logread | grep <svc>
```

---

## 🔗 Referencias

- [`grep`](../../guides/grep.md) — `-i` para ignorar mayúsculas
- [`awk`](../../guides/awk.md) — `split`, `substr`
- [`sed`](../../guides/sed.md) — rangos de líneas
- [`sort`](../../guides/sort.md) + [`uniq`](../../guides/uniq.md) — frecuencias
- [`systemd_journalctl`](../../guides/systemd_journalctl.md) — journalctl avanzado
- [`openrc`](../../guides/openrc.md) — Alpine Linux: servicios (rc-service, rc-update)
- [`busybox`](../../guides/busybox.md) — Alpine Linux: toolchain mínima (logread, dmesg)
