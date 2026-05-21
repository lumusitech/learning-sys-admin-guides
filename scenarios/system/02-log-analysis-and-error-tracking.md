# 🧩 Escenario: Análisis de logs del sistema y tracking de errores

**Dominio:** system
**Nivel:** 🟢 Básico
**Herramientas:** `grep`, `awk`, `sort`, `uniq`, `sed`, `journalctl`, `tail`
**Archivos:** `labs/syslog.log`

**Quick command:** `grep -i "error\|fail\|critical" labs/syslog.log | awk '{print $5}' | sort | uniq -c | sort -rn | head`

**Cuándo usar este escenario:**
- Servidor inestable o con fallos intermitentes
- Buscar qué servicio genera más errores
- Detectar OOM, disco lleno, segfaults

**Archivo de práctica:** `labs/syslog.log`

---

## 🎯 Objetivo

1. Identificar los servicios que más errores generan.
2. Detectar patrones de error cíclicos y problemas de recursos (OOM, disco).
3. Generar reportes de errores por hora y por servicio.

---

## 🧠 Contexto

El servidor genera errores en logs que deben ser analizados para identificar la causa raíz de inestabilidad. Los errores pueden ser de aplicación, sistema, hardware o seguridad.

---

## ✅ Datos de entrada

- **Producción:** `/var/log/syslog`, `/var/log/messages`, `journalctl`
- **Práctica:** `labs/syslog.log`

---

## ⚡ Quick run (errores por servicio)

```bash
grep -i "error\|fail\|critical" labs/syslog.log | awk '{ print $5 }' | sort | uniq -c | sort -rn | head -10
```

---

## 🔍 Paso a paso

1. `grep -i "error\|fail\|critical"` → filtra líneas con palabras clave (case-insensitive)
2. `awk '{ print $5 }'` → extrae el nombre del servicio (campo 5)
3. `sort | uniq -c | sort -rn` → cuenta y ordena por frecuencia
4. `head -10` → top 10 servicios con más errores

---

## ✅ Salida esperada

```
150 sshd
 89 kernel
 45 mysqld
```

- `kernel` con muchos errores → posible hardware (disco, memoria)
- `sshd` con muchos fallos → fuerza bruta SSH
- Un servicio de app con muchos errores → bug/fuga de recursos

---

## 📌 Pipelines de diagnóstico

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

| Error | Acción |
|-------|--------|
| OOM killer | Agregar RAM, limitar memoria por proceso, verificar memory leak |
| EXT4-fs error | `fsck`, revisar cable/HDD, reemplazar disco |
| segfault | Reinstalar/recompilar servicio, reportar bug upstream |
| Connection refused | `systemctl restart <servicio>`, verificar puerto |
| Disk full | `du -sh /* | sort -rh`, rotar logs, borrar temporales |

⚠️ Cuando veas OOM: no agregues swap como solución permanente, buscá la fuga de memoria.

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

## 🔗 Referencias

- [`guides/grep.md`](../../guides/grep.md) — `-i` para ignorar mayúsculas
- [`guides/awk.md`](../../guides/awk.md) — `split`, `substr`
- [`guides/sed.md`](../../guides/sed.md) — rangos de líneas
- [`guides/sort.md`](../../guides/sort.md) + [`guides/uniq.md`](../../guides/uniq.md) — frecuencias
- [`guides/systemd_journalctl.md`](../../guides/systemd_journalctl.md) — journalctl avanzado
