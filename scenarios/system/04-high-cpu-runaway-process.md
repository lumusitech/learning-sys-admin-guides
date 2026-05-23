
# 🧩 Escenario: Proceso con alto consumo de CPU (runaway process)

---

## 🎯 Problema

El servidor presenta alta carga de CPU de manera sostenida, lo que provoca lentitud en las aplicaciones y afecta la disponibilidad del sistema. Es necesario identificar el proceso responsable y tomar una decisión adecuada.

---

## ⚡ Quick command (SRE)

```bash
ps aux --sort=-%cpu | head -10
```

---

## ✅ Salida esperada

- listado de procesos ordenados por uso de CPU
- identificación del proceso con mayor consumo
- porcentaje de CPU utilizado

Interpretación:

- un proceso con uso alto sostenido → posible problema
- múltiples procesos altos → carga distribuida
- uso ocasional → comportamiento normal

---

## 🧠 Diagnóstico

El uso de CPU debe analizarse en función del tiempo y el comportamiento del proceso.

Patrones clave:

- CPU alta sostenida → posible bug o loop infinito
- CPU alta en picos → carga legítima
- múltiples procesos en alto consumo → cuello de botella del sistema
- proceso reaparece después de kill → servicio gestionado automáticamente

👉 No toda CPU alta es un problema: la persistencia define la anomalía.

---

## 🛠️ Procedimiento (runbook)

### 1. Identificar procesos con alto consumo

```bash
ps aux --sort=-%cpu | head -10
```

### 2. Monitorear en tiempo real

```bash
top
```

### 3. Analizar proceso específico

```bash
ps -p <PID> -o pid,cmd,%cpu,%mem
```

### 4. Evaluar impacto

```bash
uptime
```

### 5. Tomar decisión

- esperar si es carga normal
- reiniciar si es servicio
- terminar si es proceso anómalo

---

## 🧯 Mitigación

Si un proceso consume CPU excesiva:

Verificar:

```bash
top -o %CPU
```

Acción:

```bash
# intento suave primero
kill <PID>

# si no responde
kill -9 <PID>
```

Rollback:

```bash
systemctl restart <servicio>
```

Casos comunes:

- proceso en loop → bug en aplicación
- servicio sobrecargado → falta de recursos
- tarea cron intensiva → mala planificación

---

## ✅ Interpretación

- proceso eliminado → alivio inmediato de CPU, monitorear estabilidad
- CPU sigue alta → problema sistémico o múltiples procesos
- proceso vuelve a iniciarse → servicio gestionado (systemd / supervisor)

---

## 🔗 Referencias

<!-- TODO: Crear guides para top y ps que no existen todavía -->
- [`guides/top.md`](../../guides/top.md)
- [`guides/ps.md`](../../guides/ps.md)