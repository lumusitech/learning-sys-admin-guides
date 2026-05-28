
# Baseline y detección de anomalías — Guía conceptual

## 🧠 ¿Qué es una baseline?

Es el comportamiento esperado de un sistema en condiciones normales de operación. No es un valor fijo, sino un rango de valores que reflejan el estado saludable del sistema.

Sin baseline no es posible detectar anomalías — todo parece normal hasta que algo explota.

---

## 🎯 ¿Por qué es importante?

- permite distinguir un pico pasajero de una tendencia peligrosa
- reduce falsos positivos: no todo pico de CPU es un incidente
- acelera el diagnóstico: sabés qué es normal antes de que ocurra el problema
- fundamenta decisiones de capacidad: sabés cuándo hace falta escalar

---

## 📊 Métricas de referencia

### CPU

| Métrica | Cómo medirla | Baseline típica |
|---------|-------------|-----------------|
| % usuario | `top`, `mpstat -P ALL` | Depende de la carga: 10–40% idle sostenido |
| % sistema (kernel) | `mpstat`, `vmstat` | < 10% |
| % iowait | `iostat -x 1`, `vmstat 1` | < 5% (SSD), < 10% (HDD) |
| Load average | `/proc/loadavg`, `uptime` | < núcleos × 0.7 en idle / < núcleos × 2.0 en carga |
| Context switches | `vmstat 1` (columna `cs`) | < 20.000/s en sistemas típicos |

La baseline de CPU depende del tipo de carga: un servidor web normal tiene perfil distinto a un servidor de base de datos o a un worker de batch.

### Memoria

| Métrica | Cómo medirla | Baseline típica |
|---------|-------------|-----------------|
| RAM usada | `free -h` | 60–80% (con caché de disco) |
| Swap used | `free -h`, `vmstat` (columna `si`/`so`) | 0 MB ideal, > 0 sostenido es anomalía |
| Available | `free -h` (columna `available`) | > 20% del total |
| Page faults | `vmstat 1` (`si`, `so`) | 0 en condiciones normales |

La memoria `available` incluye caché que puede liberarse. Una baseline saludable muestra RAM alta por caché, no por presión real.

### Disco

| Métrica | Cómo medirla | Baseline típica |
|---------|-------------|-----------------|
| % utilización | `df -h` | < 80% |
| % inodes | `df -i` | < 70% |
| I/O wait | `iostat -x 1` (`%iowait`) | < 5% |
| IOPS | `iostat -x 1` (`r/s`, `w/s`) | Depende del hardware: SSD 10.000–100.000, HDD 100–200 |
| Latencia | `iostat -x 1` (`r_await`, `w_await`) | < 5ms SSD, < 15ms HDD |
| Queue size | `iostat -x 1` (`avgqu-sz`) | < 2 por disco |

La latencia y la cola son mejores indicadores de problemas que el % de uso solo.

### Red

| Métrica | Cómo medirla | Baseline típica |
|---------|-------------|-----------------|
| Latencia interna | `ping <gateway>` | < 1ms LAN |
| Latencia externa | `ping <host-remoto>`, `mtr` | < 50ms |
| Packet loss | `ping -c 100`, `mtr` | 0% |
| Conexiones establecidas | `ss -s`, `ss -t state established` | Depende del servicio |
| Throughput | `nload`, `iftop`, `sar -n DEV` | Depende del ancho de banda disponible |

La latencia interna debe ser estable. Si varía más de 2–3ms en LAN, hay contención o problema de hardware.

### Procesos

| Métrica | Cómo medirla | Baseline típica |
|---------|-------------|-----------------|
| Total de procesos | `ps aux \| wc -l` | Depende del sistema, pero debe ser estable |
| Zombies | `ps axo stat \| grep -c '^Z'` | 0 |
| En estado D | `ps axo stat \| grep -c '^D'` | < 5 |
| Fork rate | `vmstat 1` (columna `in`) | < 1.000/s |

---

## 📈 Cómo establecer una baseline

### 1. Recolección inicial

Durante una semana de operación normal, recolectar métricas en intervalos regulares:

```bash
# CPU, memoria, I/O cada 60 segundos durante 7 días
vmstat 60 >> /tmp/baseline-cpu.log
iostat -x 60 >> /tmp/baseline-disk.log
```

### 2. Identificar patrones

- **Diarios**: picos de carga horaria, ventanas de backup
- **Semanales**: fin de semana vs días hábiles
- **Mensuales**: cierres contables, reportes periódicos

### 3. Calcular rangos

Para cada métrica, establecer:

- **Valor normal**: percentil 50 (mediana) en operación normal
- **Alerta temprana**: percentil 80–90
- **Crítico**: percentil 95+

### 4. Documentar la baseline

Incluir:

- período de recolección
- carga del sistema durante la medición
- excepciones conocidas (picos programados)
- cambios de configuración que la invalidan

---

## 🚨 Cómo detectar desvíos

### Pico vs tendencia

| Tipo | Característica | Acción |
|------|---------------|--------|
| Pico pasajero | Dura segundos o minutos, vuelve solo | Monitorear, no intervenir |
| Tendencia alcista | Crece sostenido durante horas/días | Investigar causa raíz |
| Cambio abrupto | Salto repentino que se mantiene | Probable cambio de configuración o deploy |
| Ciclo anómalo | Patrón repetitivo fuera de lo esperado | Revisar cron, batch, tráfico externo |

### Reglas prácticas

- un pico sin repetición no es incidente
- tres desvíos consecutivos en la misma métrica ameritan investigación
- si dos métricas se desvían al mismo tiempo, probablemente hay una causa común
- el desvío más informativo no es el más grande, sino el primero en aparecer

### Ejemplo

```text
CPU al 95% durante 10 segundos → pico, probablemente normal
CPU al 95% sostenido 30 minutos → tendencia, hay que investigar
CPU al 95% + iowait al 40% → problema de disco, no de CPU
```

---

## 🧠 Modelo mental

La baseline es el sistema nervioso del servidor. Cuando conocés sus valores normales, cualquier anomalía se vuelve obvia.

No hace falta monitoreo sofisticado: `vmstat`, `iostat` y `sar` guardan historia suficiente para establecer una baseline sólida en cualquier servidor Linux.

---

## 🔗 Ver también

- [`how-to-think-like-sysadmin.md`](how-to-think-like-sysadmin.md) — patrones normales vs anómalos
- [`guides/vmstat.md`](../guides/vmstat.md) — CPU, memoria, I/O en un comando
- [`guides/iostat.md`](../guides/iostat.md) — métricas detalladas de disco
- [`guides/free.md`](../guides/free.md) — memoria y swap
- [`guides/top.md`](../guides/top.md) — visión general de procesos
