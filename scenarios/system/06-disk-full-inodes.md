
# 🧩 Escenario: Disco lleno e inodes agotados

---

## 🎯 Problema

El sistema presenta errores al guardar archivos, fallos en aplicaciones o logs que dejan de escribirse. Es necesario determinar si el problema está relacionado con falta de espacio en disco o agotamiento de inodes.

---

## ⚡ Quick command (SRE)

```bash
df -h && df -i
```

---

## ✅ Salida esperada

- uso de espacio en disco por sistema de archivos
- porcentaje de utilización (%)
- uso de inodes disponibles

Interpretación:

- disco al 100% → no se pueden escribir nuevos datos
- inodes al 100% → no se pueden crear nuevos archivos
- uso alto en /var → posible crecimiento de logs o datos

---

## 🧠 Diagnóstico
Los problemas de disco pueden estar relacionados con capacidad o cantidad de archivos.

Patrones clave:

- espacio lleno (df -h) → archivos grandes o acumulación de datos
- inodes agotados (df -i) → demasiados archivos pequeños
- crecimiento rápido → logs o procesos anómalos
- errores de escritura → aplicaciones afectadas directamente
- filesystem lleno pero disco libre en otro mount → punto de montaje incorrecto

👉 Tener espacio libre no garantiza disponibilidad: los inodes también son un recurso crítico.

---

## 🛠️ Procedimiento (runbook)

### 1. Ver uso de disco

```bash
df -h
```

### 2. Ver uso de inodes

```bash
df -i
```

### 3. Identificar directorios con mayor consumo

```bash
du -h --max-depth=1 / | sort -hr | head -10
```

### 4. Analizar ubicación específica (ej: /var)

```bash
du -h --max-depth=1 /var | sort -hr | head -10
```

### 5. Identificar archivos grandes

```bash
find / -type f -size +100M 2>/dev/null | head -10
```

### 6. Identificar exceso de archivos pequeños

```bash
find /var -type f | wc -l
```

---

## 🧯 Mitigación

Si el disco está lleno:

Verificar:

```bash
df -h
du -sh /var/*
```

Acción:

```bash
# limpiar logs grandes
truncate -s 0 /var/log/*.log

# eliminar archivos temporales
rm -rf /tmp/*

# o más seguro:
find /tmp -type f -mtime +1 -delete
```

Mitigación por inodes:

```bash
# eliminar archivos pequeños innecesarios
find /var/log -type f -name "*.gz" -delete
```

Rollback:

```bash
systemctl restart <servicio>
```

Casos comunes:

- logs sin rotación → crecimiento infinito
- backups acumulados → consumo progresivo
- archivos temporales → limpieza inexistente
- millones de archivos pequeños → agotamiento de inodes

---

## ✅ Interpretación

- espacio liberado → sistema vuelve a operar normalmente
- disco vuelve a llenarse → proceso descontrolado activo
- inodes siguen agotados → exceso de archivos pequeños
- problema recurrente → falta de políticas de limpieza/rotación

---

## 🔗 Referencias

[../../guides/du.md](../../guides/du.md)
[../../guides/df.md](../../guides/df.md)