# 🧩 Escenario: Alta I/O wait (espera de disco)

---

## 🎯 Problema

El sistema presenta lentitud, timeouts o alto load average, pero el uso de CPU parece bajo. Es necesario determinar si el problema está relacionado con espera de I/O (disco o storage).

---

## ⚡ Quick command (SRE)

```bash
top -b -n 1 | grep "Cpu(s)"
```

---

## ✅ Salida esperada

- porcentaje de uso de CPU por estado
- valor de `wa` (iowait) visible

Interpretación:

- wa alto (>10–20%) → CPU esperando operaciones de disco
- CPU baja + load alto → posible I/O wait
- id alto + sistema lento → recursos bloqueados en I/O

---

## 🧠 Diagnóstico

El I/O wait representa el tiempo en que la CPU está ociosa esperando operaciones de disco.
👉 Es decir: el CPU no está ocupado trabajando, está esperando datos.

Patrones clave:

- CPU baja + sistema lento → cuello de botella de disco
- load alto + CPU baja → procesos bloqueados en I/O
- wa alto → operaciones de disco lentas o saturadas
- procesos en estado D → bloqueados esperando I/O
- load alto + CPU baja + `wa` alto → cuello de botella de disco

👉 I/O wait es un síntoma: indica que algo está retrasando el acceso a almacenamiento, no la causa directa.

---

## 🛠️ Procedimiento (runbook)

### 1. Verificar uso de CPU y iowait

```bash
top
```

### 2. Verificar memoria y swap

```bash
free -h
```

### 3. Verificar estadísticas de CPU e I/O

```bash
vmstat 1 5
```

### 4. Analizar rendimiento de disco

```bash
iostat -x 1 3
```

### 5. Identificar procesos con mayor uso de disco

```bash
iotop
```

### 6. Verificar uso de disco y filesystem

```bash
df -h
```

### 7. Detectar procesos bloqueados

```bash
ps -eo pid,state,cmd | grep "^ *[0-9]* D"
```

---

## 🧯 Mitigación

Si se detecta I/O wait alto:

Verificar:

```bash
iostat -x
iotop
```

Acción:

```bash
# reducir impacto del proceso
ionice -c 3 -p <PID>

# opcional (emergencia)
kill -STOP <PID>
```

Mitigación adicional:

```bash
# bajar prioridad de I/O
ionice -c 3 -p <PID>
```

Rollback:

```bash
kill -CONT <PID>
```

Casos comunes:

- disco saturado → demasiadas operaciones simultáneas
- procesos intensivos → backups, bases de datos, logs
- falta de RAM → swapping excesivo
- storage lento → HDD, NFS, cloud storage

---

## ✅ Interpretación

- wa alto constante → cuello de botella en almacenamiento
- iostat %util alto → disco saturado
- await alto → latencia en disco
- procesos identificados → origen del problema

---

## 🔗 Referencias

- [`top.md`](../../guides/top.md)
- [system_iostat.md](../../guides/system_iostat.md)