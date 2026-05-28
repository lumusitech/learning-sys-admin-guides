# 🧩 Escenario: Problemas de memoria y OOM killer

---

## 🎯 Problema

El sistema presenta lentitud extrema, procesos que se caen inesperadamente o errores relacionados con memoria insuficiente. Es necesario identificar si existe un problema de consumo de memoria (RAM) o si el sistema está activando el OOM killer (Out Of Memory).

---

## ⚡ Quick command (SRE)

```bash
free -h && ps aux --sort=-%mem | head -10 | awk '{print $2, $4, $11}'
```

---

## ✅ Salida esperada

- uso de memoria total, usada y disponible
- swap utilizado (si existe)
- procesos ordenados por consumo de memoria

Interpretación:

- memoria casi agotada → riesgo de OOM
- uso alto de swap → presión de memoria
- proceso consumiendo mucha RAM → posible fuga o exceso de carga

---

## 🧠 Diagnóstico

El consumo de memoria debe analizarse considerando uso de RAM, swap y comportamiento de procesos.
Patrones clave:

- memoria al 90–100% + swap creciendo → presión real de memoria
- procesos individuales con uso alto → posible memory leak
- procesos terminados inesperadamente → posible intervención del OOM killer
- swap intensivo → degradación de rendimiento significativa

👉 Un sistema puede tener RAM llena sin problema, pero el uso sostenido de swap indica presión de memoria real.

---

## 🛠️ Procedimiento (runbook)

### 1. Ver uso general de memoria

```bash
free -h
```

### 2. Identificar procesos con mayor consumo

```bash
ps aux --sort=-%mem | head -10
```

### 3. Monitoreo en tiempo real

```bash
top
```

### 4. Verificar uso de swap

```bash
swapon --show
```

### 5. Detectar intervención del OOM killer

```bash
dmesg | grep -i "kill" | tail -10
```

### 6. Evaluar impacto

```bash
uptime
```

---

## 🧯 Mitigación

Si hay presión de memoria:

Verificar:

```bash
free -h
ps aux --sort=-%mem | head
```

Acción:

```bash
# intento liberar memoria terminando proceso no crítico
kill <PID>

# si no responde
kill -9 <PID>
```

Mitigación temporal (swap):

```bash
# activar swap si no existe (emergencia)
fallocate -l 1G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
```

Rollback:

```bash
systemctl restart <servicio>
```

Casos comunes:

- memory leak → bug en aplicación
- proceso descontrolado → mala gestión de recursos
- falta de RAM → necesidad de escalar
- contenedor mal configurado → límites de memoria incorrectos

---

## ✅ Interpretación

- memoria liberada → sistema recupera respuesta
- swap en uso constante → sistema bajo presión
- procesos eliminados automáticamente → OOM killer activo
- problema recurrente → requiere análisis profundo o escalado

---

## 🐧 Variante Alpine (OpenRC)

Este escenario asume systemd (Debian/Ubuntu). En Alpine Linux:

```bash
# Debian:                          # Alpine:
systemctl restart <svc>             rc-service <svc> restart
```

### Swap file

`fallocate` puede no estar disponible en Alpine. Usá la alternativa portable:

```bash
# Debian:                          # Alpine (portable):
fallocate -l 1G /swapfile           dd if=/dev/zero of=/swapfile bs=1M count=1024
chmod 600 /swapfile                 chmod 600 /swapfile
mkswap /swapfile                    mkswap /swapfile
swapon /swapfile                    swapon /swapfile
```

---

## 🔗 Referencias

- [`top`](../../guides/top.md)
- [`ps`](../../guides/ps.md)
